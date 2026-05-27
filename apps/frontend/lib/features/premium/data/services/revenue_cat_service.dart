import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/secrets/app_secrets.dart';

class RevenueCatService {
  static const _apiKey = AppSecrets.revenueCatApiKey;
  static const entitlementId = 'Levigo Pro';

  RevenueCatService();

  /// Initializes the RevenueCat SDK with the specific User ID from Supabase.
  Future<void> init(String appUserId) async {
    try {
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.error);

      PurchasesConfiguration configuration = PurchasesConfiguration(_apiKey)
        ..appUserID = appUserId;
      
      await Purchases.configure(configuration);
      debugPrint('[RevenueCat] SDK Configured for user: $appUserId');
    } catch (e) {
      debugPrint('[RevenueCat] Initialization Error: $e');
    }
  }

  /// Checks if the user has the 'Levigo Pro' entitlement active.
  Future<bool> isPro() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
    } catch (e) {
      debugPrint('[RevenueCat] Error checking status: $e');
      return false;
    }
  }

  /// Fetches the current offerings (Monthly, Yearly, Lifetime).
  Future<Offerings?> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint('[RevenueCat] Error fetching offerings: $e');
      return null;
    }
  }

  /// Performs a purchase for a specific package.
  Future<bool> purchasePackage(Package package) async {
    try {
      final result = await Purchases.purchasePackage(package);
      return result.customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
    } catch (e) {
      debugPrint('[RevenueCat] Purchase Error: $e');
      return false;
    }
  }

  /// Restores previous purchases.
  Future<bool> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      return customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
    } catch (e) {
      debugPrint('[RevenueCat] Restore Error: $e');
      return false;
    }
  }
}

/// Provider for the RevenueCat Service
final revenueCatServiceProvider = Provider<RevenueCatService>((ref) {
  return RevenueCatService();
});

/// Reactive provider for CustomerInfo status
final customerInfoProvider = StreamProvider<CustomerInfo>((ref) {
  final controller = StreamController<CustomerInfo>();
  
  // Initial fetch
  Purchases.getCustomerInfo().then((info) {
    if (!controller.isClosed) controller.add(info);
  }).catchError((_) {});

  // Listen for updates
  Purchases.addCustomerInfoUpdateListener((customerInfo) {
    if (!controller.isClosed) controller.add(customerInfo);
  });

  ref.onDispose(() {
    controller.close();
  });

  return controller.stream;
});

/// Simple provider to check if the user is Pro based on the stream
final isProProvider = Provider<bool>((ref) {
  final customerInfoAsync = ref.watch(customerInfoProvider);
  return customerInfoAsync.when(
    data: (info) => info.entitlements.all[RevenueCatService.entitlementId]?.isActive ?? false,
    loading: () => false,
    error: (_, __) => false,
  );
});
