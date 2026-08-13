import 'package:flutter/material.dart';

import '../models/hyope_models.dart';
import '../utils/date_utils.dart';
import '../widgets/common_widgets.dart';

class NotificationSettingsScreen extends StatelessWidget {
  final List<GuardianNotification> notifications;
  final ValueChanged<int> onMarkRead;
  final ValueChanged<int> onDelete;

  const NotificationSettingsScreen({
    super.key,
    required this.notifications,
    required this.onMarkRead,
    required this.onDelete,
  });

  bool _isDailyNews(NotificationCategory type) {
    return type == NotificationCategory.newReport ||
        type == NotificationCategory.callMissed ||
        type == NotificationCategory.callFailed ||
        type == NotificationCategory.dailyCallMissing;
  }

  bool _isRiskChange(NotificationCategory type) {
    return type == NotificationCategory.highRisk ||
        type == NotificationCategory.suddenSpike ||
        type == NotificationCategory.incompleteAnalysis;
  }

  @override
  Widget build(BuildContext context) {
    final dailyNews =
        notifications.where((n) => _isDailyNews(n.type)).toList();
    final riskChanges =
        notifications.where((n) => _isRiskChange(n.type)).toList();
    final others = notifications
        .where((n) => !_isDailyNews(n.type) && !_isRiskChange(n.type))
        .toList();

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            children: [
              const PageHeader(
                title: '알림 이력',
                subtitle: '최근 발생한 알림을 확인합니다.',
                icon: Icons.notifications_none_rounded,
              ),
              const SizedBox(height: 14),
              if (notifications.isEmpty)
                HyopeCard(
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      '받은 알림이 없습니다.',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF9AA2B4),
                      ),
                    ),
                  ),
                )
              else ...[
                if (riskChanges.isNotEmpty) ...[
                  _NotificationSection(
                    title: '위험도 변동',
                    notifications: riskChanges,
                    onMarkRead: onMarkRead,
                    onDelete: onDelete,
                  ),
                  const SizedBox(height: 10),
                ],
                if (dailyNews.isNotEmpty) ...[
                  _NotificationSection(
                    title: '오늘의 소식',
                    notifications: dailyNews,
                    onMarkRead: onMarkRead,
                    onDelete: onDelete,
                  ),
                  const SizedBox(height: 10),
                ],
                if (others.isNotEmpty)
                  _NotificationSection(
                    title: '기타 알림',
                    notifications: others,
                    onMarkRead: onMarkRead,
                    onDelete: onDelete,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationSection extends StatelessWidget {
  final String title;
  final List<GuardianNotification> notifications;
  final ValueChanged<int> onMarkRead;
  final ValueChanged<int> onDelete;

  const _NotificationSection({
    required this.title,
    required this.notifications,
    required this.onMarkRead,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return HyopeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(title: title),
          const SizedBox(height: 10),
          for (final n in notifications) ...[
            _NotificationTile(
              notification: n,
              onTap: () => onMarkRead(n.id),
              onDelete: () => onDelete(n.id),
            ),
            if (n != notifications.last) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final GuardianNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;
    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        margin: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFE5484D),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: InkWell(
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
                    if (notification.detail != null &&
                        notification.detail!.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        notification.detail!,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF7A8294),
                          height: 1.4,
                        ),
                      ),
                    ],
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
      ),
    );
  }
}