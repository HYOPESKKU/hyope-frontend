import 'package:flutter/material.dart';

import '../painters/hyope_painters.dart';
import 'common_widgets.dart';

class MetricSummaryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double score;
  /// null은 그 날 측정이 안 됐다는 뜻이다(DailyAssessment.isMeasured).
  final List<double?> values;
  final List<DateTime> dates;
  final Color color;
  final IconData icon;
  final bool lowGood;
  final String helpDescription;

  const MetricSummaryCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.score,
    required this.values,
    required this.dates,
    required this.color,
    required this.icon,
    required this.lowGood,
    required this.helpDescription,
  });

  @override
  Widget build(BuildContext context) {
    // 7일 전이 미측정이면 그 앞으로 거슬러 가장 가까운 측정값을 쓴다.
    // null을 0으로 취급하면 증감이 엉뚱하게 커진다.
    double previousWeek = score;
    for (var i = values.length - 8; i >= 0; i--) {
      final v = values[i];
      if (v != null) {
        previousWeek = v;
        break;
      }
    }
    final diff = score - previousWeek;
    final isBetter = lowGood ? diff <= 0 : diff >= 0;
    final statusColor = isBetter ? const Color(0xFF2FB86E) : const Color(0xFFE74747);
    final diffText = '${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)}';
    final chartStart = values.length > 7 ? values.length - 7 : 0;
    final chartValues = values.sublist(chartStart);
    final chartDates = dates.length == values.length ? dates.sublist(chartStart) : const <DateTime>[];

    return HyopeCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 카드 4장이 2열로 붙어 있어 어느 지표인지 아이콘으로 먼저
              // 구분하게 된다. 30x30일 때는 표정·심전도 같은 모양이 뭉개져
              // 제목을 읽어야 알 수 있었다.
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const Spacer(),
              // IconButton은 기본이 MaterialTapTargetSize.padded라, constraints로
              // 28x28을 줘도 레이아웃에서는 48x48을 차지한다. 시각적 아이콘은 그
              // 안에 가운데 놓여 좌우로 10dp씩 투명한 여백이 생기고, 그만큼
              // 아이콘이 카드 안쪽으로 들어가 아래 증감 수치(+0.0)의 오른쪽 끝과
              // 어긋난다. alignment는 constraints 안에서만 작동해 이 여백을
              // 넘지 못한다.
              //
              // shrinkWrap으로 그 여백을 없애고, 대신 버튼 크기를 44로 키워
              // 터치 영역을 지킨다(28로 두면 누르기 어려워진다). 아이콘을
              // 오른쪽에 붙이면 +0.0과 같은 세로선에 놓인다.
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isBetter ? '개선' : '주의',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => _showMetricHelp(context),
                tooltip: '$title 설명',
                alignment: Alignment.centerRight,
                constraints: const BoxConstraints.tightFor(width: 44, height: 44),
                style: IconButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(
                  Icons.help_outline_rounded,
                  size: 19,
                  color: Color(0xFF8A92A6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF687085),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                score.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 24,
                  height: 1,
                  color: Color(0xFF182033),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Text('/10', style: TextStyle(color: Color(0xFF8A92A6))),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10.5, color: Color(0xFF9AA2B4)),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Expanded(
                child: Text(
                  '7일 전 대비',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF8A92A6),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                diffText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          SizedBox(
            height: 56,
            child: CustomPaint(
              painter: MiniLineChartPainter(
                values: chartValues,
                dates: chartDates,
                color: color,
                showDateLabels: true,
              ),
              size: Size.infinite,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showMetricHelp(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 12, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$title란?',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF182033),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          '$helpDescription\n\n이 점수는 통화 내용을 바탕으로 산출한 참고 지표이며, 의료진의 진단을 대신하지 않습니다.',
          style: const TextStyle(
            fontSize: 13.5,
            height: 1.55,
            color: Color(0xFF687085),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}

class CompactTrendCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<double> values;
  final Color color;
  final IconData icon;
  final bool lowGood;

  const CompactTrendCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.values,
    required this.color,
    required this.icon,
    required this.lowGood,
  });

  @override
  Widget build(BuildContext context) {
    final latest = values.isEmpty ? 0.0 : values.last;
    final previousWeek = values.length > 7 ? values[values.length - 8] : latest;
    final diff = latest - previousWeek;
    final isBetter = lowGood ? diff <= 0 : diff >= 0;
    final statusColor = isBetter ? const Color(0xFF2FB86E) : const Color(0xFFE74747);
    final diffText = '${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)}';

    return HyopeCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isBetter ? '개선' : '주의',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF687085),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                latest.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 24,
                  height: 1,
                  color: Color(0xFF182033),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Text('/10', style: TextStyle(color: Color(0xFF8A92A6))),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF9AA2B4)),
                ),
              ),
              Text(
                diffText,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 52,
            child: CustomPaint(
              painter: MiniLineChartPainter(values: values.takeLast(14), color: color),
              size: Size.infinite,
            ),
          ),
        ],
      ),
    );
  }
}

class TrendDetailCard extends StatelessWidget {
  final String title;
  final String description;
  final List<double> values;
  final Color color;
  final bool lowGood;

  const TrendDetailCard({
    super.key,
    required this.title,
    required this.description,
    required this.values,
    required this.color,
    required this.lowGood,
  });

  @override
  Widget build(BuildContext context) {
    final latest = values.isEmpty ? 0.0 : values.last;
    final previousWeek = values.length > 7 ? values[values.length - 8] : latest;
    final diff = latest - previousWeek;
    final isBetter = lowGood ? diff <= 0 : diff >= 0;

    return HyopeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            title: title,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (isBetter ? const Color(0xFF2FB86E) : const Color(0xFFE74747))
                    .withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                isBetter ? '개선' : '주의',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isBetter ? const Color(0xFF2FB86E) : const Color(0xFFE74747),
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(description, style: const TextStyle(color: Color(0xFF8A92A6), fontSize: 13)),
          const SizedBox(height: 18),
          SizedBox(
            height: 150,
            child: CustomPaint(
              painter: LineChartPainter(values: values, color: color),
              size: Size.infinite,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _SmallInfoBox(label: '최근 점수', value: latest.toStringAsFixed(1)),
              const SizedBox(width: 10),
              _SmallInfoBox(
                label: '7일 전 대비',
                value: '${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallInfoBox extends StatelessWidget {
  final String label;
  final String value;

  const _SmallInfoBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8ECF5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFF8A92A6), fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF182033),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension TakeLastList on List<double> {
  List<double> takeLast(int count) {
    if (length <= count) return this;
    return sublist(length - count);
  }
}
