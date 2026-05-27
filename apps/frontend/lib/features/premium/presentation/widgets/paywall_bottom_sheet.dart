import 'package:flutter/material.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

class PaywallBottomSheet extends StatelessWidget {
  const PaywallBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const PaywallBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const PaywallView();
  }
}
