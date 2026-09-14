/// تنظیمات اپ — تم، صدا، وضعیت طلایی (shared_preferences)
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/premium_gate.dart';

enum GardoonThemeMode { system, light, dark }

class SettingsState {
  const SettingsState({
    this.themeMode = GardoonThemeMode.dark,
    this.soundOn = true,
    this.premium = const PremiumState(),
  });

  final GardoonThemeMode themeMode;
  final bool soundOn;
  final PremiumState premium;

  SettingsState copyWith({
    GardoonThemeMode? themeMode,
    bool? soundOn,
    PremiumState? premium,
  }) =>
      SettingsState(
        themeMode: themeMode ?? this.themeMode,
        soundOn: soundOn ?? this.soundOn,
        premium: premium ?? this.premium,
      );
}

class SettingsController extends StateNotifier<SettingsState> {
  SettingsController() : super(const SettingsState());

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    final modeIdx = sp.getInt('themeMode') ?? GardoonThemeMode.dark.index;
    final goldenIso = sp.getString('goldenUntil');
    final premium = PremiumState(
      goldenUntil: goldenIso == null ? null : DateTime.tryParse(goldenIso),
    );
    state = SettingsState(
      themeMode: GardoonThemeMode.values[modeIdx.clamp(0, 2)],
      soundOn: sp.getBool('soundOn') ?? true,
      premium: premium,
    );
    // گردن‌بند قفل — نقطه مرکزی چک اشتراک
    PremiumGate.update(premium);
  }

  Future<void> setThemeMode(GardoonThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final sp = await SharedPreferences.getInstance();
    await sp.setInt('themeMode', mode.index);
  }

  Future<void> setSound(bool on) async {
    state = state.copyWith(soundOn: on);
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('soundOn', on);
  }

  /// نسخه ۱: فعال‌سازی محلی تا اتصال پرداخت کافه بازار
  Future<void> activateGoldenTrial() async {
    final until = DateTime.now().add(const Duration(days: 365));
    state = state.copyWith(premium: PremiumState(goldenUntil: until));
    PremiumGate.update(state.premium);
    final sp = await SharedPreferences.getInstance();
    await sp.setString('goldenUntil', until.toIso8601String());
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsController, SettingsState>((ref) {
  final c = SettingsController();
  c.load();
  return c;
});
