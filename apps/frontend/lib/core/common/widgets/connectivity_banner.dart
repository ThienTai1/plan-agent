import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/common/providers/connectivity_provider.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ConnectivityBanner extends ConsumerWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityAsync = ref.watch(connectivityProvider);

    return connectivityAsync.when(
      data: (status) {
        if (status == ConnectivityStatus.online) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppPallete.warningColor.withValues(alpha: 0.9),
                AppPallete.warningColor.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                LucideIcons.wifi_off,
                color: Colors.white,
                size: 14,
              ),
              const SizedBox(width: 8),
              const Text(
                'Offline Mode • Viewing cached data',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ).animate().slideY(begin: -1, end: 0, duration: 400.ms, curve: Curves.easeOut);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
