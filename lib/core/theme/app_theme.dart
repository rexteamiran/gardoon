/// ساخت ThemeData تاریک و روشن — طبق design.md بخش ۳
library;

import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static const fontFamily = 'Vazirmatn';

  static ThemeData dark() => _build(Brightness.dark);
  static ThemeData light() => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: colors.primary,
      onPrimary: isDark ? DarkPalette.bg : Colors.white,
      secondary: isDark ? DarkPalette.surface3 : LightPalette.surface3,
      onSecondary: colors.text,
      surface: colors.surface,
      onSurface: colors.text,
      error: BrandColors.mafia,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.bg,
      textTheme: TextTheme(
        displaySmall: TextStyle(
            fontSize: 24, fontWeight: FontWeight.w700, color: colors.text),
        headlineMedium: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w700, color: colors.text),
        bodyLarge: TextStyle(fontSize: 16, color: colors.text),
        bodyMedium: TextStyle(
            fontSize: 14, height: 1.7, color: colors.text),
        bodySmall: TextStyle(
            fontSize: 13, height: 1.6, color: colors.subtext),
        labelLarge: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w500, color: colors.text),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: colors.text,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: isDark ? DarkPalette.bg : Colors.white,
          textStyle: const TextStyle(
              fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w600),
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.text,
          side: BorderSide(color: colors.subtext.withValues(alpha: 0.4)),
          textStyle: const TextStyle(
              fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w500),
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface3,
        hintStyle: TextStyle(color: colors.subtext),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surface3,
        labelStyle: TextStyle(color: colors.text, fontFamily: fontFamily),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerColor: colors.subtext.withValues(alpha: 0.2),
    );
  }
}
