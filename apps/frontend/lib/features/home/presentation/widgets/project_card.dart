import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_pallete.dart';

class ProjectCard extends StatelessWidget {
  final String title;
  final int completedTasks;
  final int totalTasks;
  final Color color;
  final String? icon;

  const ProjectCard({
    super.key,
    required this.title,
    required this.completedTasks,
    required this.totalTasks,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppPallete.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPallete.getBorderColor(context).withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  icon ?? '🎯',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Colors.white, Colors.white.withValues(alpha: 0.05)],
                stops: const [0.8, 1.0],
              ).createShader(bounds);
            },
            blendMode: BlendMode.dstIn,
            child: SizedBox(
              width: double.infinity,
              child: Text(
                title,
                style: TextStyle(
                  fontSize: AppFontSizes.bodyDefault, // Was title (12) -> 16
                  fontWeight: FontWeight.w700,
                  color: AppPallete.getTextPrimary(context),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(Icons.wb_sunny_outlined, size: 12, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '$completedTasks/$totalTasks completed',
                  style: TextStyle(
                    fontSize: AppFontSizes.metadata,
                    fontWeight: FontWeight.w600,
                    color: AppPallete.getTextMuted(context),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
