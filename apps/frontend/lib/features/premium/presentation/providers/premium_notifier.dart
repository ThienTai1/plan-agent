import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/premium/presentation/providers/premium_providers.dart';

final premiumNotifierProvider = AsyncNotifierProvider<PremiumNotifier, void>(() {
  return PremiumNotifier();
});

class PremiumNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // Initial state is idle
  }

  Future<void> upgrade() async {
    state = const AsyncValue.loading();
    try {
      final premiumService = ref.read(premiumServiceProvider);
      await premiumService.buyPro();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
