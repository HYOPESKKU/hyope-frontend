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

  // 0은 가장 최근 기간, 1부터는 이전 기간을 의미합니다.
  int periodOffset = 0;

  List<DailyAssessment> get _sortedAssessments {
    final sorted = [...widget.assessments]
      ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
    return sorted;
  }

  int get _periodDays => period == ReportPeriod.weekly ? 7 : 30;

  DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  DateTime? get _periodEnd {
    final sorted = _sortedAssessments;
    if (sorted.isEmpty) return null;
    final latest = _dateOnly(sorted.last.measuredAt);
    return latest.subtract(Duration(days: periodOffset * _periodDays));
  }

  DateTime? get _periodStart {
    final end = _periodEnd;
    if (end == null) return null;
    return end.subtract(Duration(days: _periodDays - 1));
  }

  int get _maxPeriodOffset {
    final sorted = _sortedAssessments;
    if (sorted.isEmpty) return 0;
    final earliest = _dateOnly(sorted.first.measuredAt);
    final latest = _dateOnly(sorted.last.measuredAt);
    return latest.difference(earliest).inDays ~/ _periodDays;
  }

  // 가장 오래된 기록보다 한 기간 앞까지 이동할 수 있게 하여,
  // 데이터가 없는 경우에도 빈 기간 안내를 확인할 수 있습니다.
  bool get _canGoOlder =>
      _sortedAssessments.isNotEmpty && periodOffset <= _maxPeriodOffset;
  bool get _canGoNewer => periodOffset > 0;

  List<DailyAssessment> get _filtered {
    final start = _periodStart;
    final end = _periodEnd;
    if (start == null || end == null) return [];

    return _sortedAssessments.where((assessment) {
      final date = _dateOnly(assessment.measuredAt);
      return !date.isBefore(start) && !date.isAfter(end);
    }).toList();
  }

  String get _rangeLabel {
    final start = _periodStart;
    final end = _periodEnd;
    if (start == null || end == null) return '조회 기간 없음';

    if (start.year == end.year) {
      return '${start.year}년 ${start.month}월 ${start.day}일 - '
          '${end.month}월 ${end.day}일';
    }
    return '${start.year}년 ${start.month}월 ${start.day}일 - '
        '${end.year}년 ${end.month}월 ${end.day}일';
  }

  String get _relativePeriodLabel {
    if (periodOffset == 0) {
      return period == ReportPeriod.weekly ? '최근 7일' : '최근 30일';
    }
    return period == ReportPeriod.weekly
        ? '$periodOffset주 전'
        : '$periodOffset개월 전';
  }

  void _changePeriod(ReportPeriod nextPeriod) {
    setState(() {
      period = nextPeriod;
      periodOffset = 0;
    });
  }

  void _showOlderPeriod() {
    if (!_canGoOlder) return;
    setState(() => periodOffset++);
  }

  void _showNewerPeriod() {
    if (!_canGoNewer) return;
    setState(() => periodOffset--);
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
                  onChanged: _changePeriod,
                ),
                const SizedBox(height: 12),
                _PeriodNavigator(
                  rangeLabel: _rangeLabel,
                  relativeLabel: _relativePeriodLabel,
                  canGoOlder: _canGoOlder,
                  canGoNewer: _canGoNewer,
                  onOlder: _showOlderPeriod,
                  onNewer: _showNewerPeriod,
                ),
                const SizedBox(height: 16),
                if (data.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                      child: Text(
                        periodOffset > 0
                            ? '이전 기간의 분석 기록이 없습니다.'
                            : '해당 기간의 분석 기록이 없습니다.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF8A92A6),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
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

class _PeriodNavigator extends StatelessWidget {
  final String rangeLabel;
  final String relativeLabel;
  final bool canGoOlder;
  final bool canGoNewer;
  final VoidCallback onOlder;
  final VoidCallback onNewer;

  const _PeriodNavigator({
    required this.rangeLabel,
    required this.relativeLabel,
    required this.canGoOlder,
    required this.canGoNewer,
    required this.onOlder,
    required this.onNewer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7EAF2)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: canGoOlder ? onOlder : null,
            tooltip: '이전 기간 보기',
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  relativeLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF4F80FF),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  rangeLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF687085),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: canGoNewer ? onNewer : null,
            tooltip: '다음 기간 보기',
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
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
    // 측정된 날만 평균에 넣는다. 통화가 실패했거나 답을 못 받은 날의 점수는
    // 측정값이 아니라 기본값(placeholder 0.5, 무응답 5.0)이라, 그대로 섞으면
    // 주간·월간 평균이 실제보다 좋거나 나쁘게 나온다.
    final measured = data.where((a) => a.isMeasured).toList();
    final source = measured.isEmpty ? data : measured;

    final items = [
      ('종합 위험도', _avg(source.map((a) => a.overallRisk)), const Color(0xFF4F80FF)),
      ('우울 지표', _avg(source.map((a) => a.depressionScore)), const Color(0xFF8A6DFF)),
      ('인지 지표', _avg(source.map((a) => a.cognitiveScore)), const Color(0xFF2FB86E)),
      ('정서 지표', _avg(source.map((a) => a.emotionalStability)), const Color(0xFF6D7CFF)),
      ('신체 위험', _avg(source.map((a) => a.healthRisk)), const Color(0xFFFF8A3D)),
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
    // 측정 못 한 날은 null로 넘겨 그래프에서 선을 끊는다.
    // 기본값(placeholder 0.5, 무응답 5.0)을 실측처럼 이으면 오해를 부른다.
    final values =
        data.map((a) => a.isMeasured ? a.overallRisk : null).toList();

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
    // 측정된 날 중에서 고른다. 무응답 날은 점수가 기본값 5.0이라 실제로
    // 위험했던 날보다 위로 올라올 수 있고, 그러면 "이 날 조심하세요"가
    // 엉뚱한 날을 가리킨다.
    final measured = data.where((a) => a.isMeasured).toList();
    final source = measured.isEmpty ? data : measured;
    final sorted = [...source]
      ..sort((a, b) => b.overallRisk.compareTo(a.overallRisk));
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