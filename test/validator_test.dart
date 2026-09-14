/// تست اعتبارسنجی — هر قانون خطا/هشدار یک تست (طبق agents.md بخش ۷)
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gardoon/engine/json_codec.dart';
import 'package:gardoon/engine/models/scenario.dart';
import 'package:gardoon/engine/validator.dart';

GrdnJsonCodec codec = const GrdnJsonCodec();

GrdnScenario loadMinimal() {
  final raw = File('test/fixtures/minimal_scenario.json').readAsStringSync();
  final map = json.decode(raw) as Map<String, dynamic>;
  return codec.decode(map, playersMin: 6, playersMax: 6);
}

void main() {
  final validator = const ScenarioValidator();

  test('سناریوی حداقلی معتبر است', () {
    final result = validator.validate(loadMinimal());
    expect(result.isValid, isTrue, reason: '${result.errors}');
    expect(result.balance['mafia'], greaterThan(0));
    expect(result.balance['city'], greaterThan(0));
  });

  test('تیم کمتر از دو → خطا', () {
    final s = loadMinimal();
    final fixed = GrdnScenario(
      playersMin: s.playersMin,
      playersMax: s.playersMax,
      meta: s.meta,
      teams: [s.teams.first],
      roles: s.roles,
      flow: s.flow,
      phases: s.phases,
      rules: s.rules,
      winConditions: s.winConditions,
      events: s.events,
    );
    final result = validator.validate(fixed);
    expect(result.errors.any((e) => e.text.contains('حداقل دو تیم')), isTrue);
  });

  test('ارجاع به تیم ناموجود → خطا', () {
    final s = loadMinimal();
    final fixed = GrdnScenario(
      playersMin: s.playersMin,
      playersMax: s.playersMax,
      meta: s.meta,
      teams: s.teams,
      roles: s.roles
          .map((r) => r.team == 'city'
              ? const GrdnRole(
                  id: 'citizen',
                  name: 'شهروند',
                  team: 'nope',
                  count: 3,
                  icon: 'builtin:person',
                  cardColor: '#37474F',
                  cardFrame: 'builtin:classic',
                  priority: 900,
                  knownTo: [],
                  description: '',
                  deathReveal: 'nothing',
                  abilities: [])
              : r)
          .toList(),
      flow: s.flow,
      phases: s.phases,
      rules: s.rules,
      winConditions: s.winConditions,
      events: s.events,
    );
    final result = validator.validate(fixed);
    expect(
        result.errors.any((e) => e.text.contains('تیم ناموجود')), isTrue);
  });

  test('مجموع کارت‌ها خارج از بازه → خطا', () {
    final s = loadMinimal();
    final fixed = GrdnScenario(
      playersMin: 10,
      playersMax: 12,
      meta: s.meta,
      teams: s.teams,
      roles: s.roles,
      flow: s.flow,
      phases: s.phases,
      rules: s.rules,
      winConditions: s.winConditions,
      events: s.events,
    );
    final result = validator.validate(fixed);
    expect(result.errors.any((e) => e.text.contains('بازه بازیکن‌ها')), isTrue);
  });

  test('اولویت خارج از ۱۰..۹۰۰ → خطا', () {
    final s = loadMinimal();
    final fixed = GrdnScenario(
      playersMin: s.playersMin,
      playersMax: s.playersMax,
      meta: s.meta,
      teams: s.teams,
      roles: s.roles
          .map((r) => r.id == 'mafia'
              ? GrdnRole(
                  id: r.id,
                  name: r.name,
                  team: r.team,
                  count: r.count,
                  icon: r.icon,
                  cardColor: r.cardColor,
                  cardFrame: r.cardFrame,
                  priority: 5,
                  knownTo: r.knownTo,
                  description: r.description,
                  deathReveal: r.deathReveal,
                  abilities: r.abilities)
              : r)
          .toList(),
      flow: s.flow,
      phases: s.phases,
      rules: s.rules,
      winConditions: s.winConditions,
      events: s.events,
    );
    final result = validator.validate(fixed);
    expect(
        result.errors.any((e) => e.text.contains('اولویت')), isTrue);
  });

  test('بلوک شبانه بدون جایگاه در wakeList → خطا', () {
    final s = loadMinimal();
    final fixed = GrdnScenario(
      playersMin: s.playersMin,
      playersMax: s.playersMax,
      meta: s.meta,
      teams: s.teams,
      roles: s.roles,
      flow: s.flow,
      phases: s.phases
          .map((p) => p.id == 'night'
              ? GrdnPhase(
                  id: p.id,
                  name: p.name,
                  kind: p.kind,
                  sound: p.sound,
                  autoWakeByPriority: p.autoWakeByPriority,
                  wakeList: const ['doctor'],
                  timer: p.timer)
              : p)
          .toList(),
      rules: s.rules,
      winConditions: s.winConditions,
      events: s.events,
    );
    final result = validator.validate(fixed);
    expect(
        result.errors.any((e) => e.text.contains('لیست بیداری شب')), isTrue);
  });

  test('شرط برد خالی → خطا', () {
    final s = loadMinimal();
    final fixed = GrdnScenario(
      playersMin: s.playersMin,
      playersMax: s.playersMax,
      meta: s.meta,
      teams: s.teams,
      roles: s.roles,
      flow: s.flow,
      phases: s.phases,
      rules: s.rules,
      winConditions: const [],
      events: s.events,
    );
    final result = validator.validate(fixed);
    expect(
        result.errors.any((e) => e.text.contains('شرط برد')), isTrue);
  });

  test('تیم بدون حمله → هشدار (نه خطا)', () {
    final s = loadMinimal();
    // دکتر را تیم خودش نگه می‌داریم ولی مافیا را حذف بلوک می‌کنیم
    final fixed = GrdnScenario(
      playersMin: s.playersMin,
      playersMax: s.playersMax,
      meta: s.meta,
      teams: s.teams,
      roles: s.roles
          .map((r) => r.id == 'mafia'
              ? GrdnRole(
                  id: r.id,
                  name: r.name,
                  team: r.team,
                  count: r.count,
                  icon: r.icon,
                  cardColor: r.cardColor,
                  cardFrame: r.cardFrame,
                  priority: r.priority,
                  knownTo: r.knownTo,
                  description: r.description,
                  deathReveal: r.deathReveal,
                  abilities: const [])
              : r)
          .toList(),
      flow: s.flow,
      phases: s.phases,
      rules: s.rules,
      winConditions: s.winConditions,
      events: s.events,
    );
    final result = validator.validate(fixed);
    expect(result.isValid, isTrue);
    expect(result.warnings.any((w) => w.text.contains('حمله')), isTrue);
  });

  test('id تکراری → خطا', () {
    final s = loadMinimal();
    final fixed = GrdnScenario(
      playersMin: s.playersMin,
      playersMax: s.playersMax,
      meta: s.meta,
      teams: [...s.teams, s.teams.first],
      roles: s.roles,
      flow: s.flow,
      phases: s.phases,
      rules: s.rules,
      winConditions: s.winConditions,
      events: s.events,
    );
    final result = validator.validate(fixed);
    expect(result.errors.any((e) => e.text.contains('تیم تکراری')), isTrue);
  });
}
