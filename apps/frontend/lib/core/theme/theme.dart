import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static OutlineInputBorder _border([Color? color]) =>
      OutlineInputBorder(
        borderSide: BorderSide(
          color: color ?? AppPallete.borderColor.withValues(alpha: 0.1), 
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(8),
      );

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: GoogleFonts.jetBrainsMono().fontFamily,
    scaffoldBackgroundColor: AppPallete.backgroundColor,

    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.jetBrainsMono(
        color: AppPallete.textPrimary,
        fontSize: AppFontSizes.subtitle,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: const IconThemeData(color: AppPallete.textPrimary, size: 24),
    ),

    colorScheme: const ColorScheme.light(
      primary: AppPallete.primaryColor,
      secondary: AppPallete.secondaryColor,
      surface: AppPallete.surfaceColor,
      error: AppPallete.errorColor,
      onPrimary: Colors.white,
      onSurface: AppPallete.textPrimary,
    ),

    cardTheme: CardThemeData(
      color: AppPallete.cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppPallete.cardOutline, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),

    inputDecorationTheme: InputDecorationTheme(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      filled: true,
      fillColor: AppPallete.surfaceColor,
      enabledBorder: _border(),
      focusedBorder: _border(AppPallete.primaryColor),
      errorBorder: _border(AppPallete.errorColor),
      focusedErrorBorder: _border(AppPallete.errorColor),
      hintStyle: GoogleFonts.jetBrainsMono(
        color: AppPallete.textMuted,
        fontSize: AppFontSizes.label,
      ),
      prefixIconColor: AppPallete.textSecondary,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppPallete.primaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
        textStyle: GoogleFonts.jetBrainsMono(
          fontSize: AppFontSizes.body,
          fontWeight: FontWeight.w700,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppPallete.borderColor),
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: AppPallete.surfaceColor,
        foregroundColor: AppPallete.textPrimary,
        elevation: 0,
        textStyle: GoogleFonts.jetBrainsMono(
          fontSize: AppFontSizes.label + 1,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),

    textTheme: TextTheme(
      displayLarge: GoogleFonts.jetBrainsMono(
        fontSize: AppFontSizes.heading,
        fontWeight: FontWeight.w800,
        color: AppPallete.textPrimary,
      ),
      bodyLarge: GoogleFonts.jetBrainsMono(
        fontSize: AppFontSizes.bodyDefault,
        fontWeight: FontWeight.w500,
        color: AppPallete.textPrimary,
      ),
      bodyMedium: GoogleFonts.jetBrainsMono(
        fontSize: AppFontSizes.bodyDefault,
        fontWeight: FontWeight.w500,
        color: AppPallete.textPrimary,
      ),
      bodySmall: GoogleFonts.jetBrainsMono(
        fontSize: AppFontSizes.caption,
        fontWeight: FontWeight.w500,
        color: AppPallete.textSecondary,
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: AppPallete.dividerColor,
      thickness: 1,
      space: 1,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: GoogleFonts.jetBrainsMono().fontFamily,
    scaffoldBackgroundColor: AppPallete.darkBackgroundColor,

    appBarTheme: AppBarTheme(
      backgroundColor: AppPallete.darkBackgroundColor,
      surfaceTintColor: AppPallete.darkBackgroundColor,
      elevation: 0,
      titleTextStyle: GoogleFonts.jetBrainsMono(
        color: AppPallete.darkWhiteColor,
        fontSize: AppFontSizes.subtitle,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: const IconThemeData(color: AppPallete.darkWhiteColor, size: 24),
    ),

    colorScheme: const ColorScheme.dark(
      primary: AppPallete.darkWhiteColor,
      secondary: AppPallete.darkGreyColor,
      surface: AppPallete.darkSurfaceColor,
      error: AppPallete.errorColor,
      onPrimary: AppPallete.darkBackgroundColor,
      onSurface: AppPallete.darkWhiteColor,
    ),

    cardTheme: CardThemeData(
      color: AppPallete.darkCardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppPallete.darkBorderColor, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),

    inputDecorationTheme: InputDecorationTheme(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      filled: true,
      fillColor: AppPallete.darkSurfaceColor,
      enabledBorder: _border(AppPallete.darkBorderColor),
      focusedBorder: _border(AppPallete.darkWhiteColor),
      errorBorder: _border(AppPallete.errorColor),
      focusedErrorBorder: _border(AppPallete.errorColor),
      hintStyle: GoogleFonts.jetBrainsMono(
        color: AppPallete.darkGreyColor,
        fontSize: AppFontSizes.label,
      ),
      prefixIconColor: AppPallete.darkGreyColor,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppPallete.darkWhiteColor,
        foregroundColor: AppPallete.darkBackgroundColor,
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
        textStyle: GoogleFonts.jetBrainsMono(
          fontSize: AppFontSizes.label + 1,
          fontWeight: FontWeight.w700,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),

    textTheme: TextTheme(
      displayLarge: GoogleFonts.jetBrainsMono(
        fontSize: AppFontSizes.heading,
        fontWeight: FontWeight.w800,
        color: AppPallete.darkWhiteColor,
      ),
      bodyLarge: GoogleFonts.jetBrainsMono(
        fontSize: AppFontSizes.bodyDefault,
        fontWeight: FontWeight.w500,
        color: AppPallete.darkWhiteColor,
      ),
      bodyMedium: GoogleFonts.jetBrainsMono(
        fontSize: AppFontSizes.bodyDefault,
        fontWeight: FontWeight.w500,
        color: AppPallete.darkWhiteColor,
      ),
      bodySmall: GoogleFonts.jetBrainsMono(
        fontSize: AppFontSizes.caption,
        fontWeight: FontWeight.w500,
        color: AppPallete.darkGreyColor,
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: AppPallete.darkBorderColor,
      thickness: 1,
      space: 1,
    ),
  );
}

