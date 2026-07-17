import 'package:flutter/material.dart';

import '../models/hyope_models.dart';
import '../widgets/adherence_widgets.dart';
import '../widgets/common_widgets.dart';
import '../widgets/header_section.dart';
import '../widgets/metric_widgets.dart';
import '../widgets/risk_widgets.dart';

class DashboardScreen extends StatelessWidget {
  final RecipientSummary recipient;
  final List<DailyAssessment> assessments;
  final DateTime selectedMonth;
  final DateTime? selectedDate;
  final DailyAssessment? selectedAssessment;
  final bool showAdherenceStats;
  final VoidCallback onToggleAdherenceStats;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDateSelected;

  const DashboardScreen({
    super.key,
    required this.recipient,
    required this.assessments,
    required this.selectedMonth,
    required this.selectedDate,
    required this.selectedAssessment,
    required this.showAdherenceStats,
    required this.onToggleAdherenceStats,
    required this.onMonthChanged,
    required this.onDateSelected,
  });

  DailyAssessment get currentAssessment => assessments.last;

  @override
  Widget build(BuildContext context) {
    final metricDates = assessments.map((e) => e.measuredAt).toList();
    final depressionValues = assessments.map((e) => e.depressionScore).toList();
    final cognitiveValues = assessments.map((e) => e.cognitiveScore).toList();
    final emotionValues = assessments.map((e) => e.emotionalStability).toList();
    final physicalRiskValues = assessments.map((e) => e.healthRisk).toList();

    final metricCards = [
      MetricSummaryCard(
        title: '우울 지표',
        subtitle: '낮을수록 안정 · 7일 추이',
        score: currentAssessment.depressionScore,
        values: depressionValues,
        dates: metricDates,
        color: const Color(0xFF8A6DFF),
        icon: Icons.sentiment_dissatisfied_outlined,
        lowGood: true,
        helpDescription:
            '통화에서 나타난 부정 감정, 무기력, 외로움 등의 표현을 바탕으로 우울 위험 신호를 0~10점으로 나타냅니다. 점수가 낮을수록 안정적인 상태를 의미합니다.',
      ),
      MetricSummaryCard(
        title: '인지 지표',
        subtitle: '높을수록 양호 · 7일 추이',
        score: currentAssessment.cognitiveScore,
        values: cognitiveValues,
        dates: metricDates,
        color: const Color(0xFF2FB86E),
        icon: Icons.psychology_alt_outlined,
        lowGood: false,
        helpDescription:
            '응답 길이, 어휘 다양성, 반복 표현, 대화의 문맥 일관성 등을 바탕으로 인지 상태를 0~10점으로 나타냅니다. 점수가 높을수록 양호한 상태를 의미합니다.',
      ),
      MetricSummaryCard(
        title: '정서 지표',
        subtitle: '높을수록 안정 · 7일 추이',
        score: currentAssessment.emotionalStability,
        values: emotionValues,
        dates: metricDates,
        color: const Color(0xFF6D7CFF),
        icon: Icons.mood_outlined,
        lowGood: false,
        helpDescription:
            '통화 중 표현된 감정과 말투의 변화 등을 바탕으로 정서적 안정 정도를 0~10점으로 나타냅니다. 점수가 높을수록 정서가 안정적인 상태를 의미합니다.',
      ),
      MetricSummaryCard(
        title: '신체 위험 지표',
        subtitle: '낮을수록 안정 · 7일 추이',
        score: currentAssessment.healthRisk,
        values: physicalRiskValues,
        dates: metricDates,
        color: const Color(0xFFFF8A3D),
        icon: Icons.monitor_heart_outlined,
        lowGood: true,
        helpDescription:
            '통증, 수면 문제, 호흡 불편, 낙상 가능성 등 통화에서 감지된 신체 이상 신호를 종합해 0~10점으로 나타냅니다. 점수가 낮을수록 안정적이며, 점수가 높을수록 추가 확인이나 돌봄이 필요할 수 있습니다.',
      ),
    ];

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HeaderSection(
                        recipient: recipient,
                        latestAssessment: currentAssessment,
                      ),
                      const SizedBox(height: 14),
                      RiskGaugeCard(assessment: currentAssessment),
                      const SizedBox(height: 14),
                      const SectionTitle(title: '영역별 건강 지표'),
                      const SizedBox(height: 10),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth < 340) {
                            return Column(
                              children: [
                                for (var index = 0; index < metricCards.length; index++) ...[
                                  metricCards[index],
                                  if (index != metricCards.length - 1)
                                    const SizedBox(height: 10),
                                ],
                              ],
                            );
                          }

                          final itemWidth = (constraints.maxWidth - 10) / 2;
                          return Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: metricCards
                                .map(
                                  (card) => SizedBox(
                                    width: itemWidth,
                                    child: card,
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      AdherenceCalendarCard(
                        selectedMonth: selectedMonth,
                        selectedDate: selectedDate,
                        selectedAssessment: selectedAssessment,
                        assessments: assessments,
                        showStats: showAdherenceStats,
                        onToggleStats: onToggleAdherenceStats,
                        onMonthChanged: onMonthChanged,
                        onDateSelected: onDateSelected,
                      ),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
