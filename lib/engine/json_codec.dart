/// تبدیل سناریو ↔ JSON (فرمت .grdn)
///
/// طبق agents.md بخش ۵: هیچ جای دیگری دستی JSON سناریو نمی‌سازد.
library;

import 'models/scenario.dart';

class GrdnJsonCodec {
  const GrdnJsonCodec();

  // ---------- encode: مدل → Map ----------

  Map<String, dynamic> encode(GrdnScenario s) => <String, dynamic>{
        'meta': s.meta.toJson(),
        'teams': s.teams.map((t) => t.toJson()).toList(),
        'roles': s.roles.map((r) => r.toJson()).toList(),
        'flow': s.flow.toJson(),
        'phases': s.phases.map((p) => p.toJson()).toList(),
        'rules': s.rules.toJson(),
        'winConditions': s.winConditions.map((w) => w.toJson()).toList(),
        'events': s.events.map((e) => e.toJson()).toList(),
      };

  // ---------- decode: Map → مدل ----------

  GrdnScenario decode(Map<String, dynamic> j,
      {int playersMin = 6, int playersMax = 15}) {
    return GrdnScenario(
      playersMin: playersMin,
      playersMax: playersMax,
      meta: GrdnMeta.fromJson(
          (j['meta'] as Map?)?.cast<String, dynamic>() ?? const {}),
      teams: ((j['teams'] as List?) ?? const [])
          .map((e) => GrdnTeam.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      roles: ((j['roles'] as List?) ?? const [])
          .map((e) => GrdnRole.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      flow: GrdnFlow.fromJson(
          (j['flow'] as Map?)?.cast<String, dynamic>() ?? const {}),
      phases: ((j['phases'] as List?) ?? const [])
          .map((e) => GrdnPhase.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      rules: GrdnRules.fromJson(
          (j['rules'] as Map?)?.cast<String, dynamic>() ?? const {}),
      winConditions: ((j['winConditions'] as List?) ?? const [])
          .map((e) =>
              GrdnWinCondition.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      events: ((j['events'] as List?) ?? const [])
          .map((e) => GrdnEvent.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}
