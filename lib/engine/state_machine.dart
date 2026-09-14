/// ماشین حالت بازی — LOBBY → NIGHT → DAWN → DAY → VOTE → CHECK_WIN → ...
///
/// طبق architecture.md بخش ۳.۱: حالت‌ها از سناریو خوانده می‌شوند، نه هاردکد.
/// فازهای اضافی (مثلاً «محاکمه») به‌صورت داده‌محور چرخانده می‌شوند.
library;

import 'dart:math';

import 'action_executor.dart';
import 'models/scenario.dart';
import 'models/session.dart';
import 'role_allocator.dart';
import 'win_checker.dart';

class GardoonEngine {
  GardoonEngine({
    RoleAllocator? allocator,
    ActionExecutor? executor,
    WinChecker? winChecker,
  })  : allocator = allocator ?? const RoleAllocator(),
        executor = executor ?? const ActionExecutor(),
        winChecker = winChecker ?? const WinChecker();

  final RoleAllocator allocator;
  final ActionExecutor executor;
  final WinChecker winChecker;

  // ---------------------------------------------------------- شروع بازی

  /// ساخت جلسه جدید: توزیع نقش + ورود به اولین فاز چرخه
  GameSessionState startGame({
    required GrdnScenario scenario,
    required List<String> playerNames,
    Random? random,
  }) {
    final players =
        allocator.allocate(scenario: scenario, playerNames: playerNames);
    final firstId = scenario.flow.cycle.first;
    final first = scenario.phaseById(firstId);

    var state = GameSessionState(
      scenario: scenario,
      players: players,
      phaseIndex: 0,
      phaseId: firstId,
      phaseKind: first?.kind ?? 'night',
      phaseType: _typeOf(first?.kind ?? 'night'),
      roundNumber: scenario.flow.zeroNight ? 0 : 1,
      history: [
        GameLogEntry(
            round: 0,
            phaseKind: 'lobby',
            text: 'بازی با ${playerNames.length} نفر شروع شد',
            isPublic: true),
      ],
      wakeSteps: const [],
      wakeStepIndex: 0,
      pendingActions: const [],
      usedBlockCounts: const {},
      blockCooldownUntil: const {},
      lastDawnDeaths: const [],
      lastDawnBlocked: const [],
      silencedIds: const [],
      lovers: const {},
      revengeTargets: const {},
      voteCounts: const {},
      isRevote: false,
      finished: false,
      winnerTeamIds: const [],
      activeEvent: null,
      usedEventIds: const [],
      eventRounds: const {},
    );

    // آماده‌سازی فاز اول (شب)
    state = _onEnterNight(state, random: random);
    return state;
  }

  // ---------------------------------------------------------- فازها

  /// رفتن به فاز بعدی چرخه — در گذر از شب، resolve انجام می‌شود
  GameSessionState nextPhase(GameSessionState state, {Random? random}) {
    if (state.finished) return state;

    final kind = state.phaseKind;
    switch (kind) {
      case 'night':
        return _finishNight(state, random: random);
      case 'dawn':
        return _goTo(state, 1, random: random);
      case 'day':
        return _goTo(state, 1, random: random);
      case 'vote':
        // رأی‌گیری تمام شد — برگشت به شب، گردش جدید
        return _goTo(state, 1, random: random);
      default: // custom
        return _goTo(state, 1, random: random);
    }
  }

  GameSessionState _goTo(GameSessionState state, int offset, {Random? random}) {
    var idx = state.phaseIndex + offset;
    var round = state.roundNumber;
    final cycle = state.scenario.flow.cycle;

    if (idx >= cycle.length) {
      // برگشت به نقطه تکرار چرخه — گردش جدید
      final repeatIdx =
          cycle.indexOf(state.scenario.flow.repeatFrom, 0);
      idx = repeatIdx < 0 ? 0 : repeatIdx;
      round = round + 1;
    }

    final phase = state.scenario.phaseById(cycle[idx]);
    final kind = phase?.kind ?? 'day';

    var next = state.copyWith(
      phaseIndex: idx,
      phaseId: cycle[idx],
      phaseKind: kind,
      phaseType: _typeOf(kind),
      roundNumber: round,
    );

    if (kind == 'night') {
      next = _onEnterNight(next, random: random);
    } else if (kind == 'vote') {
      // رویداد «noVote» — امشب رأی‌گیری حذف می‌شود
      next = next.copyWith(voteCounts: const {}, isRevote: false);
    } else if (kind == 'day') {
      next = next.copyWith(
        history: [
          ...next.history,
          GameLogEntry(
              round: round,
              phaseKind: 'day',
              text: 'روز $round شروع شد',
              isPublic: true),
        ],
      );
    }
    return next;
  }

  GamePhaseType _typeOf(String kind) {
    switch (kind) {
      case 'night':
        return GamePhaseType.nightActions;
      case 'dawn':
        return GamePhaseType.dawn;
      case 'day':
        return GamePhaseType.dayDiscussion;
      case 'vote':
        return GamePhaseType.vote;
      case 'lobby':
        return GamePhaseType.lobby;
      default:
        return GamePhaseType.custom;
    }
  }

  // ---------------------------------------------------------- شب

  /// آیا این بلوک امشب قابل استفاده است؟
  bool isBlockUsable(GameSessionState state, GrdnAbility block, int night) {
    if (!block.enabled) return false;
    if (block.timing.when != 'night') return false;
    if (block.type == 'immunity') return false; // مصونیت غیرفعال (پسیو)

    final t = block.timing;
    if (t.onlyNightNumbers.isNotEmpty && !t.onlyNightNumbers.contains(night)) {
      return false;
    }
    if (t.notNightNumbers.contains(night)) return false;
    // قاعده شب اول بدون کشتن
    if (block.type == 'attack' &&
        night == 0 &&
        !state.scenario.rules.firstNightKill) {
      return false;
    }
    if (t.usesTotal >= 0 &&
        (state.usedBlockCounts[block.id] ?? 0) >= t.usesTotal) {
      return false;
    }
    final cd = state.blockCooldownUntil[block.id];
    if (cd != null && cd > night) return false;
    return true;
  }

  /// ساخت گام‌های بیداری شب بر اساس wakeList فاز شب
  List<WakeStep> buildWakeSteps(GameSessionState state) {
    final nightPhase = state.scenario.phases
        .cast<GrdnPhase?>()
        .firstWhere((p) => p?.kind == 'night', orElse: () => null);
    if (nightPhase == null) return const [];

    final steps = <WakeStep>[];
    for (final entry in nightPhase.wakeList) {
      List<LivePlayer> group;
      String title;
      if (entry.endsWith('*')) {
        final teamId = entry.substring(0, entry.length - 1);
        group = _aliveOfTeam(state, teamId);
        title = state.scenario.teamById(teamId)?.name ?? teamId;
      } else if (entry.startsWith('team:')) {
        final teamId = entry.substring(5);
        group = _aliveOfTeam(state, teamId);
        title = state.scenario.teamById(teamId)?.name ?? teamId;
      } else {
        group = state.players
            .where((p) => p.alive && p.roleId == entry)
            .toList();
        title = state.scenario.roleById(entry)?.name ?? entry;
      }

      // بلوک‌های قابل استفاده این گروه امشب
      final blocks = <GrdnAbility>[];
      for (final p in group) {
        final role = state.scenario.roleById(p.roleId);
        if (role == null) continue;
        for (final b in role.abilities) {
          if (isBlockUsable(state, b, state.roundNumber) &&
              !blocks.any((x) => x.id == b.id)) {
            blocks.add(b);
          }
        }
      }
      // گام بدون بلوک فعال — بیدار نمی‌شود
      if (group.isEmpty || blocks.isEmpty) continue;

      steps.add(WakeStep(
        title: '$title بیدار شود',
        playerIds: group.map((p) => p.id).toList(),
        blocks: blocks,
      ));
    }

    // autoWakeByPriority → مرتب‌سازی بر اساس اولویت نقش‌ها
    if (nightPhase.autoWakeByPriority) {
      int minPriority(WakeStep s) {
        var best = 9999;
        for (final id in s.playerIds) {
          final role =
              state.scenario.roleById(state.playerById(id)!.roleId);
          final pr = role?.priority ?? 900;
          if (pr < best) best = pr;
        }
        return best;
      }

      steps.sort((a, b) => minPriority(a).compareTo(minPriority(b)));
    }
    return steps;
  }

  List<LivePlayer> _aliveOfTeam(GameSessionState state, String teamId) {
    return state.players.where((p) {
      if (!p.alive) return false;
      return state.scenario.roleById(p.roleId)?.team == teamId;
    }).toList();
  }

  GameSessionState _onEnterNight(GameSessionState state, {Random? random}) {
    // قرعه‌کشی رویداد تصادفی (سطح ۴)
    final event = _rollEvent(state, random);

    final withEvent = state.copyWith(
      roundNumber: state.roundNumber,
      activeEvent: event,
      usedEventIds: event == null
          ? state.usedEventIds
          : [...state.usedEventIds, event],
      eventRounds: event == null
          ? state.eventRounds
          : {...state.eventRounds, event: state.roundNumber},
      silencedIds: const [],
      pendingActions: const [],
      wakeStepIndex: 0,
      isRevote: false,
      history: [
        ...state.history,
        GameLogEntry(
            round: state.roundNumber,
            phaseKind: 'night',
            text: 'شب ${state.roundNumber} شروع شد',
            isPublic: true),
      ],
    );

    var steps = buildWakeSteps(withEvent);

    // رویداد «سکوت» — یک نفر تصادفی امشب فردا ساکت است
    var silenced = List<String>.from(withEvent.silencedIds);
    if (event != null) {
      final ev = withEvent.scenario.events
          .cast<GrdnEvent?>()
          .firstWhere((e) => e?.id == event, orElse: () => null);
      if (ev != null && (ev.effects['silenceOneRandom'] ?? false)) {
        final alive =
            withEvent.players.where((p) => p.alive).toList()..shuffle(random);
        if (alive.isNotEmpty) silenced.add(alive.first.id);
      }
    }

    var out = withEvent.copyWith(silencedIds: silenced, wakeSteps: steps);
    // اگر هیچ گام بیداری نیست، شب آماده پرش است
    return out;
  }

  String? _rollEvent(GameSessionState state, Random? random) {
    final events = state.scenario.events;
    if (events.isEmpty) return null;
    final rnd = random ?? Random.secure();
    final pool = <GrdnEvent>[];
    for (final e in events) {
      if (state.usedEventIds.contains(e.id) && e.frequency.maxPerGame > 0 &&
          (state.usedEventIds.where((x) => x == e.id).length >=
              e.frequency.maxPerGame)) {
        continue;
      }
      if (state.roundNumber < e.frequency.fromRound) continue;
      final last = state.eventRounds[e.id];
      if (last != null && state.roundNumber - last < e.frequency.everyRounds) {
        continue;
      }
      pool.add(e);
    }
    if (pool.isEmpty) return null;
    final totalWeight = pool.fold(0, (s, e) => s + e.weight);
    if (totalWeight <= 0) return null;
    var roll = rnd.nextInt(totalWeight);
    for (final e in pool) {
      roll -= e.weight;
      if (roll < 0) return e.id;
    }
    return null;
  }

  /// ثبت اکشن شب برای گام فعلی — گرداننده هدف را تأیید می‌کند
  GameSessionState submitNightAction(
    GameSessionState state, {
    required String actorId,
    required GrdnAbility block,
    required String targetId,
  }) {
    final action = PendingAction(
      actorId: actorId,
      targetId: targetId,
      block: block,
      nightNumber: state.roundNumber,
    );
    // ثبت مصرف و کول‌داون
    final counts = Map<String, int>.from(state.usedBlockCounts);
    counts[block.id] = (counts[block.id] ?? 0) + 1;
    final cds = Map<String, int>.from(state.blockCooldownUntil);
    if (block.timing.cooldown > 0) {
      cds[block.id] =
          state.roundNumber + block.timing.cooldown + 1;
    }
    return state.copyWith(
      pendingActions: [...state.pendingActions, action],
      usedBlockCounts: counts,
      blockCooldownUntil: cds,
      wakeStepIndex: state.wakeStepIndex + 1,
      history: [
        ...state.history,
        GameLogEntry(
          round: state.roundNumber,
          phaseKind: 'night',
          text:
              '${state.playerById(actorId)?.name} «${block.name}» را روی ${state.playerById(targetId)?.name} اجرا کرد',
        ),
      ],
    );
  }

  /// رد کردن گام فعلی — بدون اکشن
  GameSessionState skipWakeStep(GameSessionState state) {
    return state.copyWith(
      wakeStepIndex: state.wakeStepIndex + 1,
      history: [
        ...state.history,
        GameLogEntry(
          round: state.roundNumber,
          phaseKind: 'night',
          text: 'گام «${_currentStepTitle(state)}» بدون اکشن رد شد',
        ),
      ],
    );
  }

  String _currentStepTitle(GameSessionState state) {
    if (state.wakeStepIndex < state.wakeSteps.length) {
      return state.wakeSteps[state.wakeStepIndex].title;
    }
    return 'شب';
  }

  /// پایان شب: resolve صف + ورود به سپیده‌دم
  GameSessionState _finishNight(GameSessionState state, {Random? random}) {
    final res = executor.resolve(
      state: state,
      actions: state.pendingActions,
      random: random,
    );

    // اعمال مرگ‌ها + تبدیل‌ها
    var players = List<LivePlayer>.from(state.players);
    final revealInfo = <String>[];
    for (final id in res.deaths) {
      players = players.map((p) {
        if (p.id == id && p.alive) {
          final role = state.scenario.roleById(p.roleId);
          final reveal = role?.deathReveal ?? 'role';
          if (reveal == 'role') {
            revealInfo.add('${p.name} — نقش: ${role?.name}');
          } else if (reveal == 'team') {
            final team = state.scenario.teamById(role?.team ?? '')?.name;
            revealInfo.add('${p.name} — تیم: $team');
          } else {
            revealInfo.add('${p.name} — نقش نامشخص');
          }
          return p.copyWith(alive: false, deathRound: state.roundNumber);
        }
        return p;
      }).toList();
    }
    for (final entry in res.converted.entries) {
      players = players.map((p) {
        if (p.id == entry.key) return p.copyWith(roleId: entry.value);
        return p;
      }).toList();
    }

    final dawnPhase = state.scenario.phases
        .cast<GrdnPhase?>()
        .firstWhere((p) => p?.kind == 'dawn', orElse: () => null);
    final dawnId = dawnPhase?.id ?? 'dawn';
    final cycle = state.scenario.flow.cycle;
    final dawnIdx = cycle.contains(dawnId)
        ? cycle.indexOf(dawnId)
        : (state.phaseIndex + 1) % cycle.length;

    final hideResults = state.activeEvent != null &&
        (state.scenario.events
                .cast<GrdnEvent?>()
                .firstWhere((e) => e?.id == state.activeEvent,
                    orElse: () => null)
                ?.effects['hideDawnResults'] ??
            false);

    var next = state.copyWith(
      players: players,
      phaseIndex: dawnIdx,
      phaseId: dawnId,
      phaseKind: 'dawn',
      phaseType: GamePhaseType.dawn,
      lastDawnDeaths: res.deaths,
      lastDawnBlocked: res.blockedActions,
      silencedIds: res.newSilenced,
      lovers: res.newLovers,
      revengeTargets: res.newRevengeTargets,
      pendingActions: const [],
      history: [
        ...state.history,
        ...res.logs,
        GameLogEntry(
          round: state.roundNumber,
          phaseKind: 'dawn',
          text: res.deaths.isEmpty
              ? 'شبی آرام بود — کسی از دست نرفت'
              : 'از دست رفتگان: ${res.deaths.map((id) => state.playerById(id)?.name).join("، ")}',
          isPublic: true,
        ),
      ],
    );

    // در سپیده‌دم گام‌ها خالی می‌شوند
    next = next.copyWith(wakeSteps: const [], wakeStepIndex: 0);

    // گزارش خصوصی گرداننده
    for (final m in res.hostMessages) {
      next = next.copyWith(history: [
        ...next.history,
        GameLogEntry(round: next.roundNumber, phaseKind: 'dawn', text: m),
      ]);
    }
    if (hideResults) {
      next = next.copyWith(history: [
        ...next.history,
        GameLogEntry(
          round: next.roundNumber,
          phaseKind: 'dawn',
          text: 'رویداد فعال: هیچ نتیجه‌ای اعلام نمی‌شود',
        ),
      ]);
    }

    // چک برد بعد از مرگ‌ها
    next = _checkWin(next);
    return next;
  }

  // ---------------------------------------------------------- رأی‌گیری

  /// افزودن رأی به یک بازیکن (جمع تراشه‌ای)
  GameSessionState castVote(GameSessionState state, String targetId,
      {int weight = 1}) {
    final counts = Map<String, int>.from(state.voteCounts);
    counts[targetId] = (counts[targetId] ?? 0) + weight;
    return state.copyWith(voteCounts: counts);
  }

  GameSessionState removeVote(GameSessionState state, String targetId) {
    final counts = Map<String, int>.from(state.voteCounts);
    final cur = counts[targetId] ?? 0;
    if (cur <= 1) {
      counts.remove(targetId);
    } else {
      counts[targetId] = cur - 1;
    }
    return state.copyWith(voteCounts: counts);
  }

  GameSessionState clearVotes(GameSessionState state) {
    return state.copyWith(voteCounts: const {});
  }

  /// پایان رأی‌گیری: تعیین حذف‌شده / برگشت رأی
  GameSessionState finalizeVote(GameSessionState state, {Random? random}) {
    final rnd = random ?? Random.secure();
    final counts = state.voteCounts;
    if (counts.isEmpty) {
      return state.copyWith(
        isRevote: false,
        history: [
          ...state.history,
          GameLogEntry(
              round: state.roundNumber,
              phaseKind: 'vote',
              text: 'هیچ رأیی ثبت نشد — کسی حذف نشد',
              isPublic: true),
        ],
      );
    }

    final maxVotes = counts.values.reduce(max);
    final top = counts.entries.where((e) => e.value == maxVotes).toList();

    if (top.length > 1) {
      // تساوی — طبق tieBreak
      switch (state.scenario.rules.vote.tieBreak) {
        case 'random':
          final winner = top[rnd.nextInt(top.length)].key;
          return _eliminate(state, winner);
        case 'none':
          return state.copyWith(
            isRevote: false,
            history: [
              ...state.history,
              GameLogEntry(
                  round: state.roundNumber,
                  phaseKind: 'vote',
                  text: 'تساوی رأی — کسی حذف نشد',
                  isPublic: true),
            ],
          );
        default: // revote
          return state.copyWith(
            isRevote: true,
            voteCounts: const {},
            history: [
              ...state.history,
              GameLogEntry(
                  round: state.roundNumber,
                  phaseKind: 'vote',
                  text: 'تساوی رأی — رأی‌گیری مجدد بین ${top.length} نفر',
                  isPublic: true),
            ],
          );
      }
    }
    return _eliminate(state, top.first.key);
  }

  GameSessionState _eliminate(GameSessionState state, String playerId) {
    final p = state.playerById(playerId);
    if (p == null) return state;
    final role = state.scenario.roleById(p.roleId);
    final revealMode = state.scenario.rules.vote.eliminatedReveal;
    String revealText;
    if (revealMode == 'role') {
      revealText = 'نقش او «${role?.name}» بود';
    } else if (revealMode == 'team') {
      final team = state.scenario.teamById(role?.team ?? '')?.name;
      revealText = 'تیم او «$team» بود';
    } else {
      revealText = 'نقشش مخفی ماند';
    }

    final players =
        state.players.map((x) => x.id == p.id
            ? x.copyWith(
                alive: false,
                deathRound: state.roundNumber,
                revealedRole: revealMode != 'nothing')
            : x).toList();

    var next = state.copyWith(
      players: players,
      isRevote: false,
      voteCounts: const {},
      history: [
        ...state.history,
        GameLogEntry(
          round: state.roundNumber,
          phaseKind: 'vote',
          text: '${p.name} با رأی شهر حذف شد — $revealText',
          isPublic: true,
        ),
      ],
    );
    return _checkWin(next);
  }

  // ---------------------------------------------------------- برد

  GameSessionState _checkWin(GameSessionState state) {
    final winners = winChecker.evaluate(state);
    if (winners.isEmpty) return state;
    return state.copyWith(
      finished: true,
      winnerTeamIds: winners,
      history: [
        ...state.history,
        GameLogEntry(
          round: state.roundNumber,
          phaseKind: 'finished',
          text:
              'بازی تمام شد — برنده: ${winners.map((w) => state.scenario.teamById(w)?.name ?? w).join(" و ")}',
          isPublic: true,
        ),
      ],
    );
  }

  // ---------------------------------------------------------- حذف دستی

  /// مرگ دستی (گرداننده خودش اعلام می‌کند — مثلاً خروج بازیکن)
  GameSessionState killPlayer(GameSessionState state, String playerId,
      {String reason = 'از بازی حذف شد'}) {
    final p = state.playerById(playerId);
    if (p == null || !p.alive) return state;
    final players = state.players
        .map((x) =>
            x.id == playerId ? x.copyWith(alive: false, deathRound: state.roundNumber) : x)
        .toList();
    var next = state.copyWith(
      players: players,
      history: [
        ...state.history,
        GameLogEntry(
          round: state.roundNumber,
          phaseKind: state.phaseKind,
          text: '${p.name} $reason',
          isPublic: true,
        ),
      ],
    );
    return _checkWin(next);
  }
}
