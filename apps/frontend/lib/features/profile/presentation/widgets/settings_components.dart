import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_pallete.dart';

class SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsGroup({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 8, top: 24),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppPallete.getTextSecondary(context),
                letterSpacing: 1.2,
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: AppPallete.getCardColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppPallete.getBorderColor(context)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool isDestructive;

  const SettingTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDestructive
                      ? Colors.red.withValues(alpha: 0.1)
                      : AppPallete.getSecondarySurface(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isDestructive
                      ? Colors.red
                      : AppPallete.getTextPrimary(context),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDestructive
                        ? Colors.red
                        : AppPallete.getTextPrimary(context),
                  ),
                ),
              ),
              if (trailing != null)
                trailing!
              else
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppPallete.getTextMuted(context),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
