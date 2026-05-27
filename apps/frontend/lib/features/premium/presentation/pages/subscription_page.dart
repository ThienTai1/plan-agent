import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:frontend/core/common/providers/app_user_notifier.dart';
import 'package:frontend/features/premium/presentation/providers/premium_notifier.dart';

import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

class SubscriptionPage extends ConsumerWidget {
  static const String routeName = '/subscription';
  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appUserNotifierProvider);
    final isPro = user?.isPro ?? false;
    
    // Watch premium state to show loading status
    final premiumState = ref.watch(premiumNotifierProvider);

    // Listen for errors and show snackbar
    ref.listen(premiumNotifierProvider, (previous, next) {
      next.maybeWhen(
        error: (error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $error'),
              backgroundColor: AppPallete.errorColor,
            ),
          );
        },
        orElse: () {},
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Plan'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppPallete.getTextPrimary(context),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          DecoratedBox(
            decoration: AppPallete.getBackgroundDecoration(context),
            child: SizedBox.expand(
              child: SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upgrade to Pro',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppPallete.getTextPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Unlock the full power of AI-driven strategy.',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppPallete.getTextSecondary(context),
                          ),
                        ),
                        _buildPlanCard(
                          context,
                          title: 'Pro Plan',
                          price: '\$6.99 / month',
                          features: [
                            'Unlimited Goals & Strategies',
                            '500 AI Messages per Month',
                            'Real-time Strategic Dashboard',
                            'Intelligent Progress Reports',
                            'Large Attachments (up to 50MB)',
                          ],
                          isCurrent: isPro,
                          isLoading: premiumState.isLoading,
                          onTap: (isPro || premiumState.isLoading) 
                              ? null 
                              : () => ref.read(premiumNotifierProvider.notifier).upgrade(),
                        ),
                        const SizedBox(height: 48),
                        if (isPro)
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  'You are currently using the Pro plan!',
                                  style: TextStyle(
                                    color: AppPallete.getPrimaryColor(context), 
                                    fontWeight: FontWeight.bold
                                  ),
                                ),
                                const SizedBox(height: 24),
                                OutlinedButton.icon(
                                  onPressed: () => _showCustomerCenter(context),
                                  icon: const Icon(LucideIcons.user_cog, size: 18),
                                  label: const Text('Manage Subscription'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    side: BorderSide(color: AppPallete.getPrimaryColor(context)),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  'Secure payment via Google Play',
                                  style: TextStyle(
                                    color: AppPallete.getTextMuted(context), 
                                    fontSize: 12
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () => _showPaywall(context),
                                  icon: const Icon(LucideIcons.sparkles, size: 18),
                                  label: const Text('View Pro Offerings'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Global loading overlay
          if (premiumState.isLoading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  void _showPaywall(BuildContext context) {
    RevenueCatUI.presentPaywall();
  }

  void _showCustomerCenter(BuildContext context) {
    RevenueCatUI.presentCustomerCenter();
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required String title,
    required String price,
    required List<String> features,
    required bool isCurrent,
    required bool isLoading,
    VoidCallback? onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppPallete.getCardColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isCurrent 
              ? AppPallete.getPrimaryColor(context) 
              : AppPallete.getBorderColor(context),
          width: isCurrent ? 2 : 1,
        ),
        boxShadow: isCurrent ? AppPallete.getDynamicCardShadow(context) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppPallete.getTextPrimary(context),
                ),
              ),
              if (isCurrent)
                Icon(Icons.check_circle, color: AppPallete.getPrimaryColor(context)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            price,
            style: TextStyle(
              fontSize: 22,
              color: AppPallete.getPrimaryColor(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      LucideIcons.circle_check, 
                      color: AppPallete.getPrimaryColor(context).withValues(alpha: 0.7), 
                      size: 18
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        f,
                        style: TextStyle(
                          color: AppPallete.getTextPrimary(context),
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: isCurrent 
                    ? AppPallete.getBorderColor(context) 
                    : AppPallete.getPrimaryColor(context),
                foregroundColor: isCurrent 
                    ? AppPallete.getTextSecondary(context) 
                    : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: isCurrent ? 0 : 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isLoading 
                    ? 'Processing...' 
                    : (isCurrent ? 'Current Plan' : 'Upgrade Now'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
