import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_pallete.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool outlined;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.outlined = true,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppPallete.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: outlined
            ? Border.all(
                color: AppPallete.getBorderColor(
                  context,
                ).withValues(alpha: 0.8),
              )
            : null,
        boxShadow: AppPallete.getDynamicSoftShadow(context),
      ),
      child: child,
    );

    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: card,
    );
  }
}
