import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tiny inline sparkline chart, designed to render inside chat bubble text.
/// No axes, no labels (except optional start/end labels below).
///
/// Expected data format:
///   series[0].data = [{x: "Mon", y: 2}, {x: "Tue", y: 4}, ...]
///   config.options = {height: 40, show_area: true, color: "muted_green"}
class SparklineView extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool inline;

  const SparklineView({super.key, required this.data, this.inline = false});

  @override
  Widget build(BuildContext context) {
    final config = data['config'] as Map<String, dynamic>? ?? {};
    final options = config['options'] as Map<String, dynamic>? ?? {};
    final series = (data['series'] as List?) ?? [];
    if (series.isEmpty) return const SizedBox.shrink();

    final firstSeries = series[0] as Map<String, dynamic>;
    final points = (firstSeries['data'] as List?) ?? [];
    if (points.isEmpty) return const SizedBox.shrink();

    final height = (_parseDouble(options['height']) ?? 40).clamp(24.0, 80.0);
    final showArea = options['show_area']?.toString() != 'false';
    final colorName = options['color']?.toString() ?? 'muted_green';

    final lineColor = _resolveColor(colorName, context);
    final values = points.map((p) => ((p as Map<String, dynamic>)['y'] as num? ?? 0).toDouble()).toList();
    final labels = points.map((p) => (p as Map<String, dynamic>)['x']?.toString() ?? '').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: _SparklinePainter(
              values: values,
              lineColor: lineColor,
              showArea: showArea,
              isDark: AppPallete.isDarkMode(context),
            ),
          ),
        ),
        if (labels.length >= 2) ...[
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                labels.first,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 8,
                  color: AppPallete.getTextMuted(context),
                ),
              ),
              Text(
                labels.last,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 8,
                  color: AppPallete.getTextMuted(context),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Color _resolveColor(String name, BuildContext context) {
    switch (name) {
      case 'muted_blue':
        return AppPallete.isDarkMode(context)
            ? const Color(0xFF6B8FBF)
            : const Color(0xFF5B7FAF);
      case 'muted_green':
      default:
        return AppPallete.isDarkMode(context)
            ? const Color(0xFF6B8F6B)
            : const Color(0xFF5B7F5B);
    }
  }

  double? _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color lineColor;
  final bool showArea;
  final bool isDark;

  _SparklinePainter({
    required this.values,
    required this.lineColor,
    required this.showArea,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final minVal = values.reduce((a, b) => a < b ? a : b);
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final range = maxVal - minVal;
    final effectiveRange = range == 0 ? 1.0 : range;

    final path = Path();
    final areaPath = Path();

    for (int i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final normalized = (values[i] - minVal) / effectiveRange;
      final y = size.height - (normalized * size.height * 0.85) - (size.height * 0.075);

      if (i == 0) {
        path.moveTo(x, y);
        areaPath.moveTo(x, y);
      } else {
        // Smooth curve using cubic bezier
        final prevX = ((i - 1) / (values.length - 1)) * size.width;
        final prevNorm = (values[i - 1] - minVal) / effectiveRange;
        final prevY = size.height - (prevNorm * size.height * 0.85) - (size.height * 0.075);
        final midX = (prevX + x) / 2;

        path.cubicTo(midX, prevY, midX, y, x, y);
        areaPath.cubicTo(midX, prevY, midX, y, x, y);
      }
    }

    // Draw area fill
    if (showArea) {
      areaPath.lineTo(size.width, size.height);
      areaPath.lineTo(0, size.height);
      areaPath.close();

      final areaPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, 0),
          Offset(0, size.height),
          [
            lineColor.withValues(alpha: 0.25),
            lineColor.withValues(alpha: 0.02),
          ],
        );
      canvas.drawPath(areaPath, areaPaint);
    }

    // Draw line
    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.lineColor != lineColor;
  }
}
