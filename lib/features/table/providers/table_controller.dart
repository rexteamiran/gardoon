/// کنترلر میزگرد — پل UI ↔ موتور بازی
///
/// منطق در controller؛ ویجت‌ها فقط UI (agents.md بخش ۴).
library;

import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../audio/sound_manager.dart';
import '../../../data/scenario_store.dart';
import '../../../engine/models/session.dart';
import '../../../engine/state_machine.dart';
import '../../../engine/win_checker.dart';

/// مرحله اپ در جریان میزگرد
enum TableStage { setup, deal, play }

class TableState {
  const TableState({
    this.stage = TableStage.setup,
    this.session,
    this.entry,
    this.playerNames = const [],
    this.dealIndex = 0,
    this.cardFlipped = false,
    this.stats = const {},
  });

  final TableStage stage;
  final GameSessionState? session;
  final LibraryEntry? entry;
  final List<String> playerNames;
  final int dealIndex; // نقش‌کشه — نوبت کدام بازیکن
  final bool cardFlipped; // کارت باز شده؟
  final Map<String, int> stats; // آمار پایانی

  TableState copyWith({
    TableStage? stage,
    GameSessionState? session,
    LibraryEntry? entry,
    List<String>? playerNames,
    int? dealIndex,
    bool? cardFlipped,
    Map<String, int>? stats,
  }) =>
      TableState(
        stage: stage ?? this.stage,
        session: session ?? this.session,
        entry: entry ?? this.entry,
        playerNames: playerNames ?? this.playerNames,
        dealIndex: dealIndex ?? this.dealIndex,
        cardFlipped: cardFlipped ?? this.cardFlipped,
        stats: stats ?? this.stats,
      );
}

class TableController extends StateNotifier<TableState> {
  TableController(this._sound) : super(const TableState());

  final SoundManager _sound;
  final GardoonEngine engine = GardoonEngine();
  final Random _rnd = Random.secure();

  // ------------------------------------------------ شروع

  void startGame(LibraryEntry entry, List<String> names) {
    final session = engine.startGame(
      scenario: entry.scenario,
      playerNames: names,
      random: _rnd,
    );
    _sound.play(GardoonSound.wheel);
    _sound.play(GardoonSound.night);
    state = TableState(
      stage: TableStage.deal,
      session: session,
      entry: entry,
      playerNames: names,
      dealIndex: 0,
      cardFlipped: false,
    );
  }

  // ------------------------------------------------ نقش‌کشه

  void flipCard() {
    if (state.cardFlipped) return;
    _sound.play(GardoonSound.tap);
    state = state.copyWith(cardFlipped: true);
  }

  /// «دیدم، مخفی کن» → نفر بعد یا ورود به میزگرد
  void nextDeal() {
    final s = state.session;
    if (s == null) return;
    if (state.dealIndex + 1 >= state.playerNames.length) {
      state = state.copyWith(stage: TableStage.play, cardFlipped: false);
      return;
    }
    state = state.copyWith(
      dealIndex: state.dealIndex + 1,
      cardFlipped: false,
    );
  }

  // ------------------------------------------------ شب

  WakeStep? get currentStep {
    final s = state.session;
    if (s == null || s.wakeStepIndex >= s.wakeSteps.length) return null;
    return s.wakeSteps[s.wakeStepIndex];
  }

  /// انتخاب هدف برای گام فعلی
  void submitNightAction(String targetId) {
    final s = state.session;
    final step = currentStep;
    if (s == null || step == null) return;
    // اولین بازیکن زنده گروه + اولین بلوک فعال = اجراکننده
    final actorId = step.playerIds.first;
    _sound.play(GardoonSound.tap);
    final next = engine.submitNightAction(
      s,
      actorId: actorId,
      block: step.blocks.first,
      targetId: targetId,
    );
    state = state.copyWith(session: next);
  }

  void skipWakeStep() {
    final s = state.session;
    if (s == null) return;
    state = state.copyWith(session: engine.skipWakeStep(s));
  }

  // ------------------------------------------------ فازها

  void nextPhase() {
    final s = state.session;
    if (s == null) return;
    final before = s.phaseKind;
    final after = engine.nextPhase(s, random: _rnd);
    _onPhaseSound(before, after);
    state = state.copyWith(session: after);
  }

  void _onPhaseSound(String before, GameSessionState after) {
    if (after.finished) {
      _sound.play(GardoonSound.win);
      return;
    }
    if (after.phaseKind != before) {
      _sound.play(GardoonSound.wheel);
      switch (after.phaseKind) {
        case 'night':
          _sound.play(GardoonSound.night);
          break;
        case 'dawn':
          if (after.lastDawnDeaths.isNotEmpty) {
            _sound.play(GardoonSound.death);
          } else {
            _sound.play(GardoonSound.dawn);
          }
          break;
        case 'vote':
          _sound.play(GardoonSound.vote);
          break;
      }
    }
  }

  /// مرگ دستی — گرداننده خودش اعلام می‌کند
  void killManual(String playerId) {
    final s = state.session;
    if (s == null) return;
    _sound.play(GardoonSound.death);
    state = state.copyWith(session: engine.killPlayer(s, playerId));
  }

  // ------------------------------------------------ رأی‌گیری

  void castVote(String targetId) {
    final s = state.session;
    if (s == null) return;
    state = state.copyWith(session: engine.castVote(s, targetId));
  }

  void removeVote(String targetId) {
    final s = state.session;
    if (s == null) return;
    state = state.copyWith(session: engine.removeVote(s, targetId));
  }

  void clearVotes() {
    final s = state.session;
    if (s == null) return;
    state = state.copyWith(session: engine.clearVotes(s));
  }

  void finalizeVote() {
    final s = state.session;
    if (s == null) return;
    final after = engine.finalizeVote(s, random: _rnd);
    if (after.finished) {
      _sound.play(GardoonSound.win);
    } else {
      _sound.play(GardoonSound.vote);
    }
    state = state.copyWith(session: after);
  }

  // ------------------------------------------------ پایان / خروج

  void quit() {
    state = const TableState();
  }
}

final tableProvider =
    StateNotifierProvider<TableController, TableState>((ref) {
  final controller = TableController(ref.read(soundManagerProvider));
  ref.onDispose(controller.dispose);
  return controller;
});

/// برنده‌های فعلی — برای صفحه پایان
final winnerNamesProvider = Provider<List<String>>((ref) {
  final s = ref.watch(tableProvider).session;
  if (s == null) return const [];
  return s.winnerTeamIds
      .map((id) => s.scenario.teamById(id)?.name ?? id)
      .toList();
});

/// شرط برد را دوباره ارزیابی می‌کند (برای نمایش زنده در میزگرد)
final winStatusProvider = Provider<List<String>>((ref) {
  final s = ref.watch(tableProvider).session;
  if (s == null) return const [];
  return const WinChecker().evaluate(s);
});
