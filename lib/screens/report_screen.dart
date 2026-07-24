import 'package:flutter/material.dart';

import '../models/hyope_models.dart';
import '../painters/hyope_painters.dart';
import '../widgets/common_widgets.dart';

enum ReportPeriod { weekly, monthly }

class ReportScreen extends StatefulWidget {
  final RecipientSummary recipient;
  final List<DailyAssessment> assessments;

  const ReportScreen({
    super.key,
    required this.recipient,
    required this.assessments,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  ReportPeriod period = ReportPeriod.weekly;

  List<DailyAssessment> get _filtered {
    if (widget.assessments.isEmpty) return [];
    final sorted = [...widget.assessments]
      ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
    final latest = sorted.last.measuredAt;
    final days = period == ReportPeriod.weekly ? 7 : 30;
    final cutoff = DateTime(latest.year, latest.month, latest.day)
        .subtract(Duration(days: days - 1));
    return sorted.where((a) => !a.measuredAt.isBefore(cutoff)).toList();
  }

  double _avg(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  @override
  Widget build(BuildContext context) {
    final data = _filtered;
    final periodLabel = period == ReportPeriod.weekly ? '주간' : '월간';

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.recipient.name}님 $periodLabel 리포트'),
        backgroundColor: const Color(0xFFF5F7FB),
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _PeriodToggle(
                  period: period,
                  onChanged: (p) => setState(() => period = p),
                ),
                const SizedBox(height: 16),
                if (data.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(child: Text('해당 기간의 분석 기록이 없습니다.')),
                  )
                else ...[
                  _AverageScoresCard(data: data),
                  const SizedBox(height: 14),
                  _TrendCard(data: data, periodLabel: periodLabel, period: period),
                  const SizedBox(height: 14),
                  _HighlightCard(data: data),
                  const SizedBox(height: 14),
                  const SectionTitle(title: '기간 내 상담 요약'),
                  const SizedBox(height: 10),
                  ...data.reversed.map((a) => _SummaryTile(assessment: a)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PeriodToggle extends StatelessWidget {
  final ReportPeriod period;
  final ValueChanged<ReportPeriod> onChanged;

  const _PeriodToggle({required this.period, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF1F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleButton(
              label: '주간',
              selected: period == ReportPeriod.weekly,
              onTap: () => onChanged(ReportPeriod.weekly),
            ),
          ),
          Expanded(
            child: _ToggleButton(
              label: '월간',
              selected: period == ReportPeriod.monthly,
              onTap: () => onChanged(ReportPeriod.monthly),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(11),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: selected
              ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6)]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: selected ? const Color(0xFF4F80FF) : const Color(0xFF8A92A6),
          ),
        ),
      ),
    );
  }
}

class _AverageScoresCard extends StatelessWidget {
  final List<DailyAssessment> data;

  const _AverageScoresCard({required this.data});

  double _avg(Iterable<double> values) {
    final list = values.toList();
    if (list.isEmpty) return 0;
    return list.reduce((a, b) => a + b) / list.length;
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      ('종합 위험도', _avg(data.map((a) => a.overallRisk)), const Color(0xFF4F80FF)),
      ('우울 지표', _avg(data.map((a) => a.depressionScore)), const Color(0xFF8A6DFF)),
      ('인지 지표', _avg(data.map((a) => a.cognitiveScore)), const Color(0xFF2FB86E)),
      ('정서 지표', _avg(data.map((a) => a.emotionalStability)), const Color(0xFF6D7CFF)),
      ('신체 위험', _avg(data.map((a) => a.healthRisk)), const Color(0xFFFF8A3D)),
    ];

    return HyopeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: '기간 평균 점수'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: items.map((item) {
              return Container(
                width: 140,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: item.$3.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: item.$3.withOpacity(0.18)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.$1,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF7A8294)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.$2.toStringAsFixed(1),
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: item.$3),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  final List<DailyAssessment> data;
  final String periodLabel;
  final ReportPeriod period;

  const _TrendCard({
    required this.data,
    required this.periodLabel,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final values = data.map((a) => a.overallRisk).toList();

    final xLabels = period == ReportPeriod.weekly
        ? data.map((a) => '${a.measuredAt.month}/${a.measuredAt.day}').toList()
        : data.map((a) => '${a.measuredAt.month}/${a.measuredAt.day}').toList();

    return HyopeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(title: '$periodLabel 위험도 추이'),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            width: double.infinity,
            child: values.length < 2
                ? const Center(
                    child: Text('추이를 그리기에 데이터가 부족합니다.', style: TextStyle(color: Color(0xFF9AA2B4))),
                  )
                : CustomPaint(
                    painter: AxisLineChartPainter(
                      values: values,
                      xLabels: period == ReportPeriod.weekly
                          ? xLabels
                          : _weeklyTicks(data),
                      color: const Color(0xFF4F80FF),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

// 월간 그래프는 데이터가 30개라 x축이 빽빽해지므로, 라벨은 대략 일주일 간격으로만 표시.
  // 마지막 라벨과 마지막 7일 간격 라벨이 너무 가까우면(3일 이내) 겹치지 않도록 직전 것을 생략.
  List<String> _weeklyTicks(List<DailyAssessment> data) {
    final lastIndex = data.length - 1;
    final tickIndexes = <int>{};
    for (int i = 0; i < data.length; i += 7) {
      tickIndexes.add(i);
    }
    tickIndexes.add(lastIndex);

    // 마지막 라벨과 너무 가까운 다른 틱은 제거(겹침 방지)
    tickIndexes.removeWhere((i) => i != lastIndex && (lastIndex - i) < 3);

    return List.generate(data.length, (i) {
      if (!tickIndexes.contains(i)) return '';
      final d = data[i].measuredAt;
      return '${d.month}/${d.day}';
    });
  }
}

class _HighlightCard extends StatelessWidget {
  final List<DailyAssessment> data;

  const _HighlightCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final sorted = [...data]..sort((a, b) => b.overallRisk.compareTo(a.overallRisk));
    final highest = sorted.first;

    return HyopeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: '특이점'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: highest.riskLevel.color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: highest.riskLevel.color.withOpacity(0.18)),
            ),
            child: Row(
              children: [
                Icon(highest.riskLevel.icon, color: highest.riskLevel.color),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${highest.measuredAt.month}월 ${highest.measuredAt.day}일 위험도가 가장 높았습니다 (${highest.overallRisk.toStringAsFixed(1)}점)',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        highest.recommendation,
                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF687085)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final DailyAssessment assessment;

  const _SummaryTile({required this.assessment});

  @override
  Widget build(BuildContext context) {
    final hasSummary = assessment.summary.trim().isNotEmpty;
    final d = assessment.measuredAt;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE7EAF2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: assessment.riskLevel.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${d.month}/${d.day}',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: assessment.riskLevel.color),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasSummary ? assessment.summary : '요약이 아직 준비되지 않았습니다.',
                style: TextStyle(
                  color: hasSummary ? const Color(0xFF404A5C) : const Color(0xFF9AA2B4),
                  fontStyle: hasSummary ? FontStyle.normal : FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}