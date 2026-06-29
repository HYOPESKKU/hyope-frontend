import 'package:flutter/material.dart';

import '../models/hyope_models.dart';
import '../painters/hyope_painters.dart';
import '../utils/adherence_utils.dart';
import '../utils/date_utils.dart';
import 'common_widgets.dart';

class RiskGaugeCard extends StatefulWidget {
  final DailyAssessment assessment;

  const RiskGaugeCard({super.key, required this.assessment});

  @override
  State<RiskGaugeCard> createState() => _RiskGaugeCardState();
}

class _RiskGaugeCardState extends State<RiskGaugeCard> {
  bool showDetail = false;

  @override
  Widget build(BuildContext context) {
    final assessment = widget.assessment;
    final level = assessment.riskLevel;

    return HyopeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            title: '오늘의 돌봄 위험도',
            trailing: TextButton.icon(
              onPressed: () => setState(() => showDetail = !showDetail),
              style: TextButton.styleFrom(
                foregroundColor: level.color,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: Icon(
                showDetail ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                size: 20,
              ),
              label: Text(
                showDetail ? '접기' : '상세보기',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900),
              ),
            ),
          ),
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
                        onPressed: () {},
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                        ),
                        icon: const Icon(Icons.phone_outlined, size: 17),
                        label: const Text('전화하기'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
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
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: showDetail
                ? RiskDetailPanel(
                    key: const ValueKey('risk-detail-open'),
                    assessment: assessment,
                  )
                : const SizedBox.shrink(key: ValueKey('risk-detail-closed')),
          ),
        ],
      ),
    );
  }
}

class RiskDetailPanel extends StatelessWidget {
  final DailyAssessment assessment;

  const RiskDetailPanel({super.key, required this.assessment});

  @override
  Widget build(BuildContext context) {
    final mealRate = adherenceCompletionRate(assessment, AdherenceType.meal);
    final medicationRate = adherenceCompletionRate(assessment, AdherenceType.medication);

    final detailItems = [
      _RiskDetailItem(
        title: '우울도',
        score: assessment.depressionScore,
        color: const Color(0xFF8A6DFF),
        icon: Icons.sentiment_dissatisfied_outlined,
        caption: '부정 감정·무기력·외로움 표현 기반',
        lowGood: true,
      ),
      _RiskDetailItem(
        title: '건강 이상',
        score: assessment.healthRisk,
        color: const Color(0xFFFF8A3D),
        icon: Icons.monitor_heart_outlined,
        caption: '통증·수면·호흡·낙상 신호 기반',
        lowGood: true,
      ),
      _RiskDetailItem(
        title: '정서 안정',
        score: assessment.emotionalStability,
        color: const Color(0xFF6D7CFF),
        icon: Icons.mood_outlined,
        caption: '높을수록 안정적인 정서 상태',
        lowGood: false,
      ),
      _RiskDetailItem(
        title: '인지 기능',
        score: assessment.cognitiveScore,
        color: const Color(0xFF2FB86E),
        icon: Icons.psychology_alt_outlined,
        caption: '응답 길이·반복 패턴·어휘 다양성 기반',
        lowGood: false,
      ),
      _RiskDetailItem(
        title: '생활 리듬',
        score: (((mealRate + medicationRate) / 2) / 10).clamp(0.0, 10.0).toDouble(),
        color: const Color(0xFF00A0B0),
        icon: Icons.schedule_outlined,
        caption: '식사·복약 일정 이행 기반 간접 지표',
        lowGood: false,
      ),
    ];

    return Container(
      key: key,
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8ECF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '상세정보',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF182033),
                  ),
                ),
              ),
              Text(
                '분석 ${formatDateTime(assessment.measuredAt)}',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF8A92A6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: detailItems
                    .map(
                      (item) => SizedBox(
                        width: itemWidth,
                        child: RiskDetailScoreTile(item: item),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: RiskAdherenceSummaryTile(
                  title: '식사 이행률',
                  value: '${mealRate.round()}%',
                  description: adherenceRateDescription(mealRate),
                  icon: Icons.restaurant_outlined,
                  color: const Color(0xFF2FB86E),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: RiskAdherenceSummaryTile(
                  title: '복약 이행률',
                  value: '${medicationRate.round()}%',
                  description: adherenceRateDescription(medicationRate),
                  icon: Icons.medication_outlined,
                  color: const Color(0xFF4F80FF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8ECF5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '판단 근거 요약',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF333B4F),
                  ),
                ),
                const SizedBox(height: 8),
                _RiskSignalRow(
                  icon: Icons.check_circle_outline,
                  text: '종합 위험도 ${assessment.overallRisk.toStringAsFixed(1)}점으로 ${assessment.riskLevel.label} 단계입니다.',
                  color: assessment.riskLevel.color,
                ),
                const SizedBox(height: 6),
                _RiskSignalRow(
                  icon: Icons.insights_outlined,
                  text: riskDetailComment(assessment, mealRate, medicationRate),
                  color: const Color(0xFF687085),
                ),
                const SizedBox(height: 6),
                _RiskSignalRow(
                  icon: Icons.recommend_outlined,
                  text: assessment.recommendation,
                  color: const Color(0xFF687085),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskDetailItem {
  final String title;
  final double score;
  final Color color;
  final IconData icon;
  final String caption;
  final bool lowGood;

  const _RiskDetailItem({
    required this.title,
    required this.score,
    required this.color,
    required this.icon,
    required this.caption,
    required this.lowGood,
  });
}

class RiskDetailScoreTile extends StatelessWidget {
  final _RiskDetailItem item;

  const RiskDetailScoreTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final normalized = (item.score / 10).clamp(0.0, 1.0).toDouble();
    final status = item.lowGood
        ? item.score <= 3
            ? '안정'
            : item.score <= 6
                ? '주의'
                : '위험'
        : item.score >= 7
            ? '안정'
            : item.score >= 4
                ? '주의'
                : '위험';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(item.icon, size: 16, color: item.color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF333B4F),
                  ),
                ),
              ),
              Text(
                item.score.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: item.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: normalized,
              minHeight: 5,
              backgroundColor: item.color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(item.color),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '$status · ${item.caption}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.2,
              height: 1.25,
              color: Color(0xFF8A92A6),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class RiskAdherenceSummaryTile extends StatelessWidget {
  final String title;
  final String value;
  final String description;
  final IconData icon;
  final Color color;

  const RiskAdherenceSummaryTile({
    super.key,
    required this.title,
    required this.value,
    required this.description,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECF5)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF8A92A6),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF182033),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.2,
                          color: Color(0xFF9AA2B4),
                          fontWeight: FontWeight.w700,
                        ),
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

class _RiskSignalRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _RiskSignalRow({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12.2,
              height: 1.35,
              color: Color(0xFF687085),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
