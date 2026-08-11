import 'package:flutter/material.dart';

import '../models/hyope_models.dart';
import '../utils/date_utils.dart';

class HeaderSection extends StatelessWidget {
  final RecipientSummary recipient;
  final DailyAssessment? latestAssessment;
  final VoidCallback? onNotificationTap;
  final bool hasUnreadNotification;

  const HeaderSection({
    super.key,
    required this.recipient,
    required this.latestAssessment,
    this.onNotificationTap,
    this.hasUnreadNotification = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${recipient.name}님 리포트',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF182033),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                latestAssessment == null
                    ? '${recipient.relation} · 아직 분석 기록이 없어요'
                    : '${recipient.relation} · 마지막 분석 ${formatDateTime(latestAssessment!.measuredAt)}',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF7A8294),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onNotificationTap,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Center(child: Icon(Icons.notifications_none_rounded)),
                  if (hasUnreadNotification)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}