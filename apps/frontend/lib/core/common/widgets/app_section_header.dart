import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:google_fonts/google_fonts.dart';

class AppSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final actionLabel = this.actionLabel;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.jetBrainsMono(
              fontSize: AppFontSizes.bodyLarge,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: AppPallete.getTextPrimary(context),
            ),
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel,
              style: GoogleFonts.jetBrainsMono(
                color: AppPallete.getTextSecondary(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
