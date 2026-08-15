import 'package:flutter/material.dart';

import '../models/hyope_models.dart';
import '../services/api_client.dart';
import '../services/assessment_service.dart';
import '../services/auth_service.dart';
import '../services/call_schedule_service.dart';
import '../services/guardian_service.dart';
import '../services/notification_service.dart';
import '../services/notification_socket_service.dart';
import '../services/profile_seen_store.dart';
import '../services/recipient_service.dart';
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
  final ValueChanged<int>? onRecipientDeleted;

  const MainScreen({
    super.key,
    required this.userRole,
    required this.recipient,
    this.userProfile,
    this.onUserProfileChanged,
    this.onRecipientChanged,
    this.onRecipientDeleted,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  List<DailyAssessment>? assessments;
  CallSchedule? callSchedule;
  List<GuardianNotification>? notifications;
  String? loadError;
  DateTime selectedMonth = DateTime.now();
  late UserProfile currentUser;
  late RecipientSummary currentRecipient;
  DateTime? selectedDate;
  bool showAdherenceStats = false;
  bool isCalendarExpanded = false;
  int selectedTabIndex = 0;

  // 배지는 지금 보고 있는 대상자의 알림 화면에서 실제로 체크할 수 있는
  // 항목 기준으로 맞춘다. notifications는 보호자가 돌보는 모든 대상자의
  // 알림을 담고 있어서, 필터링 없이 쓰면 다른 대상자의 안 읽은 알림 때문에
  // 지금 화면에서 다 읽어도 빨간 점이 안 사라지는 문제가 있었다.
  bool get _hasUnreadForCurrentRecipient => (notifications ?? const [])
      .where((n) => n.recipientId == currentRecipient.id)
      .any((n) => !n.isRead);

  /// 통화로 갱신된 항목. 매 로드마다 저장된 "마지막으로 본 값"과 비교해 채운다.
  final _seenStore = ProfileSeenStore();
  Set<String> updatedProfileFields = const {};

  bool dailyNewsAlertEnabled = true;
  bool riskChangeAlertEnabled = true;
  bool emergencySmsEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    currentRecipient = widget.recipient;
    currentUser = widget.userProfile ??
        UserProfile(
          id: 0,
          role: widget.userRole,
          firstName: currentRecipient.firstName,
          lastName: currentRecipient.lastName,
          phoneNumber: currentRecipient.phoneNumber,
          email: '',
        );
    _loadAssessments();
    NotificationSocketService.instance.connect();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NotificationSocketService.instance.disconnect();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      NotificationSocketService.instance.notifyAppResumed();
    }
  }

Future<void> _loadAssessments() async {
  setState(() => loadError = null);
  try {
    final results = await Future.wait([
      AssessmentService().findByRecipient(currentRecipient.id),
      RecipientService().readRecipient(currentRecipient.id),
      CallScheduleService().findByRecipient(currentRecipient.id),
      NotificationService().fetchMine(),
    ]);
    final result = results[0] as List<DailyAssessment>;
    final refreshedRecipient = results[1] as RecipientSummary;
    final schedules = results[2] as List<CallSchedule>;
    final fetchedNotifications = results[3] as List<GuardianNotification>;

    // 서버가 갱신 시각을 주지 않아 기기에 저장된 "마지막으로 본 값"과 비교한다.
    // 실패해도 화면은 그대로 떠야 하므로 예외는 삼킨다(배지만 안 뜬다).
    Set<String> changed = const {};
    try {
      changed = await _seenStore.updatedFields(refreshedRecipient);
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      assessments = result;
      currentRecipient = refreshedRecipient;
      updatedProfileFields = changed;
      callSchedule = schedules.isEmpty ? null : schedules.first;
      notifications = fetchedNotifications;
      if (result.isNotEmpty) {
        final latestDate = dateOnly(result.last.measuredAt);
        selectedMonth = DateTime(latestDate.year, latestDate.month);
      }
      selectedDate = null;
    });
  } on NetworkException catch (e) {
    if (!mounted) return;
    setState(() => loadError = e.message);
  } on ApiException catch (e) {
    if (!mounted) return;
    setState(() => loadError = e.message);
  } catch (e) {
    if (!mounted) return;
    setState(() => loadError = '에러: $e');
  }
}

/// 배지를 눌렀을 때 현재 값을 "본 것"으로 기록한다.
Future<void> _acknowledgeProfileUpdates() async {
  setState(() => updatedProfileFields = const {});
  try {
    await _seenStore.markSeen(currentRecipient);
  } catch (_) {
    // 기록에 실패하면 다음 로드에서 배지가 다시 뜬다. 화면을 막을 일은 아니다.
  }
}

Future<void> _refreshCallSchedule() async {
  try {
    final schedules =
        await CallScheduleService().findByRecipient(currentRecipient.id);
    if (!mounted) return;
    setState(() => callSchedule = schedules.isEmpty ? null : schedules.first);
  } catch (_) {
    // 표시용 정보라 실패해도 조용히 무시 — 기존 값을 그대로 둔다.
  }
}

Future<void> _markNotificationRead(int id) async {
  final current = notifications;
  if (current == null) return;
  setState(() {
    notifications = [
      for (final n in current)
        if (n.id == id) n.copyWith(isRead: true) else n,
    ];
  });
  try {
    await NotificationService().markRead(id);
  } catch (_) {
    // 낙관적 갱신 실패해도 조용히 무시 — 다음 로드 때 서버 상태로 다시 맞춰진다.
  }
}

Future<void> _deleteNotification(int id) async {
  final current = notifications;
  if (current == null) return;
  setState(() {
    notifications = current.where((n) => n.id != id).toList();
  });
  try {
    await NotificationService().delete(id);
  } catch (_) {
    // 실패해도 조용히 무시 — 다음 로드 때 서버 상태로 다시 맞춰진다.
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

  Future<void> _updateNotificationSetting({
    bool? dailyNewsAlertEnabled,
    bool? riskChangeAlertEnabled,
    bool? emergencyAlertEnabled,
  }) async {
    final previous = currentUser;
    final optimistic = previous.copyWith(
      dailyNewsAlertEnabled: dailyNewsAlertEnabled,
      riskChangeAlertEnabled: riskChangeAlertEnabled,
      emergencyAlertEnabled: emergencyAlertEnabled,
    );
    setState(() => currentUser = optimistic);
    widget.onUserProfileChanged?.call(optimistic);

    try {
      final updated = await GuardianService().updateNotificationSettings(
        id: currentUser.id,
        dailyNewsAlertEnabled: optimistic.dailyNewsAlertEnabled,
        riskChangeAlertEnabled: optimistic.riskChangeAlertEnabled,
        emergencyAlertEnabled: optimistic.emergencyAlertEnabled,
      );
      if (!mounted) return;
      setState(() => currentUser = updated);
      widget.onUserProfileChanged?.call(updated);
    } catch (_) {
      if (!mounted) return;
      // 저장 실패 — 서버 상태와 어긋나지 않도록 되돌린다.
      setState(() => currentUser = previous);
      widget.onUserProfileChanged?.call(previous);
      _showSavedMessage('알림 설정을 저장하지 못했습니다. 다시 시도해 주세요.');
    }
  }

  Future<void> _editRecipient() async {
    final result = await Navigator.of(context).push<Object>(
      MaterialPageRoute<Object>(
        builder: (_) => EditRecipientScreen(
          recipient: currentRecipient,
          userRole: widget.userRole,
        ),
      ),
    );

    if (result == null || !mounted) return;

    if (result == 'deleted') {
      Navigator.of(context, rootNavigator: true).pop();
      widget.onRecipientDeleted?.call(currentRecipient.id);
      return;
    }

    if (result is RecipientSummary) {
      setState(() => currentRecipient = result);
      widget.onRecipientChanged?.call(result);
      await _refreshCallSchedule();
      if (!mounted) return;
      _showSavedMessage('피보호자 정보가 수정되었습니다.');
    }
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
              setState(() => selectedMonth = month);
            },
            onDateSelected: (date) {
              setState(() => selectedDate = date);
            },
            onNotificationTap: () {
              setState(() => selectedTabIndex = 2);
            },
            updatedProfileFields: updatedProfileFields,
            onAcknowledgeProfileUpdates: _acknowledgeProfileUpdates,
            hasUnreadNotification: _hasUnreadForCurrentRecipient,
          ),
          ConversationLogScreen(recipientId: currentRecipient.id),
          NotificationSettingsScreen(
            notifications: (notifications ?? const [])
                .where((n) => n.recipientId == currentRecipient.id)
                .toList(),
            onMarkRead: _markNotificationRead,
            onDelete: _deleteNotification,
          ),
          UserSettingsScreen(
            userRole: widget.userRole,
            userProfile: currentUser,
            recipient: currentRecipient,
            callSchedule: callSchedule,
            dailyNewsAlertEnabled: currentUser.dailyNewsAlertEnabled,
            riskChangeAlertEnabled: currentUser.riskChangeAlertEnabled,
            emergencySmsEnabled: currentUser.emergencyAlertEnabled,
            onEditUserProfile: _editUserProfile,
            onEditRecipient: _editRecipient,
            onDailyNewsAlertChanged: (value) {
              _updateNotificationSetting(dailyNewsAlertEnabled: value);
            },
            onRiskChangeAlertChanged: (value) {
              _updateNotificationSetting(riskChangeAlertEnabled: value);
            },
            onEmergencySmsChanged: (value) {
              _updateNotificationSetting(emergencyAlertEnabled: value);
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
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: '대시보드',
          ),
          const NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: '대화내역',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _hasUnreadForCurrentRecipient,
              child: const Icon(Icons.notifications_none_rounded),
            ),
            selectedIcon: Badge(
              isLabelVisible: _hasUnreadForCurrentRecipient,
              child: const Icon(Icons.notifications_rounded),
            ),
            label: '알림',
          ),
          const NavigationDestination(
            icon: Icon(Icons.manage_accounts_outlined),
            selectedIcon: Icon(Icons.manage_accounts_rounded),
            label: '내 정보',
          ),
        ],
      ),
    );
  }
}