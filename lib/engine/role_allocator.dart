/// نقش‌کشه — توزیع تصادفی و امن نقش‌ها بین بازیکنان
///
/// طبق architecture.md بخش ۱۰: توزیع نقش با Random.secure().
library;

import 'dart:math';

import 'models/scenario.dart';
import 'models/session.dart';

class RoleAllocator {
  const RoleAllocator();

  /// بازیکن‌ها را می‌سازد و نقش‌ها را تصادفی توزیع می‌کند.
  ///
  /// اگر مجموع کارت‌های سناریو کمتر از تعداد بازیکن‌ها باشد،
  /// باقی‌مانده‌ها نقش «پرکننده» (شهروند ساده) می‌گیرند.
  List<LivePlayer> allocate({
    required GrdnScenario scenario,
    required List<String> playerNames,
    Random? random,
  }) {
    final rnd = random ?? Random.secure();

    // دسته کارت‌ها: هر نقش به تعداد count تکرار می‌شود
    final deck = <GrdnRole>[];
    for (final role in scenario.roles) {
      for (var i = 0; i < role.count; i++) {
        deck.add(role);
      }
    }

    final total = playerNames.length;
    if (deck.length > total) {
      throw ArgumentError(
          'تعداد کارت‌های سناریو (${deck.length}) بیشتر از بازیکن‌ها ($total) است');
    }

    // پر کردن باقی‌مانده با نقش پرکننده (شهروند ساده)
    final filler = scenario.fillerRole;
    while (deck.length < total) {
      if (filler == null) {
        throw ArgumentError('سناریو نقش پرکننده (شهروند ساده) ندارد');
      }
      deck.add(filler);
    }

    deck.shuffle(rnd);

    final players = <LivePlayer>[];
    for (var i = 0; i < total; i++) {
      players.add(LivePlayer(
        id: 'p${i + 1}',
        name: playerNames[i],
        roleId: deck[i].id,
      ));
    }
    return players;
  }
}
