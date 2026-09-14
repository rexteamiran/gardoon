/// اعداد ثابت اپ — طبق agents.md بخش ۳ (core/constants.dart)
library;

/// وزن بلوک‌ها برای گیج ترازو — architecture.md بخش ۴
const Map<String, int> kBlockWeights = {
  'attack': 3,
  'save': 2,
  'inspect': 2,
  'protect': 2,
};

/// آیکون‌های داخلی نقش‌ها (builtin:) → ایموجی
const Map<String, String> kBuiltinIcons = {
  'fedora': '🎩',
  'dove': '🕊️',
  'candle': '🕯️',
  'cross': '✚',
  'person': '🧍',
  'magnifier': '🔍',
  'wolf': '🐺',
  'shield': '🛡️',
  'gun': '🔫',
  'moon': '🌙',
  'sun': '☀️',
  'skull': '💀',
  'heart': '❤️',
  'star': '⭐',
  'knife': '🔪',
  'eye': '👁️',
  'clover': '🍀',
  'fire': '🔥',
};

String iconGlyph(String iconRef, {String fallback = '🧍'}) {
  final name = iconRef.replaceFirst('builtin:', '').replaceFirst('asset:', '');
  return kBuiltinIcons[name] ?? fallback;
}

/// آیکون‌های فاز
const Map<String, String> kPhaseIcons = {
  'night': '🌙',
  'dawn': '🌅',
  'day': '☀️',
  'vote': '🗳️',
  'custom': '⏱️',
};
