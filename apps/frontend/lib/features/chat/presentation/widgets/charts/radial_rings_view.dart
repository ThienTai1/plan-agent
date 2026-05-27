import 'dart:math';
import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:google_fonts/google_fonts.dart';

/// Apple Watch Activity Rings-style progress visualization.
/// Each series represents one ring with a single progress value (0.0–1.0).
///
/// Expected data format:
///   series[i].label = "Goal Name"
///   series[i].data[0].y = 0.72  (progress)
///   config.options = {ring_thickness: 4}
class RadialRingsView extends StatelessWidget {
  final Map<String, dynamic> data;

  const RadialRingsView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final config = data['config'] as Map<String, dynamic>? ?? {};
    final options = config['options'] as Map<String, dynamic>? ?? {};
    final series = (data['series'] as List?) ?? [];
    if (series.isEmpty) return const Center(child: Text('No data'));

    final ringThickness = _parseDouble(options['ring_thickness']) ?? 4.0;

    // Parse ring data
    final rings = series.map((s) {
      final sMap = s as Map<String, dynamic>;
      final points = (sMap['data'] as List?) ?? [];
      final progress = points.isNotEmpty
          ? ((points[0] as Map<String, dynamic>)['y'] as num? ?? 0).toDouble().clamp(0.0, 1.0)
          : 0.0;
      return _RingData(
        label: sMap['label']?.toString() ?? '',
        progress: progress,
      );
    }).toList();

    // Monochrome ring colors — concentric greys with increasing brightness
    final ringColors = [
      AppPallete.getTextMuted(context),
      AppPallete.getTextSecondary(context),
      AppPallete.getTextPrimary(context),
    ];

    final ringSize = 110.0;

    return Row(
      children: [
        // Rings
        SizedBox(
          width: ringSize,
          height: ringSize,
          child: CustomPaint(
            painter: _RingsPainter(
              rings: rings,
              colors: ringColors,
              ringThickness: ringThickness,
              trackColor: AppPallete.getBorderColor(context).withValues(alpha: 0.3),
            ),
          ),
        ),
        const SizedBox(width: 20),
        // Labels
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: rings.asMap().entries.map((entry) {
              final index = entry.key;
              final ring = entry.value;
              final color = ringColors[index % ringColors.length];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ring.label,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppPallete.getTextSecondary(context),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${(ring.progress * 100).toInt()}%',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppPallete.getTextPrimary(context),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  double? _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

class _RingData {
  final String label;
  final double progress;
  _RingData({required this.label, required this.progress});
}

class _RingsPainter extends CustomPainter {
  final List<_RingData> rings;
  final List<Color> colors;
  final double ringThickness;
  final Color trackColor;

  _RingsPainter({
    required this.rings,
    required this.colors,
    required this.ringThickness,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2 - ringThickness;
    final gap = ringThickness + 4;

    for (int i = 0; i < rings.length && i < 5; i++) {
      final radius = maxRadius - (i * gap);
      if (radius <= 0) break;

      final ring = rings[i];
      final color = colors[i % colors.length];

      // Track (background)
      final trackPaint = Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringThickness
        ..strokeCap = StrokeCap.round;

      canvas.drawCircle(center, radius, trackPaint);

      // Progress arc
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringThickness
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * pi * ring.progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2, // Start from top
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter oldDelegate) {
    return oldDelegate.rings != rings;
  }
}
