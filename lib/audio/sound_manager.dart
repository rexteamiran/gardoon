/// مدیریت صدا — افکت‌های داخلی میزگرد (architecture.md بخش ۸)
///
/// صداها از GameEvent موتور مصرف می‌شوند: هر event نوع صدای خودش را دارد.
/// همیشه try/catch — نبود صدا هرگز نباید بازی را ببندد.
library;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/settings.dart';

enum GardoonSound {
  wheel('sounds/wheel.wav'), // چرخش گردونه — امضای گردون
  night('sounds/night.wav'),
  dawn('sounds/dawn.wav'),
  death('sounds/death.wav'),
  vote('sounds/vote.wav'),
  win('sounds/win.wav'),
  tap('sounds/tap.wav');

  const GardoonSound(this.assetPath);
  final String assetPath;
}

class SoundManager {
  SoundManager(this._ref);

  final Ref _ref;
  final AudioPlayer _player = AudioPlayer();

  Future<void> play(GardoonSound sound) async {
    if (!_ref.read(settingsProvider).soundOn) return;
    try {
      await _player.stop();
      await _player.play(AssetSource(sound.assetPath));
    } catch (_) {
      // صدا نشد — مهم نیست
    }
  }

  void dispose() {
    _player.dispose();
  }
}

final soundManagerProvider = Provider<SoundManager>((ref) {
  final manager = SoundManager(ref);
  ref.onDispose(manager.dispose);
  return manager;
});
