/// اعتبارسنجی سناریو — طبق scenario-format.md بخش ۴
///
/// 🔴 خطا — فایل ذخیره/خروجی نمی‌شود
/// 🟡 هشدار — مجاز ولی گوشزد می‌شود
/// ⚖️ گیج ترازو — وزن تقریبی تیم‌ها (attack=3، save=2، inspect=2، protect=2، بقیه=1)
library;

import 'models/scenario.dart';

class ValidationMessage {
  const ValidationMessage(this.text, {this.hint = ''});
  final String text;
  final String hint;
}

class ValidationResult {
  const ValidationResult({
    required this.errors,
    required this.warnings,
    required this.balance,
  });

  final List<ValidationMessage> errors;
  final List<ValidationMessage> warnings;

  /// تیم id → وزن تقریبی قدرت
  final Map<String, double> balance;

  bool get isValid => errors.isEmpty;
}

class ScenarioValidator {
  const ScenarioValidator();

  static const Map<String, double> blockWeights = {
    'attack': 3,
    'save': 2,
    'inspect': 2,
    'protect': 2,
  };

  ValidationResult validate(GrdnScenario s) {
    final errors = <ValidationMessage>[];
    final warnings = <ValidationMessage>[];

    // 🔴 تیم‌ها کمتر از ۲
    if (s.teams.length < 2) {
      errors.add(const ValidationMessage('حداقل دو تیم لازم است',
          hint: 'مثلاً «شهر» و «مافیا»'));
    }

    // 🔴 ارجاع نقش به تیم ناموجود + id تکراری نقش‌ها + priority خارج از بازه
    final roleIds = <String>{};
    for (final r in s.roles) {
      if (roleIds.contains(r.id)) {
        errors.add(ValidationMessage('نقش تکراری: «${r.name}»',
            hint: 'id نقش‌ها باید یکتا باشد'));
      }
      roleIds.add(r.id);
      if (s.teamById(r.team) == null) {
        errors.add(ValidationMessage(
            'نقش «${r.name}» به تیم ناموجود «${r.team}» اشاره می‌کند',
            hint: 'تیم‌های موجود: ${s.teams.map((t) => t.id).join("، ")}'));
      }
      if (r.priority < 10 || r.priority > 900) {
        errors.add(ValidationMessage(
            'اولویت نقش «${r.name}» خارج از بازه ۱۰ تا ۹۰۰ است',
            hint: 'اولویت فعلی: ${r.priority}'));
      }
      // id تکراری بلوک‌ها
      final blockIds = <String>{};
      for (final b in r.abilities) {
        if (blockIds.contains(b.id)) {
          errors.add(ValidationMessage(
              'بلوک تکراری «${b.name}» در نقش «${r.name}»'));
        }
        blockIds.add(b.id);
      }
    }

    // 🔴 id تکراری تیم‌ها و فازها و رویدادها
    final teamIds = <String>{};
    for (final t in s.teams) {
      if (teamIds.contains(t.id)) {
        errors.add(ValidationMessage('تیم تکراری: «${t.name}»'));
      }
      teamIds.add(t.id);
    }
    final phaseIds = <String>{};
    for (final p in s.phases) {
      if (phaseIds.contains(p.id)) {
        errors.add(ValidationMessage('فاز تکراری: «${p.name}»'));
      }
      phaseIds.add(p.id);
    }
    final eventIds = <String>{};
    for (final e in s.events) {
      if (eventIds.contains(e.id)) {
        errors.add(ValidationMessage('رویداد تکراری: «${e.name}»'));
      }
      eventIds.add(e.id);
    }

    // 🔴 مجموع کارت‌ها خارج از بازه بازیکن‌ها
    if (s.totalCards < s.playersMin || s.totalCards > s.playersMax) {
      errors.add(ValidationMessage(
          'مجموع تعداد نقش‌ها (${s.totalCards}) خارج از بازه بازیکن‌ها (${s.playersMin} تا ${s.playersMax}) است',
          hint: 'مثلاً برای بازی ۸ نفره مجموع کارت‌ها باید ۸ باشد یا نقش پرکننده داشته باشید'));
    }

    // 🔴 بلوک شبانه بدون جایگاه در wakeList فاز شب
    final nightPhase = s.phases.cast<GrdnPhase?>().firstWhere(
          (p) => p?.kind == 'night',
          orElse: () => null,
        );
    if (nightPhase != null) {
      for (final r in s.roles) {
        final hasNightBlock =
            r.abilities.any((b) => b.enabled && b.timing.when == 'night');
        if (!hasNightBlock) continue;
        final listed = nightPhase.wakeList.any((w) {
          if (w.endsWith('*')) return w.substring(0, w.length - 1) == r.team;
          if (w.startsWith('team:')) return w.substring(5) == r.team;
          return w == r.id;
        });
        if (!listed) {
          errors.add(ValidationMessage(
              'نقش «${r.name}» بلوک شبانه دارد ولی در لیست بیداری شب نیست',
              hint: 'در فاز شب، wakeList را کامل کنید'));
        }
      }
    }

    // 🔴 شرط برد خالی یا برای تیم بدون عضو
    if (s.winConditions.isEmpty) {
      errors.add(const ValidationMessage('حداقل یک شرط برد لازم است',
          hint: 'از پریست‌های آماده استفاده کنید'));
    }
    for (final wc in s.winConditions) {
      final hasMember =
          s.roles.any((r) => r.team == wc.team && r.count > 0);
      if (!hasMember) {
        errors.add(ValidationMessage(
            'شرط برد برای تیم «${s.teamById(wc.team)?.name ?? wc.team}» تعریف شده ولی این تیم هیچ عضوی ندارد'));
      }
    }

    // ------------------------------------------------ هشدارها

    // 🟡 تیم بدون هیچ حمله
    for (final t in s.teams) {
      final hasAttack = s.roles.any((r) =>
          r.team == t.id &&
          r.count > 0 &&
          r.abilities.any((b) => b.enabled && b.type == 'attack'));
      if (!hasAttack) {
        warnings.add(ValidationMessage(
            'تیم «${t.name}» هیچ بلوک حمله‌ای ندارد — بردش (با حمله) ناممکن است',
            hint: 'اگر شرط برد این تیم حمله نمی‌خواهد، این هشدار را نادیده بگیرید'));
      }
    }

    // 🟡 نسبت قدرت نامتوازن
    final balance = computeBalance(s);
    final values = balance.values.where((v) => v > 0).toList();
    if (values.length >= 2) {
      final mx = values.reduce((a, b) => a > b ? a : b);
      final mn = values.reduce((a, b) => a < b ? a : b);
      if (mn > 0 && mx / mn > 2.5) {
        warnings.add(const ValidationMessage(
            'نسبت قدرت تیم‌ها نامتوازن به نظر می‌رسد (گیج ترازو را ببینید)'));
      }
    }

    // 🟡 usesTotal=1 با cooldown>0
    for (final r in s.roles) {
      for (final b in r.abilities) {
        if (b.timing.usesTotal == 1 && b.timing.cooldown > 0) {
          warnings.add(ValidationMessage(
              'بلوک «${b.name}» در نقش «${r.name}» فقط یک استفاده دارد ولی کول‌داون هم گذاشته‌اید — تناقض احتمالی'));
        }
        if (b.timing.everyNights > 1 &&
            !b.timing.notNightNumbers.contains(1) &&
            b.timing.onlyNightNumbers.isEmpty) {
          warnings.add(ValidationMessage(
              'بلوک «${b.name}» در نقش «${r.name}» یک‌شب‌درمیان است ولی شب اول در notNightNumbers تعریف نشده'));
        }
      }
    }

    return ValidationResult(
      errors: errors,
      warnings: warnings,
      balance: balance,
    );
  }

  /// گیج ترازو — وزن تقریبی هر تیم
  Map<String, double> computeBalance(GrdnScenario s) {
    final balance = <String, double>{};
    for (final t in s.teams) {
      balance[t.id] = 0;
    }
    for (final r in s.roles) {
      var w = 0.0;
      for (final b in r.abilities) {
        if (!b.enabled) continue;
        w += blockWeights[b.type] ?? 1;
      }
      // شهروند ساده وزن پایه کوچک دارد
      if (w == 0) w = 0.5;
      if (balance.containsKey(r.team)) {
        balance[r.team] = balance[r.team]! + w * r.count;
      } else {
        balance[r.team] = w * r.count;
      }
    }
    return balance;
  }
}
