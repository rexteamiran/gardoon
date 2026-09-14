/// صفحه اصلی گرداننده — شب/سپیده‌دم/روز/رأی‌گیری/پایان (design.md ۶.۳-۳)
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/fa_numbers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../engine/models/scenario.dart';
import '../providers/table_controller.dart';

class HostScreen extends ConsumerWidget {
  const HostScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final table = ref.watch(tableProvider);
    final session = table.session;

    if (session == null || table.stage == TableStage.setup) {
      // مستقیم آمده — به راه‌اندازی برگرد
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).popUntil((r) => r.isFirst);
      });
      return const SizedBox.shrink();
    }

    if (session.finished) {
      return const _FinishPanel();
    }

    switch (session.phaseKind) {
      case 'night':
        return const _NightPanel();
      case 'dawn':
        return const _DawnPanel();
      case 'day':
        return const _DayPanel();
      case 'vote':
        return const _VotePanel();
      default:
        return const _DayPanel();
    }
  }
}

/// ------------------------------------------------------------- شب

class _NightPanel extends ConsumerWidget {
  const _NightPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final table = ref.watch(tableProvider);
    final session = table.session!;
    final controller = ref.read(tableProvider.notifier);
    final colors = AppColors.of(context);
    final step = controller.currentStep;
    final event = session.activeEvent != null
        ? session.scenario.events
            .cast<GrdnEvent?>()
            .firstWhere((e) => e?.id == session.activeEvent, orElse: () => null)
        : null;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PhaseHeader(
              icon: '🌙',
              title: 'شب ${session.roundNumber.fa}',
              subtitle: 'سناریو: ${table.entry?.name ?? ""}',
              color: const Color(0xFF3949AB),
              trailing: event != null
                  ? Tooltip(
                      message: event.description,
                      child: Chip(
                        avatar: const Text('🎲'),
                        label: Text(event.name,
                            style: const TextStyle(fontSize: 12)),
                        backgroundColor: colors.surface3,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            if (step != null) ...[
              // کارت دستور فعلی
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GooeyCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('الان: ${step.title}',
                          style: TextStyle(
                              color: colors.text,
                              fontSize: 19,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                        'بلوک: ${step.blocks.map((b) => b.name).join("، ")} — هدف را انتخاب کنید',
                        style:
                            TextStyle(color: colors.subtext, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // ردیف بازیکن‌ها — انتخاب هدف
              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.5,
                  children: [
                    for (final p in session.players.where((p) => p.alive))
                      PlayerChip(
                        name: p.name,
                        alive: true,
                        onTap: () => controller.submitNightAction(p.id),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: OutlinedButton.icon(
                  onPressed: controller.skipWakeStep,
                  icon: const Icon(Icons.skip_next),
                  label: const Text('رد کردن این گام'),
                ),
              ),
            ] else ...[
              // همه گام‌ها تمام شد
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🌗', style: TextStyle(fontSize: 64, color: colors.primary)),
                      const SizedBox(height: 16),
                      Text('شب تمام شد',
                          style: TextStyle(
                              color: colors.text,
                              fontSize: 22,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text('چرخش گردونه… 🎡',
                          style: TextStyle(color: colors.subtext, fontSize: 14)),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: GooeyButton(
                  label: 'به سپیده‌دم برو',
                  icon: Icons.wb_twilight,
                  onPressed: controller.nextPhase,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------- سپیده‌دم

class _DawnPanel extends ConsumerWidget {
  const _DawnPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(tableProvider).session!;
    final controller = ref.read(tableProvider.notifier);
    final colors = AppColors.of(context);

    final hideResults = session.activeEvent != null &&
        session.scenario.events
            .where((e) => e.id == session.activeEvent)
            .any((e) => e.effects['hideDawnResults'] == true);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PhaseHeader(
              icon: '🌅',
              title: 'سپیده‌دم ${session.roundNumber.fa}',
              subtitle: 'اعلام نتایج شب',
              color: const Color(0xFFEF6C00),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (hideResults)
                    GooeyCard(
                      child: Text(
                        '🎲 رویداد فعال: امشب هیچ نتیجه‌ای اعلام نمی‌شود',
                        style: TextStyle(color: colors.text, fontSize: 15),
                      ),
                    )
                  else if (session.lastDawnDeaths.isEmpty)
                    GooeyCard(
                      child: Text(
                        'شبی آرام بود — کسی از دست نرفت ✨',
                        style: TextStyle(color: colors.text, fontSize: 15),
                      ),
                    )
                  else
                    ...session.lastDawnDeaths.map((id) {
                      final p = session.playerById(id)!;
                      final role = session.scenario.roleById(p.roleId);
                      final reveal = role?.deathReveal ?? 'role';
                      final revealText = reveal == 'role'
                          ? 'نقش: ${role?.name}'
                          : reveal == 'team'
                              ? 'تیم: ${session.scenario.teamById(role?.team ?? "")?.name}'
                              : 'نقش نامشخص';
                      return GooeyCard(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            const Text('💀', style: TextStyle(fontSize: 26)),
                            const SizedBox(width: 10),
                            Text('${p.name} — $revealText',
                                style: TextStyle(
                                    color: colors.text, fontSize: 15)),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 16),
                  Text('گزارش خصوصی گرداننده:',
                      style: TextStyle(color: colors.subtext, fontSize: 12)),
                  const SizedBox(height: 8),
                  ...session.history
                      .where((l) => l.phaseKind == 'dawn' && !l.isPublic)
                      .map((l) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text('• ${l.text}',
                                style: TextStyle(
                                    color: colors.subtext, fontSize: 13)),
                          )),
                  if (session.silencedIds.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      '🤐 ساکت‌های امروز: ${session.silencedIds.map((id) => session.playerById(id)?.name).join("، ")}',
                      style: TextStyle(color: BrandColors.info, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: GooeyButton(
                label: 'شروع روز ☀️',
                onPressed: controller.nextPhase,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------- روز

class _DayPanel extends ConsumerStatefulWidget {
  const _DayPanel();

  @override
  ConsumerState<_DayPanel> createState() => _DayPanelState();
}

class _DayPanelState extends ConsumerState<_DayPanel> {
  Timer? _timer;
  int _remaining = 0;
  int _total = 120;
  bool _running = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer(int seconds) {
    _timer?.cancel();
    setState(() {
      _total = seconds;
      _remaining = seconds;
      _running = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_remaining > 0) _remaining--;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final table = ref.watch(tableProvider);
    final session = table.session!;
    final controller = ref.read(tableProvider.notifier);
    final colors = AppColors.of(context);
    final timerSeconds = session.currentPhaseDef?.timer ?? 120;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PhaseHeader(
              icon: '☀️',
              title: 'روز ${session.roundNumber.fa}',
              subtitle: 'بحث آزاد',
              color: const Color(0xFFF9A825),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (!_running) ...[
                    GooeyCard(
                      child: Column(
                        children: [
                          Text('تایمر بحث',
                              style: TextStyle(
                                  color: colors.text, fontSize: 16)),
                          const SizedBox(height: 14),
                          GooeyButton(
                            label: 'شروع تایمر (${timerSeconds.fa} ثانیه)',
                            height: 56,
                            onPressed: () => _startTimer(timerSeconds),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    GooeyCard(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: BigTimer(remaining: _remaining, total: _total),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // زنده‌ها + مرگ‌ها
                  Text('میز بازیکن‌ها:',
                      style: TextStyle(
                          color: colors.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: session.players
                        .map((p) => PlayerChip(
                              name: p.name,
                              alive: p.alive,
                              badge: p.alive
                                  ? (session.silencedIds.contains(p.id)
                                      ? '🤐'
                                      : null)
                                  : '💀',
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: GooeyButton(
                label: 'رفتن به رأی‌گیری 🗳️',
                onPressed: controller.nextPhase,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------- رأی‌گیری

class _VotePanel extends ConsumerStatefulWidget {
  const _VotePanel();

  @override
  ConsumerState<_VotePanel> createState() => _VotePanelState();
}

class _VotePanelState extends ConsumerState<_VotePanel> {
  @override
  Widget build(BuildContext context) {
    final session = ref.watch(tableProvider).session!;
    final controller = ref.read(tableProvider.notifier);
    final colors = AppColors.of(context);
    final counts = session.voteCounts;
    final totalVotes = counts.values.fold(0, (a, b) => a + b);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PhaseHeader(
              icon: '🗳️',
              title: session.isRevote
                  ? 'رأی‌گیری مجدد — گردش ${session.roundNumber.fa}'
                  : 'رأی‌گیری — گردش ${session.roundNumber.fa}',
              subtitle: 'جمع تراشه‌ای: ${totalVotes.fa} رأی',
              color: const Color(0xFF6A1B9A),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  for (final p in session.players.where((p) => p.alive))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GooeyCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(p.name,
                                  style: TextStyle(
                                      color: colors.text, fontSize: 16)),
                            ),
                            IconButton(
                              onPressed: () => controller.removeVote(p.id),
                              icon: Icon(Icons.remove_circle_outline,
                                  color: colors.subtext),
                            ),
                            Container(
                              width: 44,
                              alignment: Alignment.center,
                              child: Text(
                                '${counts[p.id] ?? 0}'.fa,
                                style: TextStyle(
                                    color: colors.text,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                            IconButton(
                              onPressed: () => controller.castVote(p.id),
                              icon: Icon(Icons.add_circle,
                                  color: colors.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (totalVotes > 0)
                    TextButton(
                      onPressed: controller.clearVotes,
                      child: Text('صفر کردن همه رأی‌ها',
                          style: TextStyle(color: colors.subtext)),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: GooeyButton(
                label: 'پایان رأی‌گیری — اعلام نتیجه',
                onPressed: controller.finalizeVote,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------- پایان

class _FinishPanel extends ConsumerWidget {
  const _FinishPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(tableProvider).session!;
    final controller = ref.read(tableProvider.notifier);
    final colors = AppColors.of(context);

    final winners = session.winnerTeamIds
        .map((id) => session.scenario.teamById(id))
        .whereType<GrdnTeam>()
        .toList();

    Color winnerColor = BrandColors.gold;
    if (winners.isNotEmpty) {
      final hex = winners.first.color;
      winnerColor = Color(int.parse(hex.replaceFirst('#', '0xFF')));
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),
            // موج طلایی برد
            AnimatedContainer(
              duration: const Duration(seconds: 2),
              curve: Curves.easeOutBack,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: winnerColor, width: 3),
                boxShadow: [
                  BoxShadow(
                      color: winnerColor.withValues(alpha: 0.4),
                      blurRadius: 40),
                ],
              ),
              child: Column(
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 10),
                  Text(
                    'برنده: ${winners.map((w) => w.name).join(" و ")}',
                    style: TextStyle(
                        color: winnerColor,
                        fontSize: 26,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  Text('لاگ گردش‌ها:',
                      style: TextStyle(
                          color: colors.subtext,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ...session.history
                      .where((l) => l.isPublic)
                      .map((l) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text('• ${l.text}',
                                style: TextStyle(
                                    color: colors.text, fontSize: 13)),
                          )),
                  const SizedBox(height: 12),
                  Text('ترکیب نهایی میز:',
                      style: TextStyle(
                          color: colors.subtext, fontSize: 13)),
                  ...session.players.map((p) {
                    final role = session.scenario.roleById(p.roleId);
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${p.name}: ${role?.name ?? ""} ${p.alive ? "✓" : "💀"}',
                        style: TextStyle(color: colors.text, fontSize: 13),
                      ),
                    );
                  }),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        controller.quit();
                        Navigator.of(context).popUntil((r) => r.isFirst);
                      },
                      child: const Text('خانه'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        controller.quit();
                      },
                      child: const Text('بازی جدید'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
