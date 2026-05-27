import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:google_fonts/google_fonts.dart';

/// Big number KPI display — shows metrics with trend indicators.
///
/// Expected data format:
///   series[i].label = "Tasks Done"
///   series[i].data[0] = {x: "value", y: 12}  ← the main number
///   series[i].data[1] = {x: "trend", y: 20}  ← percentage change (optional)
///   config.options = {layout: "row"}
class StatCardView extends StatelessWidget {
  final Map<String, dynamic> data;

  const StatCardView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final series = (data['series'] as List?) ?? [];
    if (series.isEmpty) return const Center(child: Text('No data'));

    return Row(
      children: series.asMap().entries.map((entry) {
        final s = entry.value as Map<String, dynamic>;
        final label = s['label']?.toString() ?? '';
        final points = (s['data'] as List?) ?? [];

        // Extract value and trend from data points
        double value = 0;
        double trend = 0;
        for (final p in points) {
          final point = p as Map<String, dynamic>;
          final key = point['x']?.toString() ?? '';
          if (key == 'value') value = (point['y'] as num? ?? 0).toDouble();
          if (key == 'trend') trend = (point['y'] as num? ?? 0).toDouble();
        }

        final isPositive = trend >= 0;
        final trendColor = trend == 0
            ? AppPallete.getTextMuted(context)
            : isPositive
                ? const Color(0xFF22C55E)
                : const Color(0xFFEF4444);

        return Expanded(
          child: Column(
            children: [
              Text(
                _formatValue(value),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppPallete.getTextPrimary(context),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label.toUpperCase(),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: AppPallete.getTextMuted(context),
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              if (trend != 0) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? LucideIcons.trending_up : LucideIcons.trending_down,
                      size: 10,
                      color: trendColor,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${isPositive ? '+' : ''}${trend.toInt()}%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: trendColor,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatValue(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }
}
