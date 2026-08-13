import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/hyope_models.dart';

class RiskGaugePainter extends CustomPainter {
  final double score;
  final RiskLevel level;

  RiskGaugePainter({required this.score, required this.level});

  @override
  void paint(Canvas canvas, Size size) {
    final normalized = (score.clamp(0.0, 10.0) as num).toDouble() / 10.0;
    const strokeWidth = 22.0;
    final center = Offset(size.width / 2, size.height * 0.90);
    final gaugeCenter = Offset(center.dx, center.dy - 30);
    final radius = math.min(size.width * 0.35, size.height * 0.5);
    final rect = Rect.fromCircle(center: gaugeCenter, radius: radius);

    const totalSweep = math.pi * 1.2;
    final startAngle = math.pi - (totalSweep - math.pi) / 2;

    final segments = [
      const Color(0xFF5BCB9A),
      const Color(0xFFF0CC4A),
      const Color(0xFFF39A45),
      const Color(0xFFE75A5A),
    ];

    const segmentCount = 80;
    for (int i = 0; i < segmentCount; i++) {
      final t0 = i / segmentCount;
      final t1 = (i + 1) / segmentCount;
      final midColor = _colorAt(segments, (t0 + t1) / 2);

      final paint = Paint()
        ..color = midColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        rect,
        startAngle + totalSweep * t0,
        totalSweep / segmentCount * 1.05,
        false,
        paint,
      );
    }

    Offset pointOnGauge(double angle) {
      return Offset(
        gaugeCenter.dx + math.cos(angle) * radius,
        gaugeCenter.dy + math.sin(angle) * radius,
      );
    }

    canvas.drawCircle(
      pointOnGauge(startAngle),
      strokeWidth / 2,
      Paint()..color = segments.first,
    );
    canvas.drawCircle(
      pointOnGauge(startAngle + totalSweep),
      strokeWidth / 2,
      Paint()..color = segments.last,
    );

    final pointerAngle = startAngle + normalized * totalSweep;
    final direction = Offset(math.cos(pointerAngle), math.sin(pointerAngle));
    final tangent = Offset(-direction.dy, direction.dx);

    final innerRadius = radius - strokeWidth / 2;
    final outerRadius = radius + strokeWidth / 2;

    final pointerTip = Offset(
      gaugeCenter.dx + direction.dx * (outerRadius - 1.0),
      gaugeCenter.dy + direction.dy * (outerRadius - 1.0),
    );

    final pointerBaseCenter = Offset(
      gaugeCenter.dx + direction.dx * (innerRadius - 9.5),
      gaugeCenter.dy + direction.dy * (innerRadius - 9.5),
    );

    const pointerHalfWidth = 4.0;
    final pointerBaseLeft = Offset(
      pointerBaseCenter.dx + tangent.dx * pointerHalfWidth,
      pointerBaseCenter.dy + tangent.dy * pointerHalfWidth,
    );
    final pointerBaseRight = Offset(
      pointerBaseCenter.dx - tangent.dx * pointerHalfWidth,
      pointerBaseCenter.dy - tangent.dy * pointerHalfWidth,
    );

    final pointerPath = Path()
      ..moveTo(pointerTip.dx, pointerTip.dy)
      ..lineTo(pointerBaseLeft.dx, pointerBaseLeft.dy)
      ..lineTo(pointerBaseRight.dx, pointerBaseRight.dy)
      ..close();

    canvas.drawPath(pointerPath, Paint()..color = const Color(0xFF1F242E));

    _drawText(
      canvas,
      '돌봄 위험도',
      Offset(size.width / 2, size.height * 0.47),
      const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: Color(0xFF404A5C),
      ),
    );

    _drawText(
      canvas,
      score.toStringAsFixed(1),
      Offset(size.width / 2, size.height * 0.60),
      const TextStyle(
        fontSize: 31,
        fontWeight: FontWeight.w900,
        color: Color(0xFF182033),
      ),
    );

    _drawPill(
      canvas,
      text: level == RiskLevel.observe ? '안정' : level.label,
      center: Offset(size.width / 2, size.height * 0.8),
      backgroundColor: level.color.withOpacity(0.18),
      textColor: level.color,
    );

    _drawText(
      canvas,
      '0',
      Offset(center.dx - radius - 10, center.dy + 12),
      const TextStyle(fontSize: 12, color: Color(0xFF8A92A6), fontWeight: FontWeight.w700),
    );
    _drawText(
      canvas,
      '10',
      Offset(center.dx + radius + 10, center.dy + 12),
      const TextStyle(fontSize: 12, color: Color(0xFF8A92A6), fontWeight: FontWeight.w700),
    );
  }

  Color _colorAt(List<Color> colors, double t) {

    const stops = [0.0, 0.45, 0.7, 1.0];
    final clamped = t.clamp(0.0, 1.0);

    for (int i = 0; i < stops.length - 1; i++) {
      if (clamped <= stops[i + 1] || i == stops.length - 2) {
        final localT = (clamped - stops[i]) / (stops[i + 1] - stops[i]);
        return Color.lerp(colors[i], colors[i + 1], localT.clamp(0.0, 1.0))!;
      }
    }
    return colors.last;
  }

  void _drawText(Canvas canvas, String text, Offset center, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, center - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  void _drawPill(
    Canvas canvas, {
    required String text,
    required Offset center,
    required Color backgroundColor,
    required Color textColor,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

    const horizontalPadding = 12.0;
    const verticalPadding = 6.0;
    final rect = Rect.fromCenter(
      center: center,
      width: textPainter.width + horizontalPadding * 2,
      height: textPainter.height + verticalPadding * 2,
    );

    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(999));
    canvas.drawRRect(rrect, Paint()..color = backgroundColor);
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant RiskGaugePainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.level != level;
  }
}

class MiniLineChartPainter extends CustomPainter {
  /// null은 그 날 측정이 안 됐다는 뜻이다.
  ///
  /// 통화가 실패했거나 어르신이 답을 안 한 날은 점수가 측정값이 아니라
  /// 기본값이다. 그대로 선을 이으면 보호자가 "이 날 좋아졌다"로 읽는데
  /// 실제로는 측정을 못 한 날이라 오해를 부른다. 그래서 선을 끊고 속이 빈
  /// 점으로 그린다.
  final List<double?> values;
  final List<DateTime> dates;
  final Color color;
  final bool showDateLabels;

  MiniLineChartPainter({
    required this.values,
    required this.color,
    this.dates = const [],
    this.showDateLabels = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final chartLeft = 5.0;
    final chartRight = size.width - 5.0;
    final chartTop = 2.0;
    final chartBottom = showDateLabels ? size.height - 16.0 : size.height;

    // 측정이 하루치뿐이면 (length - 1)이 0이라 나눗셈이 깨진다. 예전에는
    // length < 2에서 그냥 return 해 차트 자리가 통째로 비었는데, 서비스 시작
    // 직후나 통화를 막 시작한 어르신에게는 그게 정상 상태다. 빈 칸은 오류처럼
    // 보이므로 한 점이라도 가운데에 찍는다.
    final isSinglePoint = values.length == 1;
    double xAt(int i) => isSinglePoint
        ? (chartLeft + chartRight) / 2
        : chartLeft + (chartRight - chartLeft) * i / (values.length - 1);

    // 측정된 구간만 이어 그린다. 미측정 지점에서 path를 끊는다.
    final path = Path();
    final points = <Offset?>[];
    var penDown = false;

    for (int i = 0; i < values.length; i++) {
      final x = xAt(i);
      final value = values[i];

      if (value == null) {
        points.add(null);
        penDown = false; // 다음 측정값에서 선을 새로 시작한다
        continue;
      }

      final normalized = (value / 10.0).clamp(0.0, 1.0).toDouble();
      final y = chartBottom - normalized * (chartBottom - chartTop);
      final point = Offset(x, y);
      points.add(point);

      if (penDown) {
        path.lineTo(x, y);
      } else {
        path.moveTo(x, y);
        penDown = true;
      }
    }

    final guidePaint = Paint()
      ..color = const Color(0xFFE8ECF5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawLine(Offset(chartLeft, chartBottom), Offset(chartRight, chartBottom), guidePaint);

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = color;
    // 점이 하나뿐이면 이어질 선이 없어 2px 점은 얼룩처럼 보인다. 조금 키워
    // 의도한 표시라는 게 드러나게 한다.
    final dotRadius = isSinglePoint ? 3.5 : 2.0;
    for (final point in points) {
      if (point != null) canvas.drawCircle(point, dotRadius, dotPaint);
    }

    // 미측정 지점은 기준선 위에 회색 빈 점으로 표시한다. 아무것도 안 그리면
    // 그 날 통화가 없었는지 화면 오류인지 구분이 안 된다.
    final missingPaint = Paint()
      ..color = const Color(0xFFC7CDDA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (int i = 0; i < points.length; i++) {
      if (points[i] != null) continue;
      final x = xAt(i);
      canvas.drawCircle(Offset(x, chartBottom - 3), 2.2, missingPaint);
    }

    if (showDateLabels && dates.length == values.length) {
      final labelIndexes = <int>{0, values.length ~/ 2, values.length - 1};
      for (final index in labelIndexes) {
        final point = points[index] ??
            Offset(
              xAt(index),
              chartBottom,
            );
        final date = dates[index];
        _drawAxisLabel(
          canvas,
          '${date.month}/${date.day}',
          Offset(point.dx, size.height - 7),
          const TextStyle(
            fontSize: 8.8,
            fontWeight: FontWeight.w700,
            color: Color(0xFF9AA2B4),
          ),
        );
      }
    }
  }

  void _drawAxisLabel(Canvas canvas, String text, Offset center, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, center - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant MiniLineChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.dates != dates ||
        oldDelegate.color != color ||
        oldDelegate.showDateLabels != showDateLabels;
  }
}

class LineChartPainter extends CustomPainter {
  final List<double> values;
  final Color color;

  LineChartPainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final gridPaint = Paint()
      ..color = const Color(0xFFE8ECF5)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final normalized = values[i].clamp(0.0, 10.0).toDouble() / 10.0;
      final y = size.height - normalized * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.18), color.withOpacity(0.02)],
      ).createShader(Offset.zero & size);
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    final lastX = size.width;
    final lastY = size.height - (values.last.clamp(0.0, 10.0).toDouble() / 10.0) * size.height;
    canvas.drawCircle(Offset(lastX, lastY), 5, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(lastX, lastY), 4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}

class AxisLineChartPainter extends CustomPainter {
  /// null은 그 날 측정이 안 됐다는 뜻이다(DailyAssessment.isMeasured).
  /// 선을 끊고 x축 위 회색 빈 점으로 그린다.
  final List<double?> values;
  final List<String> xLabels;
  final Color color;

  AxisLineChartPainter({
    required this.values,
    required this.xLabels,
    required this.color,
  });

  // 데이터 범위에 맞춰 y축 최소/최대값을 0.5 단위로 계산 (여유값 포함)
  (double, double) get _yRange {
    // 측정된 값만으로 범위를 잡는다. 미측정 지점(null)을 0으로 취급하면
    // y축이 불필요하게 넓어져 실제 변화가 납작하게 보인다.
    final measured = values.whereType<double>().toList();
    if (measured.isEmpty) return (0.0, 10.0);

    final minValue = measured.reduce((a, b) => a < b ? a : b);
    final maxValue = measured.reduce((a, b) => a > b ? a : b);

    double yMin = (((minValue - 0.7) / 0.5).floor() * 0.5);
    double yMax = (((maxValue + 0.7) / 0.5).ceil() * 0.5);

    yMin = yMin.clamp(0.0, 10.0);
    yMax = yMax.clamp(0.0, 10.0);

    // 최소 폭 2.0은 보장 (데이터가 거의 평평할 때 그래프가 너무 납작해지는 것 방지)
    if (yMax - yMin < 2.0) {
      final mid = (yMin + yMax) / 2;
      yMin = (mid - 1.0).clamp(0.0, 10.0);
      yMax = (mid + 1.0).clamp(0.0, 10.0);
    }

    return (yMin, yMax);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    const leftAxisWidth = 28.0;
    const bottomAxisHeight = 22.0;
    final chartLeft = leftAxisWidth;
    final chartRight = size.width;
    final chartTop = 6.0;
    final chartBottom = size.height - bottomAxisHeight;

    final (yMin, yMax) = _yRange;
    const yStep = 0.5;
    final ySteps = ((yMax - yMin) / yStep).round();

    final gridPaint = Paint()
      ..color = const Color(0xFFEFF1F6)
      ..strokeWidth = 1;
    const axisTextStyle = TextStyle(
      fontSize: 9,
      color: Color(0xFF9AA2B4),
      fontWeight: FontWeight.w600,
    );

    // y축 그리드 + 라벨 (0.5 단위 전체 표시)
    for (int i = 0; i <= ySteps; i++) {
      final value = yMin + i * yStep;
      final normalized = (value - yMin) / (yMax - yMin);
      final y = chartBottom - normalized * (chartBottom - chartTop);

      canvas.drawLine(Offset(chartLeft, y), Offset(chartRight, y), gridPaint);

      _drawText(
        canvas,
        value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1),
        Offset(chartLeft - 8, y),
        axisTextStyle,
        alignRight: true,
      );
    }

    // x축 라벨
    for (int i = 0; i < xLabels.length; i++) {
      if (xLabels[i].isEmpty) continue;
      final x = chartLeft + (chartRight - chartLeft) * i / (values.length - 1);
      _drawText(
        canvas,
        xLabels[i],
        Offset(x, chartBottom + 12),
        axisTextStyle,
      );
    }

    // 라인 — 측정된 구간만 이어 그린다. 미측정 지점에서 끊어 별개 구간으로
    // 나눈다. 채우기도 구간별로 따로 그려야 끊긴 자리가 메워지지 않는다.
    final path = Path();
    final points = <Offset?>[];
    final segments = <List<Offset>>[];
    var current = <Offset>[];

    for (int i = 0; i < values.length; i++) {
      final x = chartLeft + (chartRight - chartLeft) * i / (values.length - 1);
      final value = values[i];

      if (value == null) {
        points.add(null);
        if (current.length > 1) segments.add(current);
        current = <Offset>[];
        continue;
      }

      final normalized = ((value - yMin) / (yMax - yMin)).clamp(0.0, 1.0);
      final y = chartBottom - normalized * (chartBottom - chartTop);
      final point = Offset(x, y);
      points.add(point);

      if (current.isEmpty) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      current.add(point);
    }
    if (current.length > 1) segments.add(current);

    final fillShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [color.withOpacity(0.16), color.withOpacity(0.0)],
    ).createShader(
      Rect.fromLTWH(chartLeft, chartTop, chartRight - chartLeft, chartBottom - chartTop),
    );

    for (final segment in segments) {
      final fillPath = Path()..moveTo(segment.first.dx, segment.first.dy);
      for (final p in segment.skip(1)) {
        fillPath.lineTo(p.dx, p.dy);
      }
      fillPath
        ..lineTo(segment.last.dx, chartBottom)
        ..lineTo(segment.first.dx, chartBottom)
        ..close();
      canvas.drawPath(fillPath, Paint()..shader = fillShader);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    for (final p in points) {
      if (p != null) canvas.drawCircle(p, 2.6, Paint()..color = color);
    }

    // 미측정 지점은 x축 위 회색 빈 점으로 남긴다. 아무 표시도 없으면 그 날
    // 통화가 없었는지 화면 오류인지 구분이 안 된다.
    final missingPaint = Paint()
      ..color = const Color(0xFFC7CDDA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (int i = 0; i < points.length; i++) {
      if (points[i] != null) continue;
      final x = chartLeft + (chartRight - chartLeft) * i / (values.length - 1);
      canvas.drawCircle(Offset(x, chartBottom - 4), 2.8, missingPaint);
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset anchor,
    TextStyle style, {
    bool alignRight = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    final offset = alignRight
        ? Offset(anchor.dx - tp.width, anchor.dy - tp.height / 2)
        : Offset(anchor.dx - tp.width / 2, anchor.dy - tp.height / 2);
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant AxisLineChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.xLabels != xLabels ||
        oldDelegate.color != color;
  }
}