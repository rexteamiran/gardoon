/// اجرای بلوک‌های توانایی — resolve صف اکشن‌های شب
///
/// طبق architecture.md بخش ۳.۳: اکشن‌ها اول در صف ثبت می‌شوند و
/// پایان شب با احترام به محافظت/مصونیت/مسدودسازی resolve می‌شوند.
library;

import 'dart:math';

import 'models/scenario.dart';
import 'models/session.dart';

/// نتیجه resolve یک شب
class NightResolution {
  NightResolution({
    required this.deaths,
    required this.blockedActions,
    required this.hostMessages,
    required this.logs,
    required this.newLovers,
    required this.newRevengeTargets,
    required this.newSilenced,
    required this.converted,
  });

  final List<String> deaths; // id بازیکن‌هایی که امشب می‌میرند
  final List<String> blockedActions; // توضیح اکشن‌های بلاک‌شده
  final List<String> hostMessages; // گزارش خصوصی گرداننده (بازرسی و...)
  final List<GameLogEntry> logs;
  final Map<String, String> newLovers;
  final Map<String, String> newRevengeTargets;
  final List<String> newSilenced; // فردا روز ساکت است
  final Map<String, String> converted; // playerId → نقش جدید
}

class ActionExecutor {
  const ActionExecutor();

  NightResolution resolve({
    required GameSessionState state,
    required List<PendingAction> actions,
    Random? random,
  }) {
    final rnd = random ?? Random.secure();
    final deaths = <String>[];
    final blockedActions = <String>[];
    final hostMessages = <String>[];
    final logs = <GameLogEntry>[];
    final newLovers = Map<String, String>.from(state.lovers);
    final newRevengeTargets = Map<String, String>.from(state.revengeTargets);
    final newSilenced = <String>[];
    final converted = <String, String>{};

    // ۱) مسدودسازی (roleblock) — اکشن‌های بازیکنِ مسدودشده حذف می‌شود
    final roleblockedIds = <String>{};
    for (final a in actions) {
      if (a.block.type == 'roleblock') {
        roleblockedIds.add(a.targetId);
      }
    }
    final effective = actions.where((a) {
      if (a.block.type == 'roleblock') return true; // خودِ بلاک اجرا می‌شود
      if (roleblockedIds.contains(a.actorId)) {
        final actor = state.playerById(a.actorId);
        blockedActions.add(
            'اکشن «${a.block.name}» ${actor?.name ?? ""} به دلیل مسدودسازی اجرا نشد');
        logs.add(GameLogEntry(
          round: state.roundNumber,
          phaseKind: 'night',
          text: 'مسدودسازی: ${actor?.name} نتوانست «${a.block.name}» را اجرا کند',
        ));
        return false;
      }
      return true;
    }).toList();

    // ۲) ثبت محافظت‌ها و صفحات — هر هدف لیست محافظت‌هایش
    final protectedIds = <String>{};
    for (final a in effective) {
      if (a.block.type == 'save' || a.block.type == 'protect') {
        protectedIds.add(a.targetId);
        logs.add(GameLogEntry(
          round: state.roundNumber,
          phaseKind: 'night',
          text: 'محافظت از ${state.playerById(a.targetId)?.name}',
        ));
      }
    }

    // ۳) مصونیت — نقش‌هایی با بلوک immunity فعال
    bool isImmune(String playerId) {
      final p = state.playerById(playerId);
      if (p == null) return false;
      final role = state.scenario.roleById(p.roleId);
      return role?.abilities
              .any((b) => b.enabled && b.type == 'immunity') ??
          false;
    }

    // ۴) عشق و انتقام — ثبت رابطه‌ها
    for (final a in effective) {
      if (a.block.type == 'loveLink') {
        newLovers[a.actorId] = a.targetId;
        newLovers[a.targetId] = a.actorId;
        logs.add(GameLogEntry(
          round: state.roundNumber,
          phaseKind: 'night',
          text: 'پیوند عشق بین ${state.playerById(a.actorId)?.name} و ${state.playerById(a.targetId)?.name}',
        ));
      }
      if (a.block.type == 'revenge') {
        newRevengeTargets[a.actorId] = a.targetId;
      }
    }

    // ۵) حمله‌ها — با احترام به محافظت
    for (final a in effective) {
      if (a.block.type != 'attack') continue;
      final target = state.playerById(a.targetId);
      if (target == null || !target.alive) continue;
      if (deaths.contains(target.id)) continue;

      if (!a.block.effect.bypassProtection && protectedIds.contains(target.id)) {
        blockedActions.add('حمله به ${target.name} به دلیل محافظت نافرماند');
        logs.add(GameLogEntry(
          round: state.roundNumber,
          phaseKind: 'night',
          text: 'حمله به ${target.name} دفع شد (محافظت)',
        ));
        continue;
      }
      deaths.add(target.id);
      logs.add(GameLogEntry(
        round: state.roundNumber,
        phaseKind: 'night',
        text: '${target.name} شبانه کشته شد',
      ));
    }

    // ۶) تبدیل تیم (convert) — هدف به تیمِ مهاجم می‌پیوندد
    for (final a in effective) {
      if (a.block.type != 'convert') continue;
      final target = state.playerById(a.targetId);
      final actor = state.playerById(a.actorId);
      if (target == null || actor == null || !target.alive) continue;
      if (deaths.contains(target.id)) continue;
      final actorRole = state.scenario.roleById(actor.roleId);
      final targetTeam = actorRole?.team ?? '';
      // اولین نقشِ تیم مقصد به‌عنوان نقش جدید هدف
      final newRole = state.scenario.roles
          .firstWhere((r) => r.team == targetTeam, orElse: () => actorRole!);
      converted[target.id] = newRole.id;
      logs.add(GameLogEntry(
        round: state.roundNumber,
        phaseKind: 'night',
        text: '${target.name} به تیم «${state.scenario.teamById(targetTeam)?.name ?? targetTeam}» پیوست',
      ));
      hostMessages.add('${target.name} جذب فرقه شد');
    }

    // ۷) بازرسی‌ها — گزارش خصوصی گرداننده
    for (final a in effective) {
      if (a.block.type != 'inspect') continue;
      final target = state.playerById(a.targetId);
      if (target == null) continue;

      if (isImmune(target.id) && !a.block.effect.bypassImmunity) {
        if (a.block.effect.onBlockedResult == 'blocked') {
          hostMessages.add(a.block.messages.blocked.isNotEmpty
              ? a.block.messages.blocked
              : 'بازرسی به نتیجه نرسید');
        } else if (a.block.effect.onBlockedResult == 'custom' &&
            a.block.effect.customResultText.isNotEmpty) {
          hostMessages.add(a.block.effect.customResultText);
        } else {
          hostMessages.add('نتیجه‌ای دریافت نشد');
        }
        logs.add(GameLogEntry(
          round: state.roundNumber,
          phaseKind: 'night',
          text: 'بازرسی ${target.name} بلاک شد (مصونیت)',
        ));
        continue;
      }

      final role = state.scenario.roleById(target.roleId);
      switch (a.block.effect.resultMode) {
        case 'exact':
          hostMessages.add('${target.name}: ${role?.name ?? "نامشخص"}');
          break;
        case 'custom':
          hostMessages.add(a.block.effect.customResultText.isNotEmpty
              ? a.block.effect.customResultText
              : '${target.name}: ${role?.name ?? ""}');
          break;
        default: // team
          final teamName =
              state.scenario.teamById(role?.team ?? '')?.name ?? '';
          hostMessages.add('${target.name}: تیم «$teamName»');
      }
      logs.add(GameLogEntry(
        round: state.roundNumber,
        phaseKind: 'night',
        text: 'بازرسی ${target.name} انجام شد',
      ));
    }

    // ۸) سکوت — فردا روز حق حرف ندارد
    for (final a in effective) {
      if (a.block.type == 'silence') {
        final target = state.playerById(a.targetId);
        if (target != null && target.alive) {
          newSilenced.add(target.id);
          logs.add(GameLogEntry(
            round: state.roundNumber,
            phaseKind: 'night',
            text: '${target.name} فردا ساکت است',
          ));
        }
      }
    }

    // ۹) زنجیره مرگ — پیوند عشق و انتقام
    final processed = <String>{...deaths};
    var grew = true;
    while (grew) {
      grew = false;
      for (final dead in List<String>.from(processed)) {
        // پیوند عشق
        final lover = newLovers[dead];
        if (lover != null && !processed.contains(lover)) {
          final lp = state.playerById(lover);
          if (lp != null && lp.alive) {
            processed.add(lover);
            hostMessages.add('${lp.name} از غم عشق از دست رفت 💔');
            logs.add(GameLogEntry(
              round: state.roundNumber,
              phaseKind: 'night',
              text: '${lp.name} به دلیل پیوند عشق مرد',
            ));
            grew = true;
          }
        }
        // انتقام
        final revenge = newRevengeTargets[dead];
        if (revenge != null && !processed.contains(revenge)) {
          final rp = state.playerById(revenge);
          if (rp != null && rp.alive) {
            processed.add(revenge);
            hostMessages.add('${rp.name} به دلیل انتقام از دست رفت');
            logs.add(GameLogEntry(
              round: state.roundNumber,
              phaseKind: 'night',
              text: '${rp.name} به دلیل انتقام مرد',
            ));
            grew = true;
          }
        }
      }
    }
    deaths
      ..clear()
      ..addAll(processed);

    // رویداد «دوقتله» — doubleAttack (سطح ۴، ساده‌شده): قربانی دوم تصادفی از زنده‌ها
    final event = state.activeEvent;
    if (event != null) {
      final ev = state.scenario.events
          .where((e) => e.id == event)
          .cast<GrdnEvent?>()
          .firstWhere((e) => e != null, orElse: () => null);
      if (ev != null && (ev.effects['doubleAttack'] ?? false)) {
        final alive = state.players
            .where((p) => p.alive && !processed.contains(p.id))
            .toList()
          ..shuffle(rnd);
        if (alive.isNotEmpty) {
          processed.add(alive.first.id);
          hostMessages.add('رویداد «${ev.name}»: ${alive.first.name} هم از دست رفت');
        }
      }
    }

    return NightResolution(
      deaths: deaths.toList(),
      blockedActions: blockedActions,
      hostMessages: hostMessages,
      logs: logs,
      newLovers: newLovers,
      newRevengeTargets: newRevengeTargets,
      newSilenced: newSilenced,
      converted: converted,
    );
  }
}
