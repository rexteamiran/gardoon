/// وضعیت زنده یک بازی در حال اجرا — طبق architecture.md بخش ۳.۲
///
/// وضعیت بازی immutable است؛ هر تغییر یک state جدید می‌سازد.
library;

import 'scenario.dart';

/// انواع فاز ماشین حالت
enum GamePhaseType { lobby, nightActions, dawn, dayDiscussion, vote, custom, finished }

/// یک بازیکن زنده در میز
class LivePlayer {
  const LivePlayer({
    required this.id,
    required this.name,
    required this.roleId,
    this.alive = true,
    this.deathRound,
    this.revealedRole = false,
  });

  final String id; // p1, p2, ...
  final String name;
  final String roleId;
  final bool alive;
  final int? deathRound;
  final bool revealedRole; // نقشش فاش شده (رأی‌گیری/مکاشفه)

  LivePlayer copyWith(
          {String? roleId,
          bool? alive,
          int? deathRound,
          bool? revealedRole}) =>
      LivePlayer(
        id: id,
        name: name,
        roleId: roleId ?? this.roleId,
        alive: alive ?? this.alive,
        deathRound: deathRound ?? this.deathRound,
        revealedRole: revealedRole ?? this.revealedRole,
      );
}

/// اکشن صف‌شده شب — تا پایان شب اعمال نمی‌شود
class PendingAction {
  const PendingAction({
    required this.actorId,
    required this.targetId,
    required this.block,
    required this.nightNumber,
  });

  final String actorId;
  final String targetId;
  final GrdnAbility block;
  final int nightNumber;
}

/// یک خط از تاریخچه بازی — برای لاگ گردش‌ها و وصیت
class GameLogEntry {
  const GameLogEntry({
    required this.round,
    required this.phaseKind,
    required this.text,
    this.isPublic = false,
  });

  final int round;
  final String phaseKind;
  final String text;
  final bool isPublic; // عمومی (اعلام) یا خصوصی گرداننده
}

/// گام بیداری شب — یک گروه از نقش‌ها که هم‌زمان بیدار می‌شوند
class WakeStep {
  const WakeStep({
    required this.title,
    required this.playerIds,
    required this.blocks,
  });

  final String title; // «مافیا بیدار شود»
  final List<String> playerIds; // بازیکن‌های این گام
  final List<GrdnAbility> blocks; // بلوک‌های شبانه فعالِ این گام
}

/// وضعیت کامل جلسه بازی
class GameSessionState {
  const GameSessionState({
    required this.scenario,
    required this.players,
    required this.phaseIndex,
    required this.phaseId,
    required this.phaseKind,
    required this.phaseType,
    required this.roundNumber,
    required this.history,
    required this.wakeSteps,
    required this.wakeStepIndex,
    required this.pendingActions,
    required this.usedBlockCounts,
    required this.blockCooldownUntil,
    required this.lastDawnDeaths,
    required this.lastDawnBlocked,
    required this.silencedIds,
    required this.lovers,
    required this.revengeTargets,
    required this.voteCounts,
    required this.isRevote,
    required this.finished,
    required this.winnerTeamIds,
    required this.activeEvent,
    required this.usedEventIds,
    required this.eventRounds,
  });

  final GrdnScenario scenario;
  final List<LivePlayer> players;

  final int phaseIndex; // جای فعلی در flow.cycle
  final String phaseId;
  final String phaseKind; // night/dawn/day/vote/custom
  final GamePhaseType phaseType;
  final int roundNumber; // شماره شب — شب ۰ = شب آشنایی

  final List<GameLogEntry> history;

  final List<WakeStep> wakeSteps; // گام‌های بیداری شب فعلی
  final int wakeStepIndex; // الان کدام گام است

  final List<PendingAction> pendingActions; // صف اکشن‌های شب
  final Map<String, int> usedBlockCounts; // blockId → چند بار استفاده شده
  final Map<String, int> blockCooldownUntil; // blockId → شبِ آزادشدن از کول‌داون

  final List<String> lastDawnDeaths; // id بازیکن‌های مرده در آخرین شب
  final List<String> lastDawnBlocked; // اکشن‌هایی که بلاک شدند
  final List<String> silencedIds; // امروز حق حرف ندارد
  final Map<String, String> lovers; // playerId → loverId
  final Map<String, String> revengeTargets; // actorId → targetId

  final Map<String, int> voteCounts; // playerId → تعداد رأی
  final bool isRevote; // در حال رأی‌گیری مجدد

  final bool finished;
  final List<String> winnerTeamIds;

  final String? activeEvent; // رویداد فعال این گردش
  final List<String> usedEventIds; // رویدادهایی که تا حالا افتاده‌اند
  final Map<String, int> eventRounds; // eventId → آخرین گردشی که افتاد

  int aliveCountOfTeam(String teamId) => players
      .where((p) => p.alive && scenario.roleById(p.roleId)?.team == teamId)
      .length;

  int aliveCountOfRole(String roleId) =>
      players.where((p) => p.alive && p.roleId == roleId).length;

  int get aliveTotal => players.where((p) => p.alive).length;

  LivePlayer? playerById(String id) {
    for (final p in players) {
      if (p.id == id) return p;
    }
    return null;
  }

  GrdnPhase? get currentPhaseDef => scenario.phaseById(phaseId);

  /// نسخهٔ کپی‌شده با تغییرات — الگوی immutable
  GameSessionState copyWith({
    List<LivePlayer>? players,
    int? phaseIndex,
    String? phaseId,
    String? phaseKind,
    GamePhaseType? phaseType,
    int? roundNumber,
    List<GameLogEntry>? history,
    List<WakeStep>? wakeSteps,
    int? wakeStepIndex,
    List<PendingAction>? pendingActions,
    Map<String, int>? usedBlockCounts,
    Map<String, int>? blockCooldownUntil,
    List<String>? lastDawnDeaths,
    List<String>? lastDawnBlocked,
    List<String>? silencedIds,
    Map<String, String>? lovers,
    Map<String, String>? revengeTargets,
    Map<String, int>? voteCounts,
    bool? isRevote,
    bool? finished,
    List<String>? winnerTeamIds,
    String? activeEvent,
    bool clearActiveEvent = false,
    List<String>? usedEventIds,
    Map<String, int>? eventRounds,
  }) {
    return GameSessionState(
      scenario: scenario,
      players: players ?? this.players,
      phaseIndex: phaseIndex ?? this.phaseIndex,
      phaseId: phaseId ?? this.phaseId,
      phaseKind: phaseKind ?? this.phaseKind,
      phaseType: phaseType ?? this.phaseType,
      roundNumber: roundNumber ?? this.roundNumber,
      history: history ?? this.history,
      wakeSteps: wakeSteps ?? this.wakeSteps,
      wakeStepIndex: wakeStepIndex ?? this.wakeStepIndex,
      pendingActions: pendingActions ?? this.pendingActions,
      usedBlockCounts: usedBlockCounts ?? this.usedBlockCounts,
      blockCooldownUntil: blockCooldownUntil ?? this.blockCooldownUntil,
      lastDawnDeaths: lastDawnDeaths ?? this.lastDawnDeaths,
      lastDawnBlocked: lastDawnBlocked ?? this.lastDawnBlocked,
      silencedIds: silencedIds ?? this.silencedIds,
      lovers: lovers ?? this.lovers,
      revengeTargets: revengeTargets ?? this.revengeTargets,
      voteCounts: voteCounts ?? this.voteCounts,
      isRevote: isRevote ?? this.isRevote,
      finished: finished ?? this.finished,
      winnerTeamIds: winnerTeamIds ?? this.winnerTeamIds,
      activeEvent: clearActiveEvent ? null : (activeEvent ?? this.activeEvent),
      usedEventIds: usedEventIds ?? this.usedEventIds,
      eventRounds: eventRounds ?? this.eventRounds,
    );
  }
}
