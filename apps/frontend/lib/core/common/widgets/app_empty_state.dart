import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_pallete.dart';

class AppEmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? ctaLabel;
  final VoidCallback? onCta;

  const AppEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.ctaLabel,
    this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    final ctaLabel = this.ctaLabel;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppPallete.getTextPrimary(context),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppPallete.getTextSecondary(context),
                ),
              ),
            ],
            if (ctaLabel != null && onCta != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onCta, child: Text(ctaLabel)),
            ],
          ],
        ),
      ),
    );
  }
}
