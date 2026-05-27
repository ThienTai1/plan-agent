import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_pallete.dart';

class FollowUpWidget extends StatelessWidget {
  final List<String> followUps;
  final Function(String) onSuggestionTap;

  const FollowUpWidget({
    super.key,
    required this.followUps,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    if (followUps.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suggested for you:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppPallete.getTextSecondary(context),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: followUps.map((suggestion) {
              return InkWell(
                onTap: () => onSuggestionTap(suggestion),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppPallete.getPrimaryColor(
                      context,
                    ).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppPallete.getPrimaryColor(
                        context,
                      ).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    suggestion,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppPallete.getPrimaryColor(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
