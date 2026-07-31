import 'package:flutter/material.dart';

import '../models/hyope_models.dart';
import '../services/api_client.dart';
import '../services/assessment_service.dart';
import '../services/auth_service.dart';
import '../utils/adherence_utils.dart';
import '../utils/date_utils.dart';
import 'conversation_log_screen.dart';
import 'dashboard_screen.dart';
import 'edit_recipient_screen.dart';
import 'edit_user_profile_screen.dart';
import 'notification_settings_screen.dart';
import 'role_selection_screen.dart';
import 'user_settings_screen.dart';

class MainScreen extends StatefulWidget {
  final AppUserRole userRole;
  final RecipientSummary recipient;
  final UserProfile? userProfile;
  final ValueChanged<UserProfile>? onUserProfileChanged;
  final ValueChanged<RecipientSummary>? onRecipientChanged;

  const MainScreen({
    super.key,
    required this.userRole,
    required this.recipient,
    this.userProfile,
    this.onUserProfileChanged,
    this.onRecipientChanged,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<DailyAssessment>? assessments;
  String? loadError;
  late DateTime selectedMonth;
  late UserProfile currentUser;
  late RecipientSummary currentRecipient;
  DateTime? selectedDate;
  bool showAdherenceStats = false;
  bool isCalendarExpanded = false;
  int selectedTabIndex = 0;

  bool smsAlertEnabled = true;
  bool pushAlertEnabled = true;
  bool dailyReportEnabled = true;
  bool highRiskOnlyEnabled = false;
  bool guardianCallReminderEnabled = true;
  bool biometricLockEnabled = false;
  bool darkModeEnabled = false;

  @override
  void initState() {
    super.initState();
    currentRecipient = widget.recipient;
    currentUser = widget.userProfile ??
        UserProfile(
          id: 0,
          role: widget.userRole,
          name: currentRecipient.name,
          phoneNumber: currentRecipient.phoneNumber,
          email: '',
        );
    _loadAssessments();
  }

  Future<void> _loadAssessments() async {
    setState(() => loadError = null);
    try {
      final result =
          await AssessmentService().findByRecipient(currentRecipient.id);
      if (!mounted) return;
      setState(() {
        assessments = result;
        if (result.isNotEmpty) {
          final latestDate = dateOnly(result.last.measuredAt);
          selectedMonth = DateTime(latestDate.year, latestDate.month);
        }
        selectedDate = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => loadError = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => loadError = '데이터를 불러오지 못했습니다.');
    }
  }

  DailyAssessment? get selectedAssessment {
    final date = selectedDate;
    final list = assessments;
    if (date == null || list == null) return null;
    return findAssessmentByDate(list, date);
  }

  Future<void> _editUserProfile() async {
    final updated = await Navigator.of(context).push<UserProfile>(
      MaterialPageRoute<UserProfile>(
        builder: (_) => EditUserProfileScreen(profile: currentUser),
      ),
    );

    if (updated == null || !mounted) return;

    setState(() => currentUser = updated);
    widget.onUserProfileChanged?.call(updated);
    _showSavedMessage('내 정보가 수정되었습니다.');
  }

  Future<void> _editRecipient() async {
    final updated = await Navigator.of(context).push<RecipientSummary>(
      MaterialPageRoute<RecipientSummary>(
        builder: (_) => EditRecipientScreen(
          recipient: currentRecipient,
          userRole: widget.userRole,
        ),
      ),
    );

    if (updated == null || !mounted) return;

    setState(() => currentRecipient = updated);
    widget.onRecipientChanged?.call(updated);
    _showSavedMessage('피보호자 정보가 수정되었습니다.');
  }

  void _showSavedMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('현재 계정에서 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE5484D),
            ),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !mounted) return;

    AuthService().logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const RoleSelectionScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSocialWorker = widget.userRole == AppUserRole.socialWorker;
    final appBar = isSocialWorker
        ? AppBar(
            backgroundColor: const Color(0xFFF5F7FB),
            surfaceTintColor: Colors.transparent,
            title: Text(
              '${currentRecipient.name} 대시보드',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          )
        : null;

    final list = assessments;

    if (loadError != null) {
      return Scaffold(
        appBar: appBar,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(loadError!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loadAssessments,
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (list == null) {
      return Scaffold(
        appBar: appBar,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (list.isEmpty) {
      return Scaffold(
        appBar: appBar,
        body: const Center(child: Text('아직 분석 데이터가 없습니다.')),
      );
    }

    return Scaffold(
      appBar: appBar,
      body: IndexedStack(
        index: selectedTabIndex,
        children: [
          DashboardScreen(
            recipient: currentRecipient,
            assessments: list,
            selectedMonth: selectedMonth,
            selectedDate: selectedDate,
            selectedAssessment: selectedAssessment,
            showAdherenceStats: showAdherenceStats,
            isCalendarExpanded: isCalendarExpanded,
            onToggleAdherenceStats: () {
              setState(() => showAdherenceStats = !showAdherenceStats);
            },
            onToggleCalendarExpanded: () {
              setState(() => isCalendarExpanded = !isCalendarExpanded);
            },
            onMonthChanged: (month) {
              // 달 이동은 캘린더에 표시되는 월만 변경합니다.
              // 상세 기록은 사용자가 다른 날짜를 직접 선택할 때까지 유지합니다.
              setState(() => selectedMonth = month);
            },
            onDateSelected: (date) {
              setState(() => selectedDate = date);
            },
          ),
          ConversationLogScreen(recipientId: currentRecipient.id),
          NotificationSettingsScreen(
            smsAlertEnabled: smsAlertEnabled,
            pushAlertEnabled: pushAlertEnabled,
            dailyReportEnabled: dailyReportEnabled,
            highRiskOnlyEnabled: highRiskOnlyEnabled,
            guardianCallReminderEnabled: guardianCallReminderEnabled,
            onSmsAlertChanged: (value) => setState(() => smsAlertEnabled = value),
            onPushAlertChanged: (value) => setState(() => pushAlertEnabled = value),
            onDailyReportChanged: (value) => setState(() => dailyReportEnabled = value),
            onHighRiskOnlyChanged: (value) => setState(() => highRiskOnlyEnabled = value),
            onGuardianCallReminderChanged: (value) {
              setState(() => guardianCallReminderEnabled = value);
            },
          ),
          UserSettingsScreen(
            userRole: widget.userRole,
            userProfile: currentUser,
            recipient: currentRecipient,
            biometricLockEnabled: biometricLockEnabled,
            darkModeEnabled: darkModeEnabled,
            onEditUserProfile: _editUserProfile,
            onEditRecipient: _editRecipient,
            onBiometricLockChanged: (value) {
              setState(() => biometricLockEnabled = value);
            },
            onDarkModeChanged: (value) {
              setState(() => darkModeEnabled = value);
            },
            onLogout: _logout,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedTabIndex,
        onDestinationSelected: (index) {
          setState(() => selectedTabIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: '대시보드',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: '대화내역',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none_rounded),
            selectedIcon: Icon(Icons.notifications_rounded),
            label: '알림설정',
          ),
          NavigationDestination(
            icon: Icon(Icons.manage_accounts_outlined),
            selectedIcon: Icon(Icons.manage_accounts_rounded),
            label: '내 정보',
          ),
        ],
      ),
    );
  }
}