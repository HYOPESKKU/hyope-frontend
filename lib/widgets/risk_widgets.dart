import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/hyope_models.dart';
import '../painters/hyope_painters.dart';
import 'common_widgets.dart';

class RiskGaugeCard extends StatelessWidget {
  final DailyAssessment assessment;
  final String title;
  final String? phoneNumber;

  const RiskGaugeCard({
    super.key,
    required this.assessment,
    this.title = '오늘의 돌봄 위험도',
    this.phoneNumber,
  });

  Future<void> _makeCall(BuildContext context) async {
    final number = phoneNumber;
    if (number == null || number.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('등록된 연락처가 없습니다.')),
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: number);
    final launched = await launchUrl(uri);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('전화 앱을 열 수 없습니다.')),
      );
    }
  }

  Future<void> _sendMessage(BuildContext context) async {
    final number = phoneNumber;
    if (number == null || number.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('등록된 연락처가 없습니다.')),
      );
      return;
    }
    final uri = Uri(scheme: 'sms', path: number);
    final launched = await launchUrl(uri);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('문자 앱을 열 수 없습니다.')),
      );
    }
  }

  String _formatDate(DateTime date) {
    const weekdays = [
      '월요일',
      '화요일',
      '수요일',
      '목요일',
      '금요일',
      '토요일',
      '일요일',
    ];
    return '${date.year}년 ${date.month}월 ${date.day}일 ${weekdays[date.weekday - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final level = assessment.riskLevel;
    final measuredAt = assessment.measuredAt;
    final showTodayDate = title == '오늘의 돌봄 위험도';

    return HyopeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(title: title),
          if (showTodayDate) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: Color(0xFF4F80FF),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _formatDate(measuredAt),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF182033),
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 6),
          SizedBox(
            height: 188,
            width: double.infinity,
            child: CustomPaint(
              painter: RiskGaugePainter(
                score: assessment.overallRisk,
                level: assessment.riskLevel,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: level.color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: level.color.withOpacity(0.18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(level.icon, color: level.color, size: 21),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            level.actionTitle,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: level.color,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '위험 단계: ${level.label}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF7A8294),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Text(
                  assessment.recommendation,
                  style: const TextStyle(
                    fontSize: 12.8,
                    height: 1.45,
                    color: Color(0xFF687085),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _makeCall(context),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        icon: const Icon(Icons.phone_outlined, size: 17),
                        label: const Text('전화하기'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _sendMessage(context),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        icon: const Icon(Icons.message_outlined, size: 17),
                        label: const Text('문자 보내기'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}