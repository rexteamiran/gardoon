/// تست موتور بازی — سناریوی حداقلی از لابی تا برد (طبق roadmap فاز ۲)
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gardoon/engine/json_codec.dart';
import 'package:gardoon/engine/models/scenario.dart';
import 'package:gardoon/engine/state_machine.dart';

GrdnScenario loadMinimal() {
  final raw = File('test/fixtures/minimal_scenario.json').readAsStringSync();
  final map = json.decode(raw) as Map<String, dynamic>;
  return const GrdnJsonCodec().decode(map, playersMin: 6, playersMax: 6);
}

GrdnScenario get scenario => loadMinimal();

void main() {
  final engine = GardoonEngine();

  test('توزیع نقش: ۶ نفر = ۲ مافیا + ۱ دکتر + ۳ شهروند', () {
    final players = engine.startGame(
      scenario: scenario,
      playerNames: ['علی', 'رضا', 'سارا', 'مریم', 'حسن', 'نرگس'],
      random: Random2(42),
    ).players;

    expect(players.length, 6);
    final byRole = <String, int>{};
    for (final p in players) {
      byRole[p.roleId] = (byRole[p.roleId] ?? 0) + 1;
    }
    expect(byRole['mafia'], 2);
    expect(byRole['doctor'], 1);
    expect(byRole['citizen'], 3);
  });

  test('شب صفر بدون کشتن است و چرخه کامل طی می‌شود', () {
    var state = engine.startGame(
      scenario: scenario,
      playerNames: ['علی', 'رضا', 'سارا', 'مریم', 'حسن', 'نرگس'],
      random: Random2(7),
    );

    // شب صفر — حمله غیرفعال (firstNightKill=false)
    expect(state.phaseKind, 'night');
    expect(state.roundNumber, 0);
    // هیچ گام بیداری فعال نباید بلوک حمله داشته باشد
    for (final step in state.wakeSteps) {
      expect(step.blocks.any((b) => b.type == 'attack'), isFalse);
    }

    // رد کردن همه گام‌های شب
    while (state.wakeStepIndex < state.wakeSteps.length) {
      state = engine.skipWakeStep(state);
    }
    state = engine.nextPhase(state);
    expect(state.phaseKind, 'dawn');
    expect(state.lastDawnDeaths, isEmpty);

    state = engine.nextPhase(state); // روز
    expect(state.phaseKind, 'day');
    state = engine.nextPhase(state); // رأی‌گیری
    expect(state.phaseKind, 'vote');
    state = engine.nextPhase(state); // برگشت به شب — گردش ۱
    expect(state.phaseKind, 'night');
    expect(state.roundNumber, 1);
  });

  test('حمله شبانه بدون نجات → مرگ در سپیده‌دم → شرط برد مافیا', () {
    var state = engine.startGame(
      scenario: scenario,
      playerNames: ['علی', 'رضا', 'سارا', 'مریم', 'حسن', 'نرگس'],
      random: Random2(3),
    );

    // پیدا کردن مافیاها، دکتر و یک شهروند
    final mafia = state.players.where((p) => p.roleId == 'mafia').toList();
    final doctor = state.players.firstWhere((p) => p.roleId == 'doctor');
    final victim = state.players
        .firstWhere((p) => p.roleId == 'citizen' && p.id != doctor.id);

    // شب ۱: مافیا به شهروند حمله می‌کند، دکتر کسی را نجات نمی‌دهد
    state = engine.submitNightAction(
      state,
      actorId: mafia.first.id,
      block: scenario.roleById('mafia')!.abilities.first,
      targetId: victim.id,
    );
    state = engine.nextPhase(state); // پایان شب → سپیده‌دم

    expect(state.lastDawnDeaths, contains(victim.id));
    expect(state.playerById(victim.id)!.alive, isFalse);
    // شهر = ۳ ، مافیا = ۲ → شرط برد مافیا هنوز برقرار نیست
    expect(state.finished, isFalse);

    // گردش بعد: مافیا شهروند دوم را می‌کشد → شهر = ۲ → برد مافیا
    while (state.phaseKind != 'night') {
      state = engine.nextPhase(state);
      if (state.finished) break;
    }
    if (!state.finished) {
      final victim2 = state.players
          .firstWhere((p) => p.alive && p.roleId == 'citizen');
      state = engine.submitNightAction(
        state,
        actorId: mafia.first.id,
        block: scenario.roleById('mafia')!.abilities.first,
        targetId: victim2.id,
      );
      state = engine.nextPhase(state);
      expect(state.finished, isTrue);
      expect(state.winnerTeamIds, contains('mafia'));
    }
  });

  test('نجات دکتر حمله را خنثی می‌کند', () {
    var state = engine.startGame(
      scenario: scenario,
      playerNames: ['علی', 'رضا', 'سارا', 'مریم', 'حسن', 'نرگس'],
      random: Random2(3),
    );

    final mafia = state.players.where((p) => p.roleId == 'mafia').toList();
    final doctor = state.players.firstWhere((p) => p.roleId == 'doctor');
    final victim = state.players.firstWhere((p) => p.roleId == 'citizen');

    // شب ۱: حمله مافیا + نجات دکتر روی همان هدف
    state = engine.submitNightAction(
      state,
      actorId: mafia.first.id,
      block: scenario.roleById('mafia')!.abilities.first,
      targetId: victim.id,
    );
    state = engine.submitNightAction(
      state,
      actorId: doctor.id,
      block: scenario.roleById('doctor')!.abilities.first,
      targetId: victim.id,
    );
    state = engine.nextPhase(state);

    expect(state.lastDawnDeaths, isEmpty);
    expect(state.finished, isFalse);
  });

  test('رأی‌گیری: اکثریت حذف می‌کند و مرگ دستی هم شرط برد را چک می‌کند', () {
    var state = engine.startGame(
      scenario: scenario,
      playerNames: ['علی', 'رضا', 'سارا', 'مریم', 'حسن', 'نرگس'],
      random: Random2(3),
    );

    final doctor = state.players.firstWhere((p) => p.roleId == 'doctor');

    // دکتر را با رأی حذف کن
    state = engine.castVote(state, doctor.id);
    state = engine.castVote(state, doctor.id);
    state = engine.castVote(state, doctor.id);
    state = engine.finalizeVote(state);

    expect(state.playerById(doctor.id)!.alive, isFalse);
    expect(state.playerById(doctor.id)!.revealedRole, isTrue);
    // شهر = ۳ شهروند ، مافیا = ۲ → بازی ادامه دارد
    expect(state.finished, isFalse);
  });

  test('تساوی رأی با tieBreak=revote به رأی مجدد می‌رود', () {
    var state = engine.startGame(
      scenario: scenario,
      playerNames: ['علی', 'رضا', 'سارا', 'مریم', 'حسن', 'نرگس'],
      random: Random2(3),
    );
    final two = state.players.take(2).toList();
    state = engine.castVote(state, two[0].id);
    state = engine.castVote(state, two[1].id);
    state = engine.finalizeVote(state);
    expect(state.isRevote, isTrue);
  });

  test('همه مافیاها حذف شوند → برد شهر', () {
    var state = engine.startGame(
      scenario: scenario,
      playerNames: ['علی', 'رضا', 'سارا', 'مریم', 'حسن', 'نرگس'],
      random: Random2(3),
    );
    final mafia = state.players.where((p) => p.roleId == 'mafia').toList();
    for (final m in mafia) {
      state = engine.killPlayer(state, m.id, reason: 'تست');
    }
    expect(state.finished, isTrue);
    expect(state.winnerTeamIds, contains('city'));
  });
}

/// مولد تصادفی ثابت برای تست
class Random2 implements Random {
  Random2(this.seed);
  final int seed;
  int _state = 0;

  @override
  bool nextBool() => nextInt(2) == 0;

  @override
  double nextDouble() => nextInt(1000) / 1000;

  @override
  int nextInt(int max) {
    _state = (_state * 1103515245 + 12345 + seed) % 2147483647;
    return _state % max;
  }
}
