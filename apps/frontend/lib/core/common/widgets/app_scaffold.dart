import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_pallete.dart';

class AppScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final EdgeInsetsGeometry padding;
  final bool safeAreaTop;
  final bool safeAreaBottom;
  final Color? backgroundColor;

  const AppScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
    this.safeAreaTop = true,
    this.safeAreaBottom = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? AppPallete.getBackgroundColor(context),
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: SafeArea(
        top: safeAreaTop,
        bottom: safeAreaBottom,
        child: Padding(padding: padding, child: body),
      ),
    );
  }
}
