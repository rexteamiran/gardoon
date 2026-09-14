/// کنترلر سناریوساز سطح ۱ — فرم‌محور (رایگان)
///
/// سناریوی ساخته‌شده مستقیم به میزگرد می‌رود — همان موتور (architecture.md ۱)
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engine/models/scenario.dart';
import '../../engine/validator.dart';

class BuilderState {
  const BuilderState({
    this.scenarioId,
    this.name = '',
    this.description = '',
    this.author = '',
    this.scenario,
  });

  final String? scenarioId; // null = سناریوی جدید
  final String name;
  final String description;
  final String author;
  final GrdnScenario? scenario;

  BuilderState copyWith({
    String? scenarioId,
    String? name,
    String? description,
    String? author,
    GrdnScenario? scenario,
    bool clearId = false,
  }) =>
      BuilderState(
        scenarioId: clearId ? null : (scenarioId ?? this.scenarioId),
        name: name ?? this.name,
        description: description ?? this.description,
        author: author ?? this.author,
        scenario: scenario ?? this.scenario,
      );
}

class BuilderController extends StateNotifier<BuilderState> {
  BuilderController() : super(const BuilderState());

  final _validator = const ScenarioValidator();

  ValidationResult validate(GrdnScenario s) => _validator.validate(s);

  // ------------------------------------------------ سناریوی پایه

  /// از صفر — قالب شهر/مافیا
  void newBlank() {
    state = BuilderState(
      name: '',
      description: '',
      author: 'گرداننده',
      scenario: _blankTemplate(),
    );
  }

  /// از کپی یک سناریوی موجود
  void fromCopy(LightEntry e) {
    state = BuilderState(
      name: '${e.name} (کپی)',
      description: e.description,
      author: e.author,
      scenario: e.scenario,
    );
  }

  void loadForEdit(LightEntry e) {
    state = BuilderState(
      scenarioId: e.id,
      name: e.name,
      description: e.description,
      author: e.author,
      scenario: e.scenario,
    );
  }

  void setName(String v) => state = state.copyWith(name: v);
  void setDescription(String v) => state = state.copyWith(description: v);
  void setAuthor(String v) => state = state.copyWith(author: v);

  void setPlayersMin(int v) {
    final s = state.scenario;
    if (s == null) return;
    state = state.copyWith(
        scenario: _withScenario(s, playersMin: v.clamp(4, 20)));
    _syncFillerCount();
  }

  void setPlayersMax(int v) {
    final s = state.scenario;
    if (s == null) return;
    state = state.copyWith(
        scenario: _withScenario(s, playersMax: v.clamp(4, 20)));
  }

  // ------------------------------------------------ نقش‌ها

  void addRole({
    required String name,
    required String teamId,
    required String abilityType, // none | attack | save | inspect | protect
    required bool immuneToInspect,
  }) {
    final s = state.scenario;
    if (s == null) return;

    final id = _uniqueRoleId(s, teamId);
    final blocks = <GrdnAbility>[];
    if (abilityType != 'none') {
      blocks.add(_presetBlock("$id-b1", abilityType));
    }
    if (immuneToInspect) {
      blocks.add(_immunityBlock("$id-imm"));
    }

    final role = GrdnRole(
      id: id,
      name: name,
      team: teamId,
      count: 1,
      icon: _iconFor(abilityType),
      cardColor: s.teamById(teamId)?.color ?? '#37474F',
      cardFrame: 'builtin:classic',
      priority: _nextPriority(s, teamId),
      knownTo: teamId == 'mafia' ? const ['mafia'] : const [],
      description: _descFor(abilityType, name),
      deathReveal: 'role',
      abilities: blocks,
    );

    var next = _withScenario(s, roles: [...s.roles, role]);
    next = _ensureWakeEntries(next);
    state = state.copyWith(scenario: next);
    _syncFillerCount();
  }

  void updateRoleCount(String roleId, int delta) {
    final s = state.scenario;
    if (s == null) return;
    final roles = s.roles.map((r) {
      if (r.id == roleId) {
        return GrdnRole(
          id: r.id, name: r.name, team: r.team,
          count: (r.count + delta).clamp(0, 12), icon: r.icon,
          cardColor: r.cardColor, cardFrame: r.cardFrame,
          priority: r.priority, knownTo: r.knownTo,
          description: r.description, deathReveal: r.deathReveal,
          abilities: r.abilities,
        );
      }
      return r;
    }).toList();
    state = state.copyWith(scenario: _withScenario(s, roles: roles));
    _syncFillerCount();
  }

  void removeRole(String roleId) {
    final s = state.scenario;
    if (s == null) return;
    var next = _withScenario(
        s, roles: s.roles.where((r) => r.id != roleId).toList());
    next = _ensureWakeEntries(next);
    state = state.copyWith(scenario: next);
    _syncFillerCount();
  }

  // ------------------------------------------------ تیم فرقه (سطح ۱)

  void toggleCultTeam(bool enable) {
    final s = state.scenario;
    if (s == null) return;
    if (enable) {
      if (s.teamById('cult') != null) return;
      var next = _withScenario(s, teams: [
        ...s.teams,
        const GrdnTeam(
            id: 'cult', name: 'فرقه', color: '#6A1B9A', icon: 'builtin:candle'),
      ]);
      // شرط برد فرقه
      next = _withScenario(next, winConditions: [
        ...next.winConditions,
        const GrdnWinCondition(
          team: 'cult',
          join: 'AND',
          terms: [
            GrdnTerm(left: 'aliveCount:cult', op: '>=', right: '2'),
            GrdnTerm(left: 'round', op: '>=', right: '5'),
          ],
        ),
      ]);
      state = state.copyWith(scenario: next);
    } else {
      var next = _withScenario(
        s,
        teams: s.teams.where((t) => t.id != 'cult').toList(),
        roles: s.roles.where((r) => r.team != 'cult').toList(),
        winConditions: s.winConditions
            .where((w) => w.team != 'cult')
            .toList(),
      );
      next = _ensureWakeEntries(next);
      state = state.copyWith(scenario: next);
      _syncFillerCount();
    }
  }

  bool get hasCult => state.scenario?.teamById('cult') != null;

  // ------------------------------------------------ فازها (شب/روز)

  void setPhaseTimer(String phaseId, int seconds) {
    final s = state.scenario;
    if (s == null) return;
    final phases = s.phases.map((p) {
      if (p.id != phaseId) return p;
      return GrdnPhase(
        id: p.id, name: p.name, kind: p.kind, sound: p.sound,
        autoWakeByPriority: p.autoWakeByPriority, wakeList: p.wakeList,
        timer: seconds,
      );
    }).toList();
    state = state.copyWith(scenario: _withScenario(s, phases: phases));
  }

  /// جابه‌جایی ترتیب بیداری شب
  void moveWakeEntry(int index, int direction) {
    final s = state.scenario;
    if (s == null) return;
    final nightPhase =
        s.phases.firstWhere((p) => p.kind == 'night', orElse: () => s.phases.first);
    if (nightPhase.kind != 'night') return;
    final list = [...nightPhase.wakeList];
    final target = index + direction;
    if (target < 0 || target >= list.length) return;
    final tmp = list[index];
    list[index] = list[target];
    list[target] = tmp;

    final phases = s.phases.map((p) {
      if (p.id != nightPhase.id) return p;
      return GrdnPhase(
        id: p.id, name: p.name, kind: p.kind, sound: p.sound,
        autoWakeByPriority: p.autoWakeByPriority, wakeList: list,
        timer: p.timer,
      );
    }).toList();
    state = state.copyWith(scenario: _withScenario(s, phases: phases));
  }

  // ------------------------------------------------ قوانین

  void setFirstNightKill(bool v) {
    final s = state.scenario;
    if (s == null) return;
    state = state.copyWith(
        scenario: _withScenario(s, firstNightKill: v));
  }

  void setDoctorSelfSave(bool v) {
    final s = state.scenario;
    if (s == null) return;
    state = state.copyWith(scenario: _withScenario(s, doctorSelfSave: v));
  }

  // ------------------------------------------------ شرط برد (پریست)

  void setWinPreset(bool standard, bool cultCondition) {
    final s = state.scenario;
    if (s == null) return;
    final conditions = <GrdnWinCondition>[];
    if (standard) {
      conditions.add(const GrdnWinCondition(
        team: 'city', join: 'AND',
        terms: [GrdnTerm(left: 'aliveCount:mafia', op: '==', right: '0')],
      ));
      conditions.add(const GrdnWinCondition(
        team: 'mafia', join: 'AND',
        terms: [GrdnTerm(left: 'aliveCount:mafia', op: '>=', right: 'aliveCount:city')],
      ));
    }
    if (cultCondition && s.teamById('cult') != null) {
      conditions.add(const GrdnWinCondition(
        team: 'cult', join: 'AND',
        terms: [
          GrdnTerm(left: 'aliveCount:cult', op: '>=', right: '2'),
          GrdnTerm(left: 'round', op: '>=', right: '5'),
        ],
      ));
    }
    state = state.copyWith(
        scenario: _withScenario(s, winConditions: conditions));
  }

  // ------------------------------------------------ helpers

  GrdnScenario _blankTemplate() {
    return GrdnScenario(
      playersMin: 6,
      playersMax: 12,
      meta: const GrdnMeta(
        icon: 'builtin:star',
        color: '#1B2A4A',
        language: 'fa',
        defaultTimers: GrdnTimers(
            night: 45, dawn: 15, discussion: 120, vote: 30),
      ),
      teams: const [
        GrdnTeam(
            id: 'city', name: 'شهر', color: '#2E7D32', icon: 'builtin:dove'),
        GrdnTeam(
            id: 'mafia',
            name: 'مافیا',
            color: '#B71C1C',
            icon: 'builtin:fedora'),
      ],
      roles: const [
        GrdnRole(
          id: 'citizen', name: 'شهروند', team: 'city', count: 3,
          icon: 'builtin:person', cardColor: '#37474F',
          cardFrame: 'builtin:classic', priority: 900, knownTo: [],
          description: 'با استدلال مافیاها را پیدا کن.',
          deathReveal: 'role', abilities: [],
        ),
        GrdnRole(
          id: 'mafia', name: 'مافیا', team: 'mafia', count: 1,
          icon: 'builtin:fedora', cardColor: '#B71C1C',
          cardFrame: 'builtin:classic', priority: 10,
          knownTo: ['mafia'],
          description: 'هر شب با هم‌تیمی‌ات یکی را بکش.',
          deathReveal: 'role',
          abilities: [
            GrdnAbility(
              id: 'mafia-b1', type: 'attack', name: 'کشتن', enabled: true,
              targeting: GrdnTargeting(
                count: 1, scope: 'alive', selfAllowed: false,
                sameTeamAllowed: false, repeatTarget: true, mustNotBe: [],
              ),
              timing: GrdnTiming(
                when: 'night', everyNights: 1, cooldown: 0,
                usesTotal: -1, onlyNightNumbers: [], notNightNumbers: [0],
              ),
              effect: GrdnEffect(
                resultMode: 'team', customResultText: '',
                bypassProtection: false, bypassImmunity: false,
                onBlockedResult: 'blocked',
              ),
              messages: GrdnMessages(success: '', blocked: ''),
              wakeGroup: 1,
            ),
          ],
        ),
      ],
      flow: const GrdnFlow(
        cycle: ['night', 'dawn', 'day', 'vote'],
        zeroNight: true,
        repeatFrom: 'night',
      ),
      phases: const [
        GrdnPhase(
          id: 'night', name: 'شب', kind: 'night', sound: 'builtin:wolves',
          autoWakeByPriority: true, wakeList: ['mafia*'], timer: 45,
        ),
        GrdnPhase(
          id: 'dawn', name: 'سپیده‌دم', kind: 'dawn', sound: 'builtin:rooster',
          autoWakeByPriority: false, wakeList: [], timer: 15,
        ),
        GrdnPhase(
          id: 'day', name: 'روز', kind: 'day', sound: 'builtin:bell',
          autoWakeByPriority: false, wakeList: [], timer: 120,
        ),
        GrdnPhase(
          id: 'vote', name: 'رأی‌گیری', kind: 'vote', sound: 'builtin:drum',
          autoWakeByPriority: false, wakeList: [], timer: 30,
        ),
      ],
      rules: const GrdnRules(
        firstNightKill: false,
        showTeamAtStart: true,
        deadCanSpeak: false,
        lastWords: GrdnLastWords(enabled: true, seconds: 30),
        vote: GrdnVoteRules(
          mode: 'majority', tieBreak: 'revote', abstain: true,
          showCounts: true, eliminatedReveal: 'role',
        ),
        doctor: GrdnDoctorRules(selfSave: false, sameTargetTwice: false),
        audio: GrdnAudioRules(
            phaseChange: true, death: 'builtin:gunshot'),
      ),
      winConditions: const [
        GrdnWinCondition(
          team: 'city', join: 'AND',
          terms: [GrdnTerm(left: 'aliveCount:mafia', op: '==', right: '0')],
        ),
        GrdnWinCondition(
          team: 'mafia', join: 'AND',
          terms: [GrdnTerm(left: 'aliveCount:mafia', op: '>=', right: 'aliveCount:city')],
        ),
      ],
      events: const [],
    );
  }

  GrdnScenario _withScenario(
    GrdnScenario s, {
    int? playersMin,
    int? playersMax,
    List<GrdnTeam>? teams,
    List<GrdnRole>? roles,
    List<GrdnPhase>? phases,
    List<GrdnWinCondition>? winConditions,
    bool? firstNightKill,
    bool? doctorSelfSave,
  }) {
    final rules = GrdnRules(
      firstNightKill: firstNightKill ?? s.rules.firstNightKill,
      showTeamAtStart: s.rules.showTeamAtStart,
      deadCanSpeak: s.rules.deadCanSpeak,
      lastWords: s.rules.lastWords,
      vote: s.rules.vote,
      doctor: GrdnDoctorRules(
        selfSave: doctorSelfSave ?? s.rules.doctor.selfSave,
        sameTargetTwice: s.rules.doctor.sameTargetTwice,
      ),
      audio: s.rules.audio,
    );
    return GrdnScenario(
      playersMin: playersMin ?? s.playersMin,
      playersMax: playersMax ?? s.playersMax,
      meta: s.meta,
      teams: teams ?? s.teams,
      roles: roles ?? s.roles,
      flow: s.flow,
      phases: phases ?? s.phases,
      rules: rules,
      winConditions: winConditions ?? s.winConditions,
      events: s.events,
    );
  }

  /// تعداد شهروند پرکننده = playersMin − مجموع بقیه
  void _syncFillerCount() {
    final s = state.scenario;
    if (s == null) return;
    final filler = s.fillerRole;
    if (filler == null) return;
    final others = s.roles
        .where((r) => r.id != filler.id)
        .fold(0, (sum, r) => sum + r.count);
    final needed = s.playersMin - others;
    final roles = s.roles.map((r) {
      if (r.id != filler.id) return r;
      return GrdnRole(
        id: r.id, name: r.name, team: r.team,
        count: needed.clamp(0, 20), icon: r.icon,
        cardColor: r.cardColor, cardFrame: r.cardFrame,
        priority: r.priority, knownTo: r.knownTo,
        description: r.description, deathReveal: r.deathReveal,
        abilities: r.abilities,
      );
    }).toList();
    state = state.copyWith(scenario: _withScenario(s, roles: roles));
  }

  /// wakeList شب را با نقش‌های دارای بلوک شبانه همگام می‌کند
  GrdnScenario _ensureWakeEntries(GrdnScenario s) {
    final nightPhase = s.phases
        .cast<GrdnPhase?>()
        .firstWhere((p) => p?.kind == 'night', orElse: () => null);
    if (nightPhase == null) return s;

    final list = [...nightPhase.wakeList];
    final teamsWithNight = s.roles
        .where((r) => r.count > 0 && r.hasNightAbility)
        .map((r) => r.team)
        .toSet();

    // اضافه کردن تیم‌های جدید
    for (final teamId in teamsWithNight) {
      final entry = '$teamId*';
      if (!list.contains(entry)) list.add(entry);
    }
    // حذف تیم‌هایی که دیگر بیدار نمی‌شوند
    list.retainWhere((entry) {
      if (!entry.endsWith('*')) return true;
      final teamId = entry.substring(0, entry.length - 1);
      return teamsWithNight.contains(teamId);
    });

    return _withScenario(s, phases: s.phases.map((p) {
      if (p.id != nightPhase.id) return p;
      return GrdnPhase(
        id: p.id, name: p.name, kind: p.kind, sound: p.sound,
        autoWakeByPriority: p.autoWakeByPriority, wakeList: list,
        timer: p.timer,
      );
    }).toList());
  }

  String _uniqueRoleId(GrdnScenario s, String teamId) {
    var i = 1;
    while (s.roleById('$teamId-$i') != null) {
      i++;
    }
    return '$teamId-$i';
  }

  int _nextPriority(GrdnScenario s, String teamId) {
    final same = s.roles.where((r) => r.team == teamId).toList();
    if (same.isEmpty) return 20;
    final maxP = same.map((r) => r.priority).reduce((a, b) => a > b ? a : b);
    return (maxP + 10).clamp(10, 890);
  }

  GrdnAbility _presetBlock(String id, String type) {
    return GrdnAbility(
      id: id,
      type: type,
      name: const {
        'attack': 'کشتن',
        'save': 'نجات',
        'inspect': 'بازرسی',
        'protect': 'محافظت',
      }[type]!,
      enabled: true,
      targeting: GrdnTargeting(
        count: 1,
        scope: 'alive',
        selfAllowed: type == 'save' || type == 'protect',
        sameTeamAllowed: type == 'save' || type == 'protect',
        repeatTarget: true,
        mustNotBe: const [],
      ),
      timing: GrdnTiming(
        when: 'night',
        everyNights: 1,
        cooldown: 0,
        usesTotal: -1,
        onlyNightNumbers: const [],
        notNightNumbers: const [0],
      ),
      effect: GrdnEffect(
        resultMode: type == 'inspect' ? 'team' : 'team',
        customResultText: '',
        bypassProtection: false,
        bypassImmunity: false,
        onBlockedResult: 'blocked',
      ),
      messages: const GrdnMessages(success: '', blocked: ''),
      wakeGroup: type == 'attack' ? 1 : 2,
    );
  }

  GrdnAbility _immunityBlock(String id) {
    return GrdnAbility(
      id: id,
      type: 'immunity',
      name: 'مصونیت از بازرسی',
      enabled: true,
      targeting: const GrdnTargeting(
        count: 0, scope: 'self', selfAllowed: true,
        sameTeamAllowed: true, repeatTarget: true, mustNotBe: [],
      ),
      timing: const GrdnTiming(
        when: 'night', everyNights: 1, cooldown: 0, usesTotal: -1,
        onlyNightNumbers: [], notNightNumbers: [],
      ),
      effect: const GrdnEffect(
        resultMode: 'team', customResultText: 'مافیا است',
        bypassProtection: false, bypassImmunity: false,
        onBlockedResult: 'custom',
      ),
      messages: const GrdnMessages(success: '', blocked: ''),
      wakeGroup: 0,
    );
  }

  String _iconFor(String abilityType) {
    switch (abilityType) {
      case 'attack':
        return 'builtin:knife';
      case 'save':
        return 'builtin:cross';
      case 'inspect':
        return 'builtin:magnifier';
      case 'protect':
        return 'builtin:shield';
      default:
        return 'builtin:person';
    }
  }

  String _descFor(String abilityType, String roleName) {
    switch (abilityType) {
      case 'attack':
        return 'هر شب یک نفر را حذف می‌کند.';
      case 'save':
        return 'هر شب یک نفر را از حمله نجات می‌دهد.';
      case 'inspect':
        return 'هر شب یک نفر را بازرسی می‌کند.';
      case 'protect':
        return 'هر شب یک نفر را محافظت می‌کند.';
      default:
        return 'نقش «$roleName» — با استدلال بازی کن.';
    }
  }
}

/// ورودی سبک برای کپی/ویرایش — از کتابخانه
class LightEntry {
  const LightEntry({
    required this.id,
    required this.name,
    required this.description,
    required this.author,
    required this.scenario,
  });

  final String id;
  final String name;
  final String description;
  final String author;
  final GrdnScenario scenario;
}

final builderProvider =
    StateNotifierProvider<BuilderController, BuilderState>((ref) {
  final c = BuilderController();
  c.newBlank();
  return c;
});
