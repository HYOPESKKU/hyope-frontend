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
    final segmentSweep = totalSweep / segments.length;

    for (int i = 0; i < segments.length; i++) {
      final paint = Paint()
        ..color = segments[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        rect,
        startAngle + segmentSweep * i,
        i == segments.length - 1 ? segmentSweep : segmentSweep + 0.001,
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
  final List<double> values;
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
    if (values.length < 2) return;

    final chartLeft = 5.0;
    final chartRight = size.width - 5.0;
    final chartTop = 2.0;
    final chartBottom = showDateLabels ? size.height - 16.0 : size.height;

    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < values.length; i++) {
      final x = chartLeft + (chartRight - chartLeft) * i / (values.length - 1);
      final normalized = (values[i] / 10.0).clamp(0.0, 1.0).toDouble();
      final y = chartBottom - normalized * (chartBottom - chartTop);
      final point = Offset(x, y);
      points.add(point);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
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
    for (final point in points) {
      canvas.drawCircle(point, 2.0, dotPaint);
    }

    if (showDateLabels && dates.length == values.length) {
      final labelIndexes = <int>{0, values.length ~/ 2, values.length - 1};
      for (final index in labelIndexes) {
        final point = points[index];
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
