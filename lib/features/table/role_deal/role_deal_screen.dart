/// نقش‌کشه — «گوشی را بده به علی» → کارت flip → مخفی کن (design.md ۶.۳-۲)
library;

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

    final playerName =
        table.playerNames[table.dealIndex.clamp(0, table.playerNames.length - 1)];
    final player = session.players.firstWhere((p) => p.name == playerName);
    final role = session.scenario.roleById(player.roleId);
    final team = session.scenario.teamById(role?.team ?? '');
    final hidden = table.entry!.locked; // سناریوی سورپرایز

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                table.cardFlipped
                    ? '$playerName — کارتت را مخفی کن'
                    : 'گوشی را بده به $playerName',
                style: TextStyle(
                    color: colors.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w700),
              ),
              Text(
                'بازیکن ${table.dealIndex == 0 ? "اول" : (table.dealIndex + 1).fa} از ${table.playerNames.length.fa}',
                style: TextStyle(color: colors.subtext, fontSize: 13),
              ),
              const Spacer(),
              // کارت گویی — flip سه‌بعدی
              GestureDetector(
                onTap: table.cardFlipped ? null : () => ref.read(tableProvider.notifier).flipCard(),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  switchInCurve: Curves.easeOutBack,
                  transitionBuilder: (child, anim) => RotationYTransition(
                    turns: anim,
                    child: child,
                  ),
                  child: table.cardFlipped
                      ? _RoleCard(
                          key: const ValueKey('front'),
                          roleName: hidden ? '؟؟؟' : (role?.name ?? ''),
                          icon: hidden ? '🎁' : iconGlyph(role?.icon ?? ''),
                          teamName: hidden ? 'مخفی' : (team?.name ?? ''),
                          teamColor: _teamColor(hidden ? '' : (team?.id ?? '')),
                          description:
                              hidden ? 'نقشت هنگام بازی فاش می‌شود 🎡' : (role?.description ?? ''),
                        )
                      : _CardBack(key: const ValueKey('back'), onTap: () {}),
                ),
              ),
              const Spacer(),
              if (table.cardFlipped)
                GooeyButton(
                  label: 'دیدم، مخفی کن',
                  onPressed: () {
                    ref.read(tableProvider.notifier).nextDeal();
                    if (table.dealIndex + 1 >= table.playerNames.length) {
                      context.go('/table/play');
                    }
                  },
                )
              else
                Text(
                  'برای باز کردن کارت لمس کن',
                  style: TextStyle(color: colors.subtext, fontSize: 14),
                ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go('/table/play'),
                child: Text(
                  'رد کردن نقش‌کشه (گرداننده بازیکن‌ها را خودش توزیع کرده)',
                  style: TextStyle(color: colors.subtext, fontSize: 12),
                ),
              ),
            ],
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
  const _CardBack({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      width: 220,
      height: 320,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.primary, width: 3),
        boxShadow: [
          BoxShadow(
              color: colors.primary.withValues(alpha: 0.25), blurRadius: 30),
        ],
      ),
      child: Center(
        child: Text('🎡', style: TextStyle(fontSize: 64, color: colors.primary)),
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
      width: 220,
      height: 320,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: teamColor, width: 3),
        boxShadow: [
          BoxShadow(
              color: teamColor.withValues(alpha: 0.3), blurRadius: 30),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 14),
          Text(roleName,
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
            style: TextStyle(color: colors.subtext, fontSize: 13, height: 1.6),
          ),
        ],
      ),
    );
  }
}

/// چرخش سه‌بعدی کارت
class RotationYTransition extends StatelessWidget {
  const RotationYTransition({super.key, required this.turns, required this.child});

  final Animation<double> turns;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: turns,
      builder: (context, _) {
        final angle = turns.value * 3.14159;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          child: child,
        );
      },
    );
  }
}
