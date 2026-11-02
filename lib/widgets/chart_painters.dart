import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/chart_data.dart';
import '../utils/values.dart';

class ChartStyle {
  const ChartStyle({
    required this.gridColor,
    required this.axisColor,
    required this.labelColor,
    required this.valueColor,
    required this.surfaceColor,
    required this.palette,
  });

  final Color gridColor;
  final Color axisColor;
  final Color labelColor;
  final Color valueColor;
  final Color surfaceColor;
  final List<Color> palette;
}

TextPainter _layoutText(
  String text,
  TextStyle style, {
  double maxWidth = 200,
  TextAlign textAlign = TextAlign.left,
}) {
  return TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    textAlign: textAlign,
    maxLines: 1,
    ellipsis: '\u2026',
  )..layout(maxWidth: maxWidth);
}

String _shortValue(double value) {
  if (value.abs() >= 1000) return formatCompactNumber(value);
  return formatNumber(value, maxDecimals: 2);
}

class BarChartPainter extends CustomPainter {
  BarChartPainter({required this.groups, required this.style});

  final List<ChartGroup> groups;
  final ChartStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    if (groups.isEmpty || size.width <= 0 || size.height <= 0) return;
    canvas.clipRect(Offset.zero & size);

    final values = [for (final group in groups) group.value];
    final scale = buildAxisScale(
      values.reduce(math.min),
      values.reduce(math.max),
    );

    final rotateLabels =
        groups.length > 6 || groups.any((group) => group.label.length > 10);
    const leftPadding = 58.0;
    const rightPadding = 10.0;
    const topPadding = 24.0;
    final bottomPadding = rotateLabels ? 78.0 : 36.0;
    final chartRect = Rect.fromLTRB(
      leftPadding,
      topPadding,
      size.width - rightPadding,
      size.height - bottomPadding,
    );
    if (chartRect.width < 10 || chartRect.height < 10) return;

    double yFor(double value) {
      return chartRect.bottom -
          (value - scale.min) / (scale.max - scale.min) * chartRect.height;
    }

    final labelStyle = TextStyle(
      fontSize: 10.5,
      color: style.labelColor,
      height: 1.1,
    );
    final valueStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: style.valueColor,
      height: 1.1,
    );

    final gridPaint = Paint()
      ..color = style.gridColor
      ..strokeWidth = 1;
    for (final tick in scale.ticks) {
      final y = yFor(tick);
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        gridPaint,
      );
      final text = _layoutText(
        formatCompactNumber(tick),
        labelStyle,
        maxWidth: 46,
        textAlign: TextAlign.right,
      );
      text.paint(
        canvas,
        Offset(chartRect.left - 8 - text.width, y - text.height / 2),
      );
    }

    if (scale.min < 0 && scale.max > 0) {
      final zeroY = yFor(0);
      canvas.drawLine(
        Offset(chartRect.left, zeroY),
        Offset(chartRect.right, zeroY),
        Paint()
          ..color = style.axisColor
          ..strokeWidth = 1.2,
      );
    }

    final slot = chartRect.width / groups.length;
    final barWidth = math.min(64.0, slot * 0.5);
    final zeroY = yFor(0).clamp(chartRect.top, chartRect.bottom).toDouble();
    final showValues = slot >= 38 && groups.length <= 14;

    for (var index = 0; index < groups.length; index++) {
      final group = groups[index];
      final centerX = chartRect.left + slot * (index + 0.5);
      final valueY = yFor(group.value);
      final top = math.min(valueY, zeroY);
      final bottom = math.max(valueY, zeroY);
      final rect = Rect.fromLTWH(
        centerX - barWidth / 2,
        top,
        barWidth,
        math.max(2, bottom - top),
      );
      final color = style.palette[index % style.palette.length];
      final shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.95),
          color.withValues(alpha: 0.55),
        ],
      ).createShader(rect);
      final rounded = RRect.fromRectAndCorners(
        rect,
        topLeft: const Radius.circular(5),
        topRight: const Radius.circular(5),
        bottomLeft: Radius.circular(group.value < 0 ? 5 : 2),
        bottomRight: Radius.circular(group.value < 0 ? 5 : 2),
      );
      canvas.drawRRect(rounded, Paint()..shader = shader);

      if (showValues) {
        final text = _layoutText(
          _shortValue(group.value),
          valueStyle,
          maxWidth: math.max(28, slot - 4),
          textAlign: TextAlign.center,
        );
        final y = group.value < 0
            ? rect.bottom + 4
            : rect.top - text.height - 4;
        text.paint(canvas, Offset(centerX - text.width / 2, y));
      }

      if (rotateLabels) {
        final text = _layoutText(group.label, labelStyle, maxWidth: 100);
        canvas.save();
        canvas.translate(centerX, chartRect.bottom + 10);
        canvas.rotate(-0.55);
        text.paint(canvas, Offset(-text.width, 0));
        canvas.restore();
      } else {
        final text = _layoutText(
          group.label,
          labelStyle,
          maxWidth: math.max(20, slot - 6),
          textAlign: TextAlign.center,
        );
        text.paint(canvas, Offset(centerX - text.width / 2, chartRect.bottom + 9));
      }
    }
  }

  @override
  bool shouldRepaint(covariant BarChartPainter oldDelegate) => true;
}

class LineChartPainter extends CustomPainter {
  LineChartPainter({required this.groups, required this.style});

  final List<ChartGroup> groups;
  final ChartStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    if (groups.isEmpty || size.width <= 0 || size.height <= 0) return;
    canvas.clipRect(Offset.zero & size);

    final values = [for (final group in groups) group.value];
    final scale = buildAxisScale(
      values.reduce(math.min),
      values.reduce(math.max),
    );

    const leftPadding = 58.0;
    const rightPadding = 14.0;
    const topPadding = 22.0;
    const bottomPadding = 38.0;
    final chartRect = Rect.fromLTRB(
      leftPadding,
      topPadding,
      size.width - rightPadding,
      size.height - bottomPadding,
    );
    if (chartRect.width < 10 || chartRect.height < 10) return;

    double yFor(double value) {
      return chartRect.bottom -
          (value - scale.min) / (scale.max - scale.min) * chartRect.height;
    }

    final labelStyle = TextStyle(
      fontSize: 10.5,
      color: style.labelColor,
      height: 1.1,
    );

    final gridPaint = Paint()
      ..color = style.gridColor
      ..strokeWidth = 1;
    for (final tick in scale.ticks) {
      final y = yFor(tick);
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        gridPaint,
      );
      final text = _layoutText(
        formatCompactNumber(tick),
        labelStyle,
        maxWidth: 46,
        textAlign: TextAlign.right,
      );
      text.paint(
        canvas,
        Offset(chartRect.left - 8 - text.width, y - text.height / 2),
      );
    }

    final zeroY = yFor(0).clamp(chartRect.top, chartRect.bottom).toDouble();
    if (scale.min < 0 && scale.max > 0) {
      canvas.drawLine(
        Offset(chartRect.left, zeroY),
        Offset(chartRect.right, zeroY),
        Paint()
          ..color = style.axisColor
          ..strokeWidth = 1.2,
      );
    }

    final slot = chartRect.width / groups.length;
    final points = <Offset>[];
    for (var index = 0; index < groups.length; index++) {
      points.add(Offset(
        chartRect.left + slot * (index + 0.5),
        yFor(groups[index].value),
      ));
    }

    final color = style.palette.first;
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var index = 1; index < points.length; index++) {
      final previous = points[index - 1];
      final current = points[index];
      final midX = (previous.dx + current.dx) / 2;
      linePath.cubicTo(
        midX,
        previous.dy,
        midX,
        current.dy,
        current.dx,
        current.dy,
      );
    }

    if (points.length > 1) {
      final fillPath = Path.from(linePath)
        ..lineTo(points.last.dx, zeroY)
        ..lineTo(points.first.dx, zeroY)
        ..close();
      final fillShader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.24),
          color.withValues(alpha: 0.015),
        ],
      ).createShader(chartRect);
      canvas.drawPath(fillPath, Paint()..shader = fillShader);
    }

    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    if (points.length <= 60) {
      for (final point in points) {
        canvas.drawCircle(
          point,
          4,
          Paint()..color = style.surfaceColor,
        );
        canvas.drawCircle(point, 2.6, Paint()..color = color);
      }
    }

    final labelStep = (groups.length / 6).ceil().clamp(1, groups.length);
    double? lastRight;
    for (var index = 0; index < groups.length; index++) {
      final isLast = index == groups.length - 1;
      if (index % labelStep != 0 && !isLast) continue;
      final widthFactor = isLast ? 1 : labelStep;
      final text = _layoutText(
        groups[index].label,
        labelStyle,
        maxWidth: math.max(30, slot * widthFactor * 0.92),
        textAlign: TextAlign.center,
      );
      final left = points[index].dx - text.width / 2;
      if (lastRight != null && left < lastRight + 8) continue;
      text.paint(canvas, Offset(left, chartRect.bottom + 10));
      lastRight = left + text.width;
    }
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) => true;
}

class DonutChartPainter extends CustomPainter {
  DonutChartPainter({
    required this.groups,
    required this.style,
    required this.centerLabel,
    required this.centerValue,
  });

  final List<ChartGroup> groups;
  final ChartStyle style;
  final String centerLabel;
  final String centerValue;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    canvas.clipRect(Offset.zero & size);
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 12;
    if (radius <= 14) return;
    final strokeWidth = radius * 0.38;
    final ringRect = Rect.fromCircle(
      center: center,
      radius: radius - strokeWidth / 2,
    );

    canvas.drawArc(
      ringRect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = style.gridColor.withValues(alpha: 0.5),
    );

    final total = groups.fold<double>(0, (sum, group) => sum + group.value);
    if (total > 0) {
      var start = -math.pi / 2;
      for (var index = 0; index < groups.length; index++) {
        final value = groups[index].value;
        if (value <= 0) continue;
        final sweep = math.pi * 2 * value / total;
        final gap = groups.length > 1 ? math.min(0.035, sweep * 0.18) : 0.0;
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..color = style.palette[index % style.palette.length];
        canvas.drawArc(
          ringRect,
          start + gap / 2,
          math.max(0.006, sweep - gap),
          false,
          paint,
        );
        start += sweep;
      }
    }

    if (centerValue.isNotEmpty) {
      final valuePainter = TextPainter(
        text: TextSpan(
          text: centerValue,
          style: TextStyle(
            fontSize: math.max(16, math.min(30, radius * 0.24)),
            fontWeight: FontWeight.w800,
            color: style.valueColor,
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '\u2026',
      )..layout(maxWidth: radius * 1.2);
      final labelPainter = TextPainter(
        text: TextSpan(
          text: centerLabel,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: style.labelColor,
            height: 1.1,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: radius * 1.2);
      final totalHeight = valuePainter.height + 4 + labelPainter.height;
      final top = center.dy - totalHeight / 2;
      valuePainter.paint(
        canvas,
        Offset(center.dx - valuePainter.width / 2, top),
      );
      labelPainter.paint(
        canvas,
        Offset(center.dx - labelPainter.width / 2, top + valuePainter.height + 4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) => true;
}
