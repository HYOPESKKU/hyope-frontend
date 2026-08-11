import 'package:flutter/material.dart';
import 'report_screen.dart';

import '../models/hyope_models.dart';
import '../utils/date_utils.dart';
import '../widgets/adherence_widgets.dart';
import '../widgets/common_widgets.dart';
import '../widgets/header_section.dart';
import '../widgets/metric_widgets.dart';
import '../widgets/recipient_info_card.dart';
import '../widgets/risk_widgets.dart';

class DashboardScreen extends StatelessWidget {
  final RecipientSummary recipient;
  final List<DailyAssessment> assessments;
  final DateTime selectedMonth;
  final DateTime? selectedDate;
  final DailyAssessment? selectedAssessment;
  final bool showAdherenceStats;
  final bool isCalendarExpanded;
  final VoidCallback onToggleAdherenceStats;
  final VoidCallback onToggleCalendarExpanded;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback? onNotificationTap;
  final bool hasUnreadNotification;

  const DashboardScreen({
    super.key,
    required this.recipient,
    required this.assessments,
    required this.selectedMonth,
    required this.selectedDate,
    required this.selectedAssessment,
    required this.showAdherenceStats,
    required this.isCalendarExpanded,
    required this.onToggleAdherenceStats,
    required this.onToggleCalendarExpanded,
    required this.onMonthChanged,
    required this.onDateSelected,
    this.onNotificationTap,
    this.hasUnreadNotification = false,
  });

  // 선택된 날짜가 없으면 최신(오늘) 데이터를 기본으로 보여줌
  DailyAssessment? get displayedAssessment =>
      selectedAssessment ?? (assessments.isNotEmpty ? assessments.last : null);

  DateTime get latestAssessmentDate {
    if (assessments.isEmpty) return dateOnly(DateTime.now());
    return assessments
        .map((assessment) => dateOnly(assessment.measuredAt))
        .reduce((latest, date) => date.isAfter(latest) ? date : latest);
  }

  String get _riskTitle {
    final date = selectedDate;
    if (date == null || isSameDay(date, latestAssessmentDate)) {
      return '오늘의 돌봄 위험도';
    }
    return '${date.year}년 ${date.month}월 ${date.day}일의 돌봄 위험도';
  }

  @override
  Widget build(BuildContext context) {
    // 분석 데이터가 아예 없는 경우: 정보 카드 + 안내 문구만 표시
    if (assessments.isEmpty) {
      return _EmptyDashboard(
        recipient: recipient,
        onNotificationTap: onNotificationTap,
        hasUnreadNotification: hasUnreadNotification,
      );
    }

    final metricDates = assessments.map((e) => e.measuredAt).toList();
    // 통화가 실패했거나 답을 못 받은 날은 점수가 측정값이 아니라 기본값이다.
    // 그대로 선을 이으면 보호자가 "이 날 좋아졌다"로 읽으므로 null로 넘겨
    // 그래프에서 끊어 그린다(DailyAssessment.isMeasured 참고).
    List<double?> valuesOf(double Function(DailyAssessment) pick) =>
        assessments.map((e) => e.isMeasured ? pick(e) : null).toList();

    final depressionValues = valuesOf((e) => e.depressionScore);
    final cognitiveValues = valuesOf((e) => e.cognitiveScore);
    final emotionValues = valuesOf((e) => e.emotionalStability);
    final physicalRiskValues = valuesOf((e) => e.healthRisk);
    final current = displayedAssessment!;

    final metricCards = [
      MetricSummaryCard(
        title: '우울 지표',
        subtitle: '낮을수록 안정 · 7일 추이',
        score: current.depressionScore,
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
        score: current.cognitiveScore,
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
        score: current.emotionalStability,
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
        score: current.healthRisk,
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
                        latestAssessment: current,
                        onNotificationTap: onNotificationTap,
                        hasUnreadNotification: hasUnreadNotification,
                      ),
                      const SizedBox(height: 14),
                      RecipientInfoCard(recipient: recipient),
                      const SizedBox(height: 14),

                      // 접이식 캘린더
                      _CollapsibleCalendarHeader(
                        isExpanded: isCalendarExpanded,
                        selectedDate: selectedDate,
                        latestAssessmentDate: latestAssessmentDate,
                        onTap: onToggleCalendarExpanded,
                      ),
                     if (isCalendarExpanded) ...[
                        const SizedBox(height: 8),
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
                      ],
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ReportScreen(
                                  recipient: recipient,
                                  assessments: assessments,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.summarize_rounded, size: 19),
                          label: const Text('주간 · 월간 리포트 보기'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF4F80FF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      RiskGaugeCard(
                        assessment: current,
                        title: _riskTitle,
                        phoneNumber: recipient.phoneNumber,
                      ),
                      if (current.incompleteCategories.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        IncompleteCategoriesBadge(categories: current.incompleteCategories),
                      ],
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

// 통화 분석 기록이 아직 없는 대상자용 — 지표 카드 대신 안내 카드 하나만 보여준다.
// (assessments가 비어 있으면 .last/.reduce가 예외를 던지는 위 build()의 계산들을 아예 스킵한다)
class _EmptyDashboard extends StatelessWidget {
  final RecipientSummary recipient;
  final VoidCallback? onNotificationTap;
  final bool hasUnreadNotification;

  const _EmptyDashboard({
    required this.recipient,
    this.onNotificationTap,
    this.hasUnreadNotification = false,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HeaderSection(recipient: recipient, latestAssessment: null),
                const SizedBox(height: 14),
                RecipientInfoCard(recipient: recipient),
                const SizedBox(height: 14),
                HyopeCard(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.insights_outlined,
                        size: 40,
                        color: Color(0xFF9AA2B4),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '아직 통화 분석 기록이 없습니다',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF182033),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '첫 통화가 완료되면 여기에 우울·인지·정서·신체 지표가 표시됩니다.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: Color(0xFF7A8294),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CollapsibleCalendarHeader extends StatelessWidget {
  final bool isExpanded;
  final DateTime? selectedDate;
  final DateTime latestAssessmentDate;
  final VoidCallback onTap;

  const _CollapsibleCalendarHeader({
    required this.isExpanded,
    required this.selectedDate,
    required this.latestAssessmentDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLatestDate = selectedDate == null ||
        isSameDay(selectedDate!, latestAssessmentDate);
    final label = isLatestDate
        ? '오늘'
        : '${selectedDate!.month}월 ${selectedDate!.day}일';

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE7EAF2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_outlined, color: Color(0xFF4F80FF)),
            const SizedBox(width: 10),
            Text(
              '$label 기록 · 캘린더로 다른 날짜 보기',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
          ],
        ),
      ),
    );
  }
}