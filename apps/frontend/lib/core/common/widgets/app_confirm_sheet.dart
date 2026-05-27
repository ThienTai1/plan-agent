import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_pallete.dart';

class AppConfirmSheet extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;
  final Color? confirmColor;

  const AppConfirmSheet({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    required this.onConfirm,
    this.confirmColor,
  });

  /// Shows a premium confirmation bottom sheet.
  /// Returns [true] if confirmed, [false] or [null] if cancelled.
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    Color? confirmColor,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AppConfirmSheet(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        confirmColor: confirmColor,
        onConfirm: () => Navigator.pop(context, true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppPallete.getBackgroundColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, bottomPadding + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppPallete.getBorderColor(context).withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 32),
          
          // Icon for emphasis if it's a destructive action
          if (confirmColor == AppPallete.errorColor || confirmColor == Colors.red)
             Container(
               margin: const EdgeInsets.only(bottom: 24),
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: AppPallete.errorColor.withValues(alpha: 0.1),
                 shape: BoxShape.circle,
               ),
               child: const Icon(Icons.warning_amber_rounded, color: AppPallete.errorColor, size: 32),
             ),

          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppPallete.getTextPrimary(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 15,
              color: AppPallete.getTextSecondary(context),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _SheetButton(
                  label: cancelLabel,
                  onPressed: () => Navigator.pop(context, false),
                  isSecondary: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SheetButton(
                  label: confirmLabel,
                  onPressed: onConfirm,
                  color: confirmColor ?? AppPallete.getPrimaryColor(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color? color;
  final bool isSecondary;

  const _SheetButton({
    required this.label,
    required this.onPressed,
    this.color,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSecondary 
            ? AppPallete.getSurfaceContainerLow(context) 
            : color,
          foregroundColor: isSecondary 
            ? AppPallete.getTextPrimary(context) 
            : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
