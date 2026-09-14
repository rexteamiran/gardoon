/// گردن‌بند قفل فیچرها — طبق agents.md بخش ۶
///
/// هیچ صفحه‌ای مستقیماً اشتراک را چک نمی‌کند — فقط PremiumGate.
library;

/// فیچرهای طلایی
enum PremiumFeature {
  builderLevel2,
  builderLevel3,
  builderLevel4,
  premiumScenarios,
  noAds,
}

/// وضعیت اشتراک — از data/settings بارگذاری و اینجا مصرف می‌شود
class PremiumState {
  const PremiumState({this.goldenUntil});

  /// تاریخ انقضای اشتراک طلایی — null = رایگان
  final DateTime? goldenUntil;

  PremiumState copyWith({DateTime? goldenUntil, bool clear = false}) =>
      PremiumState(
        goldenUntil: clear ? null : (goldenUntil ?? this.goldenUntil),
      );

  bool get isGolden {
    final until = goldenUntil;
    if (until == null) return false;
    return until.isAfter(DateTime.now());
  }
}

class PremiumGate {
  PremiumGate._();

  static PremiumState _state = const PremiumState();

  /// فقط data/settings این را ست می‌کند
  static void update(PremiumState state) => _state = state;

  static bool get isGolden => _state.isGolden;

  /// آیا کاربر به فیچر دسترسی دارد؟
  static bool canUse(PremiumFeature feature) {
    if (_state.isGolden) return true;
    // نسخه ۱: سناریوساز سطح ۱ و سناریوهای رایگان برای همه باز است
    switch (feature) {
      case PremiumFeature.builderLevel2:
      case PremiumFeature.builderLevel3:
      case PremiumFeature.builderLevel4:
      case PremiumFeature.premiumScenarios:
      case PremiumFeature.noAds:
        return false;
    }
  }
}
