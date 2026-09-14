/// پالت رنگی گردون — طبق design.md بخش ۲
///
/// قانون: هرگز رنگ خام در ویجت — همه از همین کلاس.
library;

import 'package:flutter/material.dart';

/// رنگ‌های مشترک مافیا/شهر — در هر دو تم ثابت‌اند
class BrandColors {
  static const mafia = Color(0xFFC62828);
  static const city = Color(0xFF2E7D32);
  static const info = Color(0xFF00838F);
  static const cult = Color(0xFF6A1B9A);
  static const gold = Color(0xFFF0B429);
}

/// رنگ‌های تم تاریک (پیش‌فرض)
class DarkPalette {
  static const bg = Color(0xFF0D1321); // سرمه‌ای عمیق
  static const surface = Color(0xFF1B2A4A); // کارت‌ها
  static const surface3 = Color(0xFF24345C); // شیت‌ها
  static const primary = Color(0xFFF0B429); // طلایی کهربایی
  static const text = Color(0xFFF5EFE6); // سفید گرم
  static const subtext = Color(0xFF8B9BB4); // خاکستری آبی
}

/// رنگ‌های تم روشن
class LightPalette {
  static const bg = Color(0xFFF7F3EB); // کرم روشن
  static const surface = Color(0xFFFFFFFF);
  static const surface3 = Color(0xFFEFE7D8);
  static const primary = Color(0xFFC8871A); // طلایی تیره
  static const text = Color(0xFF2B2118); // قهوه‌ای تیره
  static const subtext = Color(0xFF7A6A55);
}

/// دسترسی یکنواخت به رنگ‌های تم جاری
class AppColors {
  const AppColors._(this.brightness);

  final Brightness brightness;

  static const dark = AppColors._(Brightness.dark);
  static const light = AppColors._(Brightness.light);

  static AppColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  Color get bg => brightness == Brightness.dark ? DarkPalette.bg : LightPalette.bg;
  Color get surface =>
      brightness == Brightness.dark ? DarkPalette.surface : LightPalette.surface;
  Color get surface3 =>
      brightness == Brightness.dark ? DarkPalette.surface3 : LightPalette.surface3;
  Color get primary =>
      brightness == Brightness.dark ? DarkPalette.primary : LightPalette.primary;
  Color get text =>
      brightness == Brightness.dark ? DarkPalette.text : LightPalette.text;
  Color get subtext =>
      brightness == Brightness.dark ? DarkPalette.subtext : LightPalette.subtext;
}
