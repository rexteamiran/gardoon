/// مدل‌های داده فرمت `.grdn` — نسخه ۱
///
/// این کلاس‌ها تصویر دقیق `scenario-format.md` هستند.
/// تبدیل JSON ↔ مدل فقط از `json_codec.dart` انجام می‌شود.
library;

/// تنظیمات عمومی سناریو (بخش ۳.۱ فرمت)
class GrdnMeta {
  const GrdnMeta({
    required this.icon,
    required this.color,
    required this.language,
    required this.defaultTimers,
  });

  final String icon; // builtin:نام یا asset:icons/x.png
  final String color; // hex مثل #1B2A4A
  final String language; // fa
  final GrdnTimers defaultTimers;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'icon': icon,
        'color': color,
        'language': language,
        'defaultTimers': defaultTimers.toJson(),
      };

  factory GrdnMeta.fromJson(Map<String, dynamic> j) => GrdnMeta(
        icon: j['icon'] as String? ?? 'builtin:fedora',
        color: j['color'] as String? ?? '#1B2A4A',
        language: j['language'] as String? ?? 'fa',
        defaultTimers: GrdnTimers.fromJson(
            (j['defaultTimers'] as Map?)?.cast<String, dynamic>() ?? const {}),
      );

  static int asInt(dynamic v, [int fallback = 60]) =>
      v is int ? v : (v is num ? v.round() : fallback);
}

class GrdnTimers {
  const GrdnTimers({
    required this.night,
    required this.dawn,
    required this.discussion,
    required this.vote,
  });

  final int night;
  final int dawn;
  final int discussion;
  final int vote;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'night': night,
        'dawn': dawn,
        'discussion': discussion,
        'vote': vote,
      };

  factory GrdnTimers.fromJson(Map<String, dynamic> j) => GrdnTimers(
        night: GrdnMeta.asInt(j['night'], 60),
        dawn: GrdnMeta.asInt(j['dawn'], 15),
        discussion: GrdnMeta.asInt(j['discussion'], 180),
        vote: GrdnMeta.asInt(j['vote'], 30),
      );
}

/// تیم (بخش ۳.۲)
class GrdnTeam {
  const GrdnTeam({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
  });

  final String id; // lowercase-latin بدون فاصله
  final String name;
  final String color;
  final String icon;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'color': color,
        'icon': icon,
      };

  factory GrdnTeam.fromJson(Map<String, dynamic> j) => GrdnTeam(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        color: j['color'] as String? ?? '#888888',
        icon: j['icon'] as String? ?? 'builtin:person',
      );
}

/// هدف‌گیری بلوک توانایی (بخش ۳.۴)
class GrdnTargeting {
  const GrdnTargeting({
    required this.count,
    required this.scope,
    required this.selfAllowed,
    required this.sameTeamAllowed,
    required this.repeatTarget,
    required this.mustNotBe,
  });

  final int count;
  final String scope; // alive | all | team:mafia | role:doctor | dead
  final bool selfAllowed;
  final bool sameTeamAllowed;
  final bool repeatTarget;
  final List<String> mustNotBe;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'count': count,
        'scope': scope,
        'selfAllowed': selfAllowed,
        'sameTeamAllowed': sameTeamAllowed,
        'repeatTarget': repeatTarget,
        'mustNotBe': mustNotBe,
      };

  factory GrdnTargeting.fromJson(Map<String, dynamic> j) => GrdnTargeting(
        count: j['count'] is int ? j['count'] as int : 1,
        scope: j['scope'] as String? ?? 'alive',
        selfAllowed: j['selfAllowed'] as bool? ?? false,
        sameTeamAllowed: j['sameTeamAllowed'] as bool? ?? false,
        repeatTarget: j['repeatTarget'] as bool? ?? true,
        mustNotBe: (j['mustNotBe'] as List?)?.cast<String>() ?? const [],
      );
}

/// زمان‌بندی بلوک توانایی
class GrdnTiming {
  const GrdnTiming({
    required this.when,
    required this.everyNights,
    required this.cooldown,
    required this.usesTotal,
    required this.onlyNightNumbers,
    required this.notNightNumbers,
  });

  final String when; // night | day | anytime
  final int everyNights; // 2 = یک شب در میان
  final int cooldown; // بعد از استفاده چند شب غیرفعال
  final int usesTotal; // -1 = بی‌نهایت
  final List<int> onlyNightNumbers; // خالی = همه
  final List<int> notNightNumbers; // این شب‌ها غیرفعال

  Map<String, dynamic> toJson() => <String, dynamic>{
        'when': when,
        'everyNights': everyNights,
        'cooldown': cooldown,
        'usesTotal': usesTotal,
        'onlyNightNumbers': onlyNightNumbers,
        'notNightNumbers': notNightNumbers,
      };

  factory GrdnTiming.fromJson(Map<String, dynamic> j) => GrdnTiming(
        when: j['when'] as String? ?? 'night',
        everyNights: j['everyNights'] is int ? j['everyNights'] as int : 1,
        cooldown: j['cooldown'] is int ? j['cooldown'] as int : 0,
        usesTotal: j['usesTotal'] is int ? j['usesTotal'] as int : -1,
        onlyNightNumbers:
            (j['onlyNightNumbers'] as List?)?.map((e) => e as int).toList() ??
                const [],
        notNightNumbers:
            (j['notNightNumbers'] as List?)?.map((e) => e as int).toList() ??
                const [],
      );
}

/// اثر بلوک توانایی
class GrdnEffect {
  const GrdnEffect({
    required this.resultMode,
    required this.customResultText,
    required this.bypassProtection,
    required this.bypassImmunity,
    required this.onBlockedResult,
  });

  final String resultMode; // team | exact | custom
  final String customResultText;
  final bool bypassProtection; // حمله از محافظت عبور می‌کند
  final bool bypassImmunity; // بازرسی از مصونیت عبور می‌کند
  final String onBlockedResult; // blocked | noResult | custom

  Map<String, dynamic> toJson() => <String, dynamic>{
        'resultMode': resultMode,
        'customResultText': customResultText,
        'bypassProtection': bypassProtection,
        'bypassImmunity': bypassImmunity,
        'onBlockedResult': onBlockedResult,
      };

  factory GrdnEffect.fromJson(Map<String, dynamic> j) => GrdnEffect(
        resultMode: j['resultMode'] as String? ?? 'team',
        customResultText: j['customResultText'] as String? ?? '',
        bypassProtection: j['bypassProtection'] as bool? ?? false,
        bypassImmunity: j['bypassImmunity'] as bool? ?? false,
        onBlockedResult: j['onBlockedResult'] as String? ?? 'blocked',
      );
}

/// پیام‌های گرداننده برای بلوک
class GrdnMessages {
  const GrdnMessages({required this.success, required this.blocked});

  final String success;
  final String blocked;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'success': success,
        'blocked': blocked,
      };

  factory GrdnMessages.fromJson(Map<String, dynamic> j) => GrdnMessages(
        success: j['success'] as String? ?? '',
        blocked: j['blocked'] as String? ?? '',
      );
}

/// بلوک توانایی — کامل‌ترین بخش فرمت (بخش ۳.۴)
class GrdnAbility {
  const GrdnAbility({
    required this.id,
    required this.type,
    required this.name,
    required this.enabled,
    required this.targeting,
    required this.timing,
    required this.effect,
    required this.messages,
    required this.wakeGroup,
  });

  static const List<String> types = [
    'attack',
    'save',
    'inspect',
    'protect',
    'silence',
    'roleblock',
    'convert',
    'voteWeight',
    'loveLink',
    'immunity',
    'revenge',
    'reveal',
    'transfer',
    'custom',
  ];

  final String id;
  final String type; // یکی از types
  final String name;
  final bool enabled;
  final GrdnTargeting targeting;
  final GrdnTiming timing;
  final GrdnEffect effect;
  final GrdnMessages messages;
  final int wakeGroup; // هم‌گروه‌ها هم‌زمان بیدار می‌شوند

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'type': type,
        'name': name,
        'enabled': enabled,
        'targeting': targeting.toJson(),
        'timing': timing.toJson(),
        'effect': effect.toJson(),
        'messages': messages.toJson(),
        'wakeGroup': wakeGroup,
      };

  factory GrdnAbility.fromJson(Map<String, dynamic> j) => GrdnAbility(
        id: j['id'] as String,
        type: j['type'] as String,
        name: j['name'] as String? ?? '',
        enabled: j['enabled'] as bool? ?? true,
        targeting: GrdnTargeting.fromJson(
            (j['targeting'] as Map?)?.cast<String, dynamic>() ?? const {}),
        timing: GrdnTiming.fromJson(
            (j['timing'] as Map?)?.cast<String, dynamic>() ?? const {}),
        effect: GrdnEffect.fromJson(
            (j['effect'] as Map?)?.cast<String, dynamic>() ?? const {}),
        messages: GrdnMessages.fromJson(
            (j['messages'] as Map?)?.cast<String, dynamic>() ?? const {}),
        wakeGroup: j['wakeGroup'] is int ? j['wakeGroup'] as int : 1,
      );
}

/// نقش — قلب سناریو (بخش ۳.۳)
class GrdnRole {
  const GrdnRole({
    required this.id,
    required this.name,
    required this.team,
    required this.count,
    required this.icon,
    required this.cardColor,
    required this.cardFrame,
    required this.priority,
    required this.knownTo,
    required this.description,
    required this.deathReveal,
    required this.abilities,
  });

  final String id;
  final String name;
  final String team; // id تیم
  final int count; // چند کارت از این نقش
  final String icon;
  final String cardColor;
  final String cardFrame;
  final int priority; // ۱۰..۹۰۰ — جایگاه بیداری شب
  final List<String> knownTo; // team:تیم یا role:نقش
  final String description;
  final String deathReveal; // role | team | nothing
  final List<GrdnAbility> abilities;

  /// آیا این نقش شبانه بیدار می‌شود؟ (بلوک شبانه فعال دارد)
  bool get hasNightAbility => abilities
      .any((a) => a.enabled && a.timing.when == 'night' && a.type != 'immunity');

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'team': team,
        'count': count,
        'icon': icon,
        'cardColor': cardColor,
        'cardFrame': cardFrame,
        'priority': priority,
        'knownTo': knownTo,
        'description': description,
        'deathReveal': deathReveal,
        'abilities': abilities.map((a) => a.toJson()).toList(),
      };

  factory GrdnRole.fromJson(Map<String, dynamic> j) => GrdnRole(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        team: j['team'] as String,
        count: j['count'] is int ? j['count'] as int : 1,
        icon: j['icon'] as String? ?? 'builtin:person',
        cardColor: j['cardColor'] as String? ?? '#37474F',
        cardFrame: j['cardFrame'] as String? ?? 'builtin:classic',
        priority: j['priority'] is int ? j['priority'] as int : 900,
        knownTo: (j['knownTo'] as List?)?.cast<String>() ?? const [],
        description: j['description'] as String? ?? '',
        deathReveal: j['deathReveal'] as String? ?? 'role',
        abilities: ((j['abilities'] as List?) ?? const [])
            .map((e) => GrdnAbility.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );
}

/// ترتیب فازها و چرخه (بخش ۳.۵)
class GrdnFlow {
  const GrdnFlow({
    required this.cycle,
    required this.zeroNight,
    required this.repeatFrom,
  });

  final List<String> cycle; // ["night","dawn","day","vote"]
  final bool zeroNight; // شب صفر (آشنایی)
  final String repeatFrom; // چرخه از کجا تکرار شود

  Map<String, dynamic> toJson() => <String, dynamic>{
        'cycle': cycle,
        'zeroNight': zeroNight,
        'repeatFrom': repeatFrom,
      };

  factory GrdnFlow.fromJson(Map<String, dynamic> j) => GrdnFlow(
        cycle: (j['cycle'] as List?)?.cast<String>() ??
            const ['night', 'dawn', 'day', 'vote'],
        zeroNight: j['zeroNight'] as bool? ?? true,
        repeatFrom: j['repeatFrom'] as String? ?? 'night',
      );
}

/// تعریف هر فاز (بخش ۳.۶)
class GrdnPhase {
  const GrdnPhase({
    required this.id,
    required this.name,
    required this.kind,
    required this.sound,
    required this.autoWakeByPriority,
    required this.wakeList,
    required this.timer,
  });

  final String id;
  final String name;
  final String kind; // night | dawn | day | vote | custom
  final String sound;
  final bool autoWakeByPriority;
  final List<String> wakeList; // "mafia*" یعنی همه نقش‌های تیم مافیا یکجا
  final int timer; // ثانیه

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'kind': kind,
        'sound': sound,
        'autoWakeByPriority': autoWakeByPriority,
        'wakeList': wakeList,
        'timer': timer,
      };

  factory GrdnPhase.fromJson(Map<String, dynamic> j) => GrdnPhase(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        kind: j['kind'] as String? ?? 'day',
        sound: j['sound'] as String? ?? '',
        autoWakeByPriority: j['autoWakeByPriority'] as bool? ?? true,
        wakeList: (j['wakeList'] as List?)?.cast<String>() ?? const [],
        timer: j['timer'] is int ? j['timer'] as int : 60,
      );
}

/// قوانین کلی بازی (بخش ۳.۷)
class GrdnRules {
  const GrdnRules({
    required this.firstNightKill,
    required this.showTeamAtStart,
    required this.deadCanSpeak,
    required this.lastWords,
    required this.vote,
    required this.doctor,
    required this.audio,
  });

  final bool firstNightKill;
  final bool showTeamAtStart;
  final bool deadCanSpeak;
  final GrdnLastWords lastWords;
  final GrdnVoteRules vote;
  final GrdnDoctorRules doctor;
  final GrdnAudioRules audio;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'firstNightKill': firstNightKill,
        'showTeamAtStart': showTeamAtStart,
        'deadCanSpeak': deadCanSpeak,
        'lastWords': lastWords.toJson(),
        'vote': vote.toJson(),
        'doctor': doctor.toJson(),
        'audio': audio.toJson(),
      };

  factory GrdnRules.fromJson(Map<String, dynamic> j) => GrdnRules(
        firstNightKill: j['firstNightKill'] as bool? ?? false,
        showTeamAtStart: j['showTeamAtStart'] as bool? ?? true,
        deadCanSpeak: j['deadCanSpeak'] as bool? ?? false,
        lastWords: GrdnLastWords.fromJson(
            (j['lastWords'] as Map?)?.cast<String, dynamic>() ?? const {}),
        vote: GrdnVoteRules.fromJson(
            (j['vote'] as Map?)?.cast<String, dynamic>() ?? const {}),
        doctor: GrdnDoctorRules.fromJson(
            (j['doctor'] as Map?)?.cast<String, dynamic>() ?? const {}),
        audio: GrdnAudioRules.fromJson(
            (j['audio'] as Map?)?.cast<String, dynamic>() ?? const {}),
      );
}

class GrdnLastWords {
  const GrdnLastWords({required this.enabled, required this.seconds});

  final bool enabled;
  final int seconds;

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'enabled': enabled, 'seconds': seconds};

  factory GrdnLastWords.fromJson(Map<String, dynamic> j) => GrdnLastWords(
        enabled: j['enabled'] as bool? ?? true,
        seconds: GrdnMeta.asInt(j['seconds'], 30),
      );
}

class GrdnVoteRules {
  const GrdnVoteRules({
    required this.mode,
    required this.tieBreak,
    required this.abstain,
    required this.showCounts,
    required this.eliminatedReveal,
  });

  final String mode; // majority
  final String tieBreak; // revote | random | none
  final bool abstain;
  final bool showCounts;
  final String eliminatedReveal; // role | team | nothing

  Map<String, dynamic> toJson() => <String, dynamic>{
        'mode': mode,
        'tieBreak': tieBreak,
        'abstain': abstain,
        'showCounts': showCounts,
        'eliminatedReveal': eliminatedReveal,
      };

  factory GrdnVoteRules.fromJson(Map<String, dynamic> j) => GrdnVoteRules(
        mode: j['mode'] as String? ?? 'majority',
        tieBreak: j['tieBreak'] as String? ?? 'revote',
        abstain: j['abstain'] as bool? ?? true,
        showCounts: j['showCounts'] as bool? ?? true,
        eliminatedReveal: j['eliminatedReveal'] as String? ?? 'role',
      );
}

class GrdnDoctorRules {
  const GrdnDoctorRules({required this.selfSave, required this.sameTargetTwice});

  final bool selfSave;
  final bool sameTargetTwice;

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'selfSave': selfSave, 'sameTargetTwice': sameTargetTwice};

  factory GrdnDoctorRules.fromJson(Map<String, dynamic> j) => GrdnDoctorRules(
        selfSave: j['selfSave'] as bool? ?? false,
        sameTargetTwice: j['sameTargetTwice'] as bool? ?? false,
      );
}

class GrdnAudioRules {
  const GrdnAudioRules({required this.phaseChange, required this.death});

  final bool phaseChange;
  final String death; // builtin:gunshot و...

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'phaseChange': phaseChange, 'death': death};

  factory GrdnAudioRules.fromJson(Map<String, dynamic> j) => GrdnAudioRules(
        phaseChange: j['phaseChange'] as bool? ?? true,
        death: j['death'] as String? ?? 'builtin:gunshot',
      );
}

/// یک جمله شرط برد (بخش ۳.۸)
class GrdnTerm {
  const GrdnTerm({required this.left, required this.op, required this.right});

  final String left; // aliveCount:تیم | aliveCount:role:نقش | aliveTotal | round | عدد
  final String op; // == != > < >= <=
  final String right;

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'left': left, 'op': op, 'right': right};

  factory GrdnTerm.fromJson(Map<String, dynamic> j) => GrdnTerm(
        left: j['left'] as String,
        op: j['op'] as String? ?? '==',
        right: j['right'] as String,
      );
}

/// شرط برد یک تیم
class GrdnWinCondition {
  const GrdnWinCondition({
    required this.team,
    required this.join,
    required this.terms,
  });

  final String team;
  final String join; // AND | OR
  final List<GrdnTerm> terms;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'team': team,
        'join': join,
        'terms': terms.map((t) => t.toJson()).toList(),
      };

  factory GrdnWinCondition.fromJson(Map<String, dynamic> j) =>
      GrdnWinCondition(
        team: j['team'] as String,
        join: j['join'] as String? ?? 'AND',
        terms: ((j['terms'] as List?) ?? const [])
            .map((e) => GrdnTerm.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );
}

/// رویدادهای تصادفی — سطح ۴ (بخش ۳.۹)
class GrdnEvent {
  const GrdnEvent({
    required this.id,
    required this.name,
    required this.description,
    required this.weight,
    required this.frequency,
    required this.effects,
    required this.sound,
  });

  final String id;
  final String name;
  final String description;
  final int weight;
  final GrdnEventFrequency frequency;
  final Map<String, bool> effects; // hideDawnResults, silenceOneRandom, ...
  final String sound;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'description': description,
        'weight': weight,
        'frequency': frequency.toJson(),
        'effects': effects,
        'sound': sound,
      };

  factory GrdnEvent.fromJson(Map<String, dynamic> j) => GrdnEvent(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        description: j['description'] as String? ?? '',
        weight: j['weight'] is int ? j['weight'] as int : 1,
        frequency: GrdnEventFrequency.fromJson(
            (j['frequency'] as Map?)?.cast<String, dynamic>() ?? const {}),
        effects: ((j['effects'] as Map?)?.cast<String, dynamic>() ?? const {})
            .map((k, v) => MapEntry(k, v == true)),
        sound: j['sound'] as String? ?? '',
      );
}

class GrdnEventFrequency {
  const GrdnEventFrequency({
    required this.fromRound,
    required this.everyRounds,
    required this.maxPerGame,
  });

  final int fromRound;
  final int everyRounds;
  final int maxPerGame;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'fromRound': fromRound,
        'everyRounds': everyRounds,
        'maxPerGame': maxPerGame,
      };

  factory GrdnEventFrequency.fromJson(Map<String, dynamic> j) =>
      GrdnEventFrequency(
        fromRound: GrdnMeta.asInt(j['fromRound'], 1),
        everyRounds: GrdnMeta.asInt(j['everyRounds'], 1),
        maxPerGame: GrdnMeta.asInt(j['maxPerGame'], 1),
      );
}

/// سناریوی کامل — معادل `data.grdn.json`
class GrdnScenario {
  const GrdnScenario({
    required this.playersMin,
    required this.playersMax,
    required this.meta,
    required this.teams,
    required this.roles,
    required this.flow,
    required this.phases,
    required this.rules,
    required this.winConditions,
    required this.events,
  });

  // playersMin/Max در فایل داخل manifest.grdn.json زندگی می‌کنند
  // ولی در مدل اپ کنار سناریو می‌آیند.
  final int playersMin;
  final int playersMax;
  final GrdnMeta meta;
  final List<GrdnTeam> teams;
  final List<GrdnRole> roles;
  final GrdnFlow flow;
  final List<GrdnPhase> phases;
  final GrdnRules rules;
  final List<GrdnWinCondition> winConditions;
  final List<GrdnEvent> events;

  GrdnTeam? teamById(String id) {
    for (final t in teams) {
      if (t.id == id) return t;
    }
    return null;
  }

  GrdnRole? roleById(String id) {
    for (final r in roles) {
      if (r.id == id) return r;
    }
    return null;
  }

  GrdnPhase? phaseById(String id) {
    for (final p in phases) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// نقش «پرکننده» — شهروند ساده بدون بلوک؛ باقی‌مانده بازیکن‌ها این نقش را می‌گیرند
  GrdnRole? get fillerRole {
    GrdnRole? best;
    for (final r in roles) {
      if (r.abilities.isEmpty) {
        if (best == null || r.priority > best.priority) best = r;
      }
    }
    return best;
  }

  /// مجموع کارت‌های تعریف‌شده
  int get totalCards => roles.fold(0, (s, r) => s + r.count);
}
