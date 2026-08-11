import 'package:flutter/material.dart';

import '../models/hyope_models.dart';
import '../utils/date_utils.dart';
import '../widgets/common_widgets.dart';

class NotificationSettingsScreen extends StatelessWidget {
  final List<GuardianNotification> notifications;
  final ValueChanged<int> onMarkRead;
  final bool smsAlertEnabled;
  final bool pushAlertEnabled;
  final bool dailyReportEnabled;
  final bool highRiskOnlyEnabled;
  final bool guardianCallReminderEnabled;
  final ValueChanged<bool> onSmsAlertChanged;
  final ValueChanged<bool> onPushAlertChanged;
  final ValueChanged<bool> onDailyReportChanged;
  final ValueChanged<bool> onHighRiskOnlyChanged;
  final ValueChanged<bool> onGuardianCallReminderChanged;

  const NotificationSettingsScreen({
    super.key,
    required this.notifications,
    required this.onMarkRead,
    required this.smsAlertEnabled,
    required this.pushAlertEnabled,
    required this.dailyReportEnabled,
    required this.highRiskOnlyEnabled,
    required this.guardianCallReminderEnabled,
    required this.onSmsAlertChanged,
    required this.onPushAlertChanged,
    required this.onDailyReportChanged,
    required this.onHighRiskOnlyChanged,
    required this.onGuardianCallReminderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            children: [
              const PageHeader(
                title: '알림설정',
                subtitle: '위험도 단계와 리포트 수신 방식을 설정합니다.',
                icon: Icons.notifications_none_rounded,
              ),
              const SizedBox(height: 14),
              HyopeCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle(title: '최근 알림'),
                    const SizedBox(height: 10),
                    if (notifications.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          '받은 알림이 없습니다.',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF9AA2B4),
                          ),
                        ),
                      )
                    else
                      for (final n in notifications) ...[
                        _NotificationTile(
                          notification: n,
                          onTap: () => onMarkRead(n.id),
                        ),
                        if (n != notifications.last) const SizedBox(height: 6),
                      ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
              HyopeCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle(title: '알림 수신 방식'),
                    const SizedBox(height: 10),
                    SettingsSwitchTile(
                      icon: Icons.sms_outlined,
                      title: 'SMS 문자 알림',
                      subtitle: '위험도와 주요 이상 항목을 문자로 받기',
                      value: smsAlertEnabled,
                      onChanged: onSmsAlertChanged,
                    ),
                    SettingsSwitchTile(
                      icon: Icons.notifications_none_rounded,
                      title: '앱 푸시 알림',
                      subtitle: '주의·경고·고위험 발생 시 앱으로 받기',
                      value: pushAlertEnabled,
                      onChanged: onPushAlertChanged,
                    ),
                    SettingsSwitchTile(
                      icon: Icons.description_outlined,
                      title: '일일 리포트 알림',
                      subtitle: '매일 통화 분석 완료 후 요약 받기',
                      value: dailyReportEnabled,
                      onChanged: onDailyReportChanged,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              HyopeCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle(title: '알림 기준'),
                    const SizedBox(height: 10),
                    SettingsSwitchTile(
                      icon: Icons.priority_high_rounded,
                      title: '고위험만 강한 알림',
                      subtitle: '8점 이상일 때만 강한 알림음 사용',
                      value: highRiskOnlyEnabled,
                      onChanged: onHighRiskOnlyChanged,
                    ),
                    SettingsSwitchTile(
                      icon: Icons.phone_in_talk_outlined,
                      title: '보호자 전화 권장 알림',
                      subtitle: '주의 단계 이상이면 전화 확인을 권장',
                      value: guardianCallReminderEnabled,
                      onChanged: onGuardianCallReminderChanged,
                    ),
                    const SizedBox(height: 8),
                    const SettingsInfoRow(
                      icon: Icons.folder_outlined,
                      title: '현재 알림 단계',
                      value: '주의 이상',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final GuardianNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: unread ? const Color(0xFFE5484D) : const Color(0xFFD5D9E3),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 12.8,
                      fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
                      color: unread ? const Color(0xFF1F2430) : const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatDateTime(notification.createdAt),
                    style: const TextStyle(
                      fontSize: 10.8,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF9AA2B4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
