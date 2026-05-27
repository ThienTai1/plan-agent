import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:google_fonts/google_fonts.dart';

/// GitHub Contribution-style Heatmap View.
/// Renders a grid of colored squares representing activity levels.
///
/// Expected data format:
///   series[0].data = [{x: "w1_mon", y: 3}, {x: "w1_tue", y: 0}, ...]
///   config.options = {columns: 7, rows: 4, color_scale: "mono"}
class HeatmapView extends StatelessWidget {
  final Map<String, dynamic> data;

  const HeatmapView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final config = data['config'] as Map<String, dynamic>? ?? {};
    final options = config['options'] as Map<String, dynamic>? ?? {};
    final series = (data['series'] as List?) ?? [];
    if (series.isEmpty) return const Center(child: Text('No data'));

    final firstSeries = series[0] as Map<String, dynamic>;
    final points = (firstSeries['data'] as List?) ?? [];

    final columns = _parseInt(options['columns']) ?? 7;
    final rows = _parseInt(options['rows']) ?? 4;
    final colorScale = options['color_scale']?.toString() ?? 'mono';

    // Find max value for normalization
    double maxVal = 1;
    for (final p in points) {
      final v = ((p as Map<String, dynamic>)['y'] as num? ?? 0).toDouble();
      if (v > maxVal) maxVal = v;
    }

    final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day labels
        Row(
          children: List.generate(columns, (i) {
            return Expanded(
              child: Center(
                child: Text(
                  i < dayLabels.length ? dayLabels[i] : '',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppPallete.getTextMuted(context),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),

        // Grid
        ...List.generate(rows, (row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              children: List.generate(columns, (col) {
                final index = row * columns + col;
                final level = index < points.length
                    ? ((points[index] as Map<String, dynamic>)['y'] as num? ?? 0).toDouble()
                    : 0.0;
                final normalized = maxVal > 0 ? (level / maxVal).clamp(0.0, 1.0) : 0.0;

                return Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      margin: const EdgeInsets.all(1.5),
                      decoration: BoxDecoration(
                        color: _getColor(normalized, colorScale, context),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),

        const SizedBox(height: 8),

        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Less',
              style: TextStyle(fontSize: 9, color: AppPallete.getTextMuted(context)),
            ),
            const SizedBox(width: 4),
            ...List.generate(5, (i) {
              return Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: _getColor(i / 4, colorScale, context),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
            const SizedBox(width: 4),
            Text(
              'More',
              style: TextStyle(fontSize: 9, color: AppPallete.getTextMuted(context)),
            ),
          ],
        ),
      ],
    );
  }

  Color _getColor(double normalized, String scale, BuildContext context) {
    final isDark = AppPallete.isDarkMode(context);
    switch (scale) {
      case 'green':
        final base = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFEBEBEB);
        final peak = const Color(0xFF22C55E);
        return Color.lerp(base, peak, normalized)!;
      case 'blue':
        final base = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFEBEBEB);
        final peak = const Color(0xFF3B82F6);
        return Color.lerp(base, peak, normalized)!;
      default: // mono
        if (isDark) {
          return Color.lerp(const Color(0xFF2A2A2A), const Color(0xFFCCCCCC), normalized)!;
        } else {
          return Color.lerp(const Color(0xFFEBEBEB), const Color(0xFF555555), normalized)!;
        }
    }
  }

  int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
