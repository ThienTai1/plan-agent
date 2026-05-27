import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/premium/data/services/revenue_cat_service.dart';
import 'package:frontend/features/auth/presentation/providers/auth_notifier.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

final premiumServiceProvider = Provider<PremiumService>((ref) {
  return PremiumService(ref);
});

class PremiumService {
  final Ref ref;

  PremiumService(this.ref);

  RevenueCatService get _rc => ref.read(revenueCatServiceProvider);

  /// Buy a specific package using RevenueCat
  Future<bool> buyPackage(Package package) async {
    final success = await _rc.purchasePackage(package);
    if (success) {
      // Refresh local user state if needed, though isProProvider watches the stream
      await ref.read(authNotifierProvider.notifier).build();
    }
    return success;
  }

  /// Restore purchases
  Future<bool> restorePurchases() async {
    final success = await _rc.restorePurchases();
    if (success) {
      await ref.read(authNotifierProvider.notifier).build();
    }
    return success;
  }

  /// Check for active offerings
  Future<Offerings?> getOfferings() async {
    return await _rc.getOfferings();
  }

  /// Convenience method for legacy code (defaults to monthly)
  Future<void> buyPro() async {
    final offerings = await getOfferings();
    if (offerings?.current?.monthly != null) {
      await buyPackage(offerings!.current!.monthly!);
    }
  }
}
