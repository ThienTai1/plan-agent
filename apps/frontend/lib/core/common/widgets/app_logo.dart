import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_pallete.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final Color? color;

  const AppLogo({
    super.key,
    this.size = 48,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color ?? AppPallete.getPrimaryColor(context),
        borderRadius: BorderRadius.circular(size * 0.25),
        boxShadow: AppPallete.getDynamicSoftShadow(context),
      ),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.25),
          child: Image.asset(
            'assets/images/logo.png',
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              // Fallback if logo.png is not found
              return Icon(
                Icons.auto_awesome_mosaic_rounded,
                color: Colors.white,
                size: size * 0.6,
              );
            },
          ),
        ),
      ),
    );
  }
}
