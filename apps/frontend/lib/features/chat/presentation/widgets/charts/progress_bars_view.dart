import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:google_fonts/google_fonts.dart';

/// Multiple horizontal progress bars for goal tracking.
///
/// Expected data format:
///   series[i].label = "Goal Name"
///   series[i].data[0] = {x: "on_track", y: 0.72}
///     x = status ("on_track" | "behind" | "at_risk")
///     y = progress 0.0–1.0
class ProgressBarsView extends StatelessWidget {
  final Map<String, dynamic> data;

  const ProgressBarsView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final series = (data['series'] as List?) ?? [];
    if (series.isEmpty) return const Center(child: Text('No data'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: series.map((s) {
        final sMap = s as Map<String, dynamic>;
        final label = sMap['label']?.toString() ?? '';
        final points = (sMap['data'] as List?) ?? [];

        double progress = 0;
        String status = 'on_track';
        if (points.isNotEmpty) {
          final p = points[0] as Map<String, dynamic>;
          progress = (p['y'] as num? ?? 0).toDouble().clamp(0.0, 1.0);
          status = p['x']?.toString() ?? 'on_track';
        }

        final statusColor = _getStatusColor(status);

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppPallete.getTextPrimary(context),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _statusLabel(status),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppPallete.getBorderColor(context).withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'behind':
        return const Color(0xFFF59E0B);
      case 'at_risk':
        return const Color(0xFFEF4444);
      case 'on_track':
      default:
        return const Color(0xFF22C55E);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'behind':
        return 'BEHIND';
      case 'at_risk':
        return 'AT RISK';
      case 'on_track':
      default:
        return 'ON TRACK';
    }
  }
}
