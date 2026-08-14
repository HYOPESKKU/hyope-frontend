import 'package:flutter/material.dart';

import '../painters/hyope_painters.dart';
import 'common_widgets.dart';

class MetricSummaryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  /// null이면 그 날 이 항목을 확인하지 못했다는 뜻이다.
  ///
  /// 통화가 끊겼거나 어르신이 답을 안 하면 서버는 그 카테고리를
  /// incompleteCategories에 담고 점수는 중간값으로 채워 보낸다. 그 값을 그대로
  /// 쓰면 9.0이던 인지 지표가 5.0으로 "떨어진" 것처럼 보이고 증감도 -4.0으로
  /// 잡힌다. 실제로는 못 물어본 것이라, 숫자 대신 미확인으로 표시한다.
  final double? score;

  /// null은 그 날 측정이 안 됐다는 뜻이다(DailyAssessment.isMeasured).
  final List<double?> values;
  final List<DateTime> dates;

  /// values에서 지금 화면에 띄운 날의 위치. 증감을 이 지점 기준으로 계산한다.
  ///
  /// 캘린더에서 과거 날짜를 고르면 그 날 기준으로 비교해야 한다. 또 이 값보다
  /// 앞선 것만 비교 대상으로 삼아야 자기 자신과 비교하는 일이 없다.
  final int currentIndex;

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
    required this.currentIndex,
    required this.color,
    required this.icon,
    required this.lowGood,
    required this.helpDescription,
  });

  @override
  Widget build(BuildContext context) {
    // 기준선은 보고 있는 날의 7일 전. 그 날이 미측정이면 그 앞으로 거슬러
    // 가장 가까운 측정값을 쓴다. null을 0으로 취급하면 증감이 엉뚱하게 커진다.
    //
    // 기준을 values의 끝이 아니라 currentIndex로 잡는 이유는, 캘린더에서 과거
    // 날짜를 고르면 그 날 기준으로 비교해야 하기 때문이다.
    int? prevIndex;
    for (var i = currentIndex - 7; i >= 0; i--) {
      if (values[i] != null) {
        prevIndex = i;
        break;
      }
    }

    // 아직 일주일치가 안 쌓였으면 7일 전 지점 자체가 없다. 그렇다고 비교를
    // 포기하면 며칠씩 아무 변화도 못 보여주므로, 보고 있는 날보다 앞선 것 중
    // 가장 오래된 측정값과 비교한다. 대신 라벨에 실제 비교 날짜를 적어
    // "7일 전"이라고 잘못 읽히지 않게 한다.
    //
    // currentIndex 미만으로 제한하는 게 중요하다. 예전에는 0부터 훑어서, 가장
    // 오래된 날을 선택하면 자기 자신과 비교해 모든 지표가 "유지 +0.0"이 됐다.
    final isSevenDayBase = prevIndex != null;
    if (prevIndex == null) {
      for (var i = 0; i < currentIndex; i++) {
        if (values[i] != null) {
          prevIndex = i;
          break;
        }
      }
    }

    final previousWeek = prevIndex == null ? null : values[prevIndex];
    // 오늘 이 항목을 못 물어봤으면(score == null) 증감을 낼 수 없다. 채움값으로
    // 계산하면 없던 하락·상승이 만들어진다.
    final currentScore = score;
    final diff = (currentScore == null || previousWeek == null)
        ? null
        : currentScore - previousWeek;

    // 비교 대상이 7일 전이 아니면 그 날짜를 그대로 보여준다.
    final String compareLabel;
    if (prevIndex == null || isSevenDayBase || dates.length != values.length) {
      compareLabel = '7일 전 대비';
    } else {
      final d = dates[prevIndex];
      compareLabel = '${d.month}/${d.day} 대비';
    }
    // 변화가 없는 것(유지)도 개선이 아니다. 다섯을 구분해 문구와 색을 따로 준다.
    final String statusLabel;
    final Color statusColor;
    if (currentScore == null) {
      statusLabel = '미확인';
      statusColor = const Color(0xFF9AA2B4);
    } else if (diff == null) {
      statusLabel = '비교 전';
      statusColor = const Color(0xFF9AA2B4);
    } else if (diff == 0) {
      statusLabel = '유지';
      statusColor = const Color(0xFF9AA2B4);
    } else if (lowGood ? diff < 0 : diff > 0) {
      statusLabel = '개선';
      statusColor = const Color(0xFF2FB86E);
    } else {
      statusLabel = '주의';
      statusColor = const Color(0xFFE74747);
    }
    final diffText = diff == null
        ? '—'
        : '${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)}';
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
                  statusLabel,
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
              // 못 물어본 항목에 채움값을 숫자로 띄우면 보호자가 실제 점수로
              // 읽는다. 값을 감추고 확인이 안 됐다는 사실만 남긴다.
              Text(
                currentScore == null ? '미확인' : currentScore.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: currentScore == null ? 18 : 24,
                  height: 1,
                  color: currentScore == null
                      ? const Color(0xFF9AA2B4)
                      : const Color(0xFF182033),
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (currentScore != null) ...[
                const SizedBox(width: 4),
                const Padding(
                  padding: EdgeInsets.only(bottom: 2),
                  child: Text('/10', style: TextStyle(color: Color(0xFF8A92A6))),
                ),
              ],
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
              Expanded(
                child: Text(
                  compareLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
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
