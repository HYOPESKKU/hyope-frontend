import 'package:flutter/material.dart';

import '../models/hyope_models.dart';
import 'common_widgets.dart';

class ActionRecommendationCard extends StatelessWidget {
  final DailyAssessment assessment;

  const ActionRecommendationCard({super.key, required this.assessment});

  @override
  Widget build(BuildContext context) {
    final level = assessment.riskLevel;
    return HyopeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: level.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(level.icon, color: level.color, size: 27),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level.actionTitle,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: level.color,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '위험 단계: ${level.label}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF7A8294),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            assessment.recommendation,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: Color(0xFF687085),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.phone_outlined),
                  label: const Text('전화하기'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.message_outlined),
                  label: const Text('문자 보내기'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
