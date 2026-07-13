import 'package:flutter/material.dart';

import '../models/hyope_models.dart';
import '../widgets/adherence_widgets.dart';
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
    final healthValues = assessments.map((e) => e.healthRisk).toList();
    final emotionValues = assessments.map((e) => e.emotionalStability).toList();

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
                      const SizedBox(height: 10),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final useVerticalCards = constraints.maxWidth < 340;
                          final healthCard = MetricSummaryCard(
                            title: '건강 위험 점수',
                            subtitle: '낮을수록 안정 · 7일 추이',
                            score: currentAssessment.healthRisk,
                            values: healthValues,
                            dates: metricDates,
                            color: const Color(0xFFFF8A3D),
                            icon: Icons.favorite_border,
                            lowGood: true,
                          );
                          final emotionCard = MetricSummaryCard(
                            title: '정서 안정 점수',
                            subtitle: '높을수록 안정 · 7일 추이',
                            score: currentAssessment.emotionalStability,
                            values: emotionValues,
                            dates: metricDates,
                            color: const Color(0xFF6D7CFF),
                            icon: Icons.mood_outlined,
                            lowGood: false,
                          );

                          if (useVerticalCards) {
                            return Column(
                              children: [
                                healthCard,
                                const SizedBox(height: 10),
                                emotionCard,
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: healthCard),
                              const SizedBox(width: 10),
                              Expanded(child: emotionCard),
                            ],
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
