/// نقش‌کشه — «گوشی را بده به علی» → کارت flip → مخفی کن (design.md ۶.۳-۲)
///
/// نکته فلیپ: هر نیمه فقط تا ±۹۰° می‌چرخد تا محتوا هرگز آینه نشود.
/// نیمه اول: پشت کارت ۰→+۹۰° (لبه‌به‌چشم) — نیمه دوم: روی کارت −۹۰°→۰.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants.dart';
import '../../../core/extensions/fa_numbers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../providers/table_controller.dart';

class RoleDealScreen extends ConsumerWidget {
  const RoleDealScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final table = ref.watch(tableProvider);
    final session = table.session;
    final colors = AppColors.of(context);

    if (session == null || table.stage == TableStage.setup) {
      // مستقیم آمده — برگشت به راه‌اندازی
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/table/setup');
      });
      return const SizedBox.shrink();
    }
    if (table.stage == TableStage.play) {
      // نقش‌کشه تمام شده — برگشت به میزگرد
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/table/play');
      });
      return const SizedBox.shrink();
    }

    // بازیکنِ نوبت — با شماره ردیف، نه تطبیق اسم (مقاوم به اسم تکراری)
    final idx = table.dealIndex.clamp(0, session.players.length - 1);
    final player = session.players[idx];
    final playerName = player.name;
    final role = session.scenario.roleById(player.roleId);
    final team = session.scenario.teamById(role?.team ?? '');
    final hidden = table.entry!.locked; // سناریوی سورپرایز
    final total = table.playerNames.length;

    return Scaffold(
      backgroundColor: colors.bg,
      body: Container(
        // پس‌زمینه با عمق — گرادیان ملایم به رنگ تیم
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors.bg,
              colors.bg,
              (hidden ? BrandColors.gold : _teamColor(team?.id ?? ''))
                  .withValues(alpha: 0.07),
            ],
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // نوار پیشرفت نقش‌کشه
                Row(
                  children: [
                    for (var i = 0; i < total; i++) ...[
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: i <= idx
                                ? colors.primary
                                : colors.subtext.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      if (i < total - 1) const SizedBox(width: 4),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  table.cardFlipped
                      ? '$playerName — کارتت را مخفی کن'
                      : 'گوشی را بده به $playerName',
                  style: TextStyle(
                      color: colors.text,
                      fontSize: 20,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'بازیکن ${idx == 0 ? "اول" : (idx + 1).fa} از ${total.fa}',
                  style: TextStyle(color: colors.subtext, fontSize: 13),
                ),
                const Spacer(),
                // کارت گویی — flip سه‌بعدی بدون آینه
                GestureDetector(
                  onTap:
                      table.cardFlipped ? null : () => ref.read(tableProvider.notifier).flipCard(),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, anim) {
                      final isFront = child.key == const ValueKey('front');
                      // هر دو حالت در بازهٔ ±۹۰° می‌مانند → متن هرگز برعکس نمی‌شود
                      final t = isFront ? anim.value : 1 - anim.value;
                      final angle = (t - 0.5) * math.pi; // −۹۰° تا +۹۰°
                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(angle),
                        child: child,
                      );
                    },
                    child: table.cardFlipped
                        ? _RoleCard(
                            key: const ValueKey('front'),
                            roleName:
                                hidden ? '؟؟؟' : (role?.name ?? ''),
                            icon: hidden ? '🎁' : iconGlyph(role?.icon ?? ''),
                            teamName:
                                hidden ? 'مخفی' : (team?.name ?? ''),
                            teamColor: _teamColor(
                                hidden ? '' : (team?.id ?? '')),
                            description: hidden
                                ? 'نقشت هنگام بازی فاش می‌شود 🎡'
                                : (role?.description ?? ''),
                          )
                        : _CardBack(key: const ValueKey('back')),
                  ),
                ),
                const Spacer(),
                if (table.cardFlipped)
                  GooeyButton(
                    label: idx + 1 >= total
                        ? 'دیدم — بریم میزگرد 🎡'
                        : 'دیدم، مخفی کن',
                    onPressed: () {
                      final wasLast =
                          table.dealIndex + 1 >= table.playerNames.length;
                      ref.read(tableProvider.notifier).nextDeal();
                      if (wasLast && context.mounted) {
                        context.pushReplacement('/table/play');
                      }
                    },
                  )
                else ...[
                  Text(
                    'برای باز کردن کارت لمس کن',
                    style: TextStyle(color: colors.subtext, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.pushReplacement('/table/play'),
                  child: Text(
                    'رد کردن نقش‌کشه (گرداننده بازیکن‌ها را خودش توزیع کرده)',
                    style: TextStyle(color: colors.subtext, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _teamColor(String teamId) {
    switch (teamId) {
      case 'mafia':
        return BrandColors.mafia;
      case 'city':
        return BrandColors.city;
      case 'cult':
        return BrandColors.cult;
      default:
        return BrandColors.info;
    }
  }
}

class _CardBack extends StatelessWidget {
  const _CardBack({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      width: 230,
      height: 330,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            colors.primary.withValues(alpha: 0.16),
            colors.surface,
          ],
        ),
        border: Border.all(color: colors.primary, width: 3),
        boxShadow: [
          BoxShadow(
              color: colors.primary.withValues(alpha: 0.25), blurRadius: 30),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎡', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 14),
          Text(
            'گردون',
            style: TextStyle(
              color: colors.primary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    super.key,
    required this.roleName,
    required this.icon,
    required this.teamName,
    required this.teamColor,
    required this.description,
  });

  final String roleName;
  final String icon;
  final String teamName;
  final Color teamColor;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      width: 230,
      height: 330,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colors.surface,
            Color.lerp(colors.surface, teamColor, 0.10)!,
          ],
        ),
        border: Border.all(color: teamColor, width: 3),
        boxShadow: [
          BoxShadow(
              color: teamColor.withValues(alpha: 0.3), blurRadius: 30),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: teamColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(icon, style: const TextStyle(fontSize: 48)),
          ),
          const SizedBox(height: 14),
          Text(roleName,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: colors.text,
                  fontSize: 26,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: teamColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('تیم $teamName',
                style: TextStyle(color: teamColor, fontSize: 13)),
          ),
          const SizedBox(height: 14),
          Text(
            description,
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.subtext, fontSize: 13, height: 1.6),
          ),
        ],
      ),
    );
  }
}
