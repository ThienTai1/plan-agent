import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_pallete.dart';

class NextEventWidget extends StatelessWidget {
  const NextEventWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppPallete.getSecondarySurface(context),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Up Next',
                style: TextStyle(
                  fontSize: AppFontSizes.bodyLarge, // Was 16 -> 18
                  fontWeight: FontWeight.bold,
                  color: AppPallete.getOnSurface(context),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppPallete.getPrimaryColor(
                    context,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '10:00 AM',
                  style: TextStyle(
                    fontSize: AppFontSizes.label, // Was 12 -> 14
                    fontWeight: FontWeight.bold,
                    color: AppPallete.getPrimaryColor(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: AppPallete.getPrimaryColor(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Design System Review',
                      style: TextStyle(
                        fontSize: AppFontSizes.subtitle, // Was 18 -> 20
                        fontWeight: FontWeight.bold,
                        color: AppPallete.getOnSurface(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Meeting with Design Team • Zoom',
                      style: TextStyle(
                        fontSize: AppFontSizes.label, // Was 13 -> 14
                        color: AppPallete.getTextSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
