import 'package:flutter/material.dart';

class AppPallete {
  // Primary Colors - Notion Charcoal
  static const Color primaryColor = Color(0xFF37352F); // Notion Charcoal
  static const Color secondaryColor = Color(0xFF787774); // Notion Grey
  static const Color accentBg = Color(0xFFF1F1EF); // Notion Light Grey

  // Premium Gradients
  static const Color gradient1 = Color(0xFF37352F);
  static const Color gradient2 = Color(0xFF787774);
  static const Color gradient3 = Color(0xFF191919);

  // Background - Pristine White
  static const Color backgroundColor = Color(0xFFF9F9F8);
  static const Color surfaceColor = Colors.white;
  static const Color cardColor = Colors.white;
  static const Color cardOutline = Color(
    0xFFE2E2E0,
  ); // More defined Notion-style border

  // Tonal Surfaces (Neural Canvas)
  static const Color surfaceContainerLow = Color(0xFFF1F1EF);
  static const Color surfaceContainerHigh = Color(0xFFE9E9E7);

  // Text Colors
  static const Color textPrimary = Color(0xFF37352F);
  static const Color textSecondary = Color(0xFF787774);
  static const Color textMuted = Color(0xFF9B9A97);

  // Semantic Colors
  static const Color errorColor = Color(0xFFEB5757); // Notion Red
  static const Color successColor = Color(0xFF22C55E);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color infoColor = Color(0xFF37352F);

  // Border & Divider
  static const Color borderColor = Color(0xFFE2E2E0);
  static const Color dividerColor = Color(0xFFF1F1EF);

  // Calendar
  static const Color calendarTodayBg = borderColor;
  static const Color calendarSelectedBg = primaryColor;
  static const Color calendarSelectedText = Colors.white;

  // Legacy aliases
  static const Color greyColor = textSecondary;
  static const Color whiteColor = Colors.white;
  static const Color blackColor = textPrimary;
  static const Color transparentColor = Colors.transparent;

  // Dark Mode Colors - Charcoal & Neutral
  static const Color darkBackgroundColor = Color(0xFF191919);
  static const Color darkSurfaceColor = Color(0xFF2F2F2F);
  static const Color darkCardColor = Color(0xFF2F2F2F);
  static const Color darkBorderColor = Color(0xFF484848);
  static const Color darkGreyColor = Color(0xFF919191); // Neutral Grey
  static const Color darkWhiteColor = Color(0xFFE3E3E3);

  // Semantic Status Colors
  static const Color statusUrgentBg = Color(0xFFFEE2E2);
  static const Color statusUrgentText = Color(0xFF991B1B);
  static const Color statusInProgressBg = Color(0xFFFEF3C7);
  static const Color statusInProgressText = Color(0xFF92400E);
  static const Color statusCompletedBg = Color(0xFFDCFCE7);
  static const Color statusCompletedText = Color(0xFF166534);
  static const Color statusInReviewBg = Color(0xFFDBEAFE);
  static const Color statusInReviewText = Color(0xFF1E40AF);

  // App Configuration
  static const String appName = 'Planning Agent';
  static const double pagePadding = 24;
  static const double cardRadius = 8; // Notion-style sharper look
  static const double sectionRadius = 12;
  static const Color secondarySurface = Color(0xFFF1F1EF);

  // Soft Shadows - Key for minimalist design
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 20,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 24,
      offset: const Offset(0, 8),
      spreadRadius: -4,
    ),
  ];

  static List<BoxShadow> accentShadow = [];

  static const double minTableWidth = 920;
  static const double calendarCompactBreakpoint = 640;

  // Dynamic Theme Helpers
  static bool isDarkMode(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color getPrimaryColor(BuildContext context) {
    return isDarkMode(context) ? darkWhiteColor : primaryColor;
  }

  static Color getSecondarySurface(BuildContext context) {
    return isDarkMode(context) ? darkSurfaceColor : secondarySurface;
  }

  static Color getOnSurface(BuildContext context) {
    return isDarkMode(context) ? darkWhiteColor : textPrimary;
  }

  static Color getTextPrimary(BuildContext context) => getOnSurface(context);

  static Color getTextSecondary(BuildContext context) {
    return isDarkMode(context) ? darkGreyColor : textSecondary;
  }

  static Color getTextMuted(BuildContext context) {
    return isDarkMode(context)
        ? darkGreyColor.withValues(alpha: 1.0)
        : textMuted;
  }

  static Color getSurface(BuildContext context) {
    return isDarkMode(context) ? darkSurfaceColor : surfaceColor;
  }

  static Color getCardColor(BuildContext context) {
    return isDarkMode(context) ? darkCardColor : cardColor;
  }

  static Color getBackgroundColor(BuildContext context) {
    return isDarkMode(context) ? darkBackgroundColor : backgroundColor;
  }

  static Color getBorderColor(BuildContext context) {
    return isDarkMode(context) ? darkBorderColor : borderColor;
  }

  static Color getSurfaceContainerLow(BuildContext context) {
    return isDarkMode(context) ? const Color(0xFF1F1F1F) : surfaceContainerLow;
  }

  static List<BoxShadow> getDynamicSoftShadow(BuildContext context) {
    if (isDarkMode(context)) return []; // Usually no shadows in dark mode
    return softShadow;
  }

  static List<BoxShadow> getDynamicCardShadow(BuildContext context) {
    if (isDarkMode(context)) return [];
    return cardShadow;
  }

  static BoxDecoration getBackgroundDecoration(BuildContext context) {
    if (isDarkMode(context)) {
      return const BoxDecoration(color: darkBackgroundColor);
    }
    return const BoxDecoration(
      color: backgroundColor,
      image: DecorationImage(
        image: AssetImage('assets/images/app_bg.png'),
        fit: BoxFit.cover,
        opacity: 0.12, // Subtle enough not to distract
      ),
    );
  }

  static Color getErrorColor(BuildContext context) {
    return isDarkMode(context) ? Colors.redAccent : errorColor;
  }

  static Color getPriorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'urgent':
        return const Color(0xFFEF4444); // Red-500
      case 'high':
        return const Color(0xFFF97316); // Orange-500
      case 'medium':
        return const Color(0xFFEAB308); // Yellow-500
      case 'low':
        return const Color(0xFF3B82F6); // Blue-500
      default:
        return const Color(0xFF71717A); // Zinc-500 (Muted)
    }
  }

  static InputDecoration _buildInputDecoration(
    BuildContext context, {
    required String hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: getBorderColor(context).withValues(alpha: 0.5),
        width: 1,
      ),
    );

    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: getTextMuted(context), fontSize: 15),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: getTextSecondary(context), size: 20)
          : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: getCardColor(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: baseBorder,
      enabledBorder: baseBorder,
      focusedBorder: baseBorder.copyWith(
        borderSide: BorderSide(
          color: getPrimaryColor(context).withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      errorBorder: baseBorder.copyWith(
        borderSide: BorderSide(color: getErrorColor(context), width: 1),
      ),
    );
  }

  static InputDecoration getInputDecoration(
    BuildContext context, {
    required String hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return _buildInputDecoration(
      context,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
    );
  }
}

class AppFontSizes {
  // New Hierarchical Mapping (Min 12px)
  // Mapping based on user request:
  // 32px  → Main Heading
  // 28px  → Large Title
  // 24px  → Section title
  // 20px  → Subtitle / small title
  // 18px  → Large body / emphasis
  // 16px  → Default body
  // 14px  → Secondary text / label
  // 12px  → Caption / small hint

  /// Main Heading (32px)
  static const double heading = 32.0;

  /// Large Title (28px)
  static const double titleLarge = 28.0;

  /// Section title / Hero (24px)
  static const double sectionTitle = 24.0;
  static const double hero = 24.0;

  /// Subtitle / h1 (20px)
  static const double subtitle = 20.0;
  static const double h1 = 20.0;

  /// Large body / emphasis (18px)
  static const double bodyLarge = 18.0;

  /// Default body / h2 (16px)
  static const double bodyDefault = 16.0;
  static const double body = 16.0;
  static const double h2 = 16.0;

  /// Secondary text / label / h3 (14px)
  static const double label = 14.0;
  static const double h3 = 14.0;

  /// Caption / header (12px) - Minimal font size
  static const double caption = 12.0;
  static const double header = 12.0;

  // Legacy mappings (all min 12px)
  /// Was 11px -> now 12px
  static const double title = 12.0;

  /// Was 9px -> now 12px
  static const double metadata = 12.0;

  /// Was 8px -> now 12px
  static const double tiny = 12.0;
}
