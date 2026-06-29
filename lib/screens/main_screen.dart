import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/hyope_models.dart';
import '../utils/adherence_utils.dart';
import '../utils/date_utils.dart';
import 'dashboard_screen.dart';
import 'notification_settings_screen.dart';
import 'user_settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final List<DailyAssessment> assessments;
  late DateTime selectedMonth;
  DateTime? selectedDate;
  bool showAdherenceStats = false;
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
    assessments = MockData.last30Days();
    final latestDate = dateOnly(assessments.last.measuredAt);
    selectedDate = null;
    selectedMonth = DateTime(latestDate.year, latestDate.month);
  }

  DailyAssessment? get selectedAssessment {
    final date = selectedDate;
    if (date == null) return null;
    return findAssessmentByDate(assessments, date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: selectedTabIndex,
        children: [
          DashboardScreen(
            assessments: assessments,
            selectedMonth: selectedMonth,
            selectedDate: selectedDate,
            selectedAssessment: selectedAssessment,
            showAdherenceStats: showAdherenceStats,
            onToggleAdherenceStats: () {
              setState(() => showAdherenceStats = !showAdherenceStats);
            },
            onMonthChanged: (month) {
              setState(() {
                selectedMonth = month;
                selectedDate = null;
              });
            },
            onDateSelected: (date) {
              setState(() => selectedDate = date);
            },
          ),
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
            biometricLockEnabled: biometricLockEnabled,
            darkModeEnabled: darkModeEnabled,
            onBiometricLockChanged: (value) => setState(() => biometricLockEnabled = value),
            onDarkModeChanged: (value) => setState(() => darkModeEnabled = value),
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
            icon: Icon(Icons.notifications_none_rounded),
            selectedIcon: Icon(Icons.notifications_rounded),
            label: '알림설정',
          ),
          NavigationDestination(
            icon: Icon(Icons.manage_accounts_outlined),
            selectedIcon: Icon(Icons.manage_accounts_rounded),
            label: '사용자 설정',
          ),
        ],
      ),
    );
  }
}
