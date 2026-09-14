/// سناریوساز سطح ۱ — تب‌ها: نقش‌ها | شب | روز | شرط برد (design.md ۶.۴)
/// نوار پایین مشترک: ⚖️ ترازو | 🔴 خطا/🟡 هشدار | 💾 ذخیره | 📤 خروجی .grdn
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants.dart';
import '../../../core/extensions/fa_numbers.dart';
import '../../../core/premium_gate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/scenario_store.dart';
import '../../../engine/models/scenario.dart';
import '../../../engine/validator.dart';
import '../../../grdn/share.dart';
import 'builder_controller.dart';

class BuilderScreen extends ConsumerStatefulWidget {
  const BuilderScreen({super.key, this.fromCopyId});

  final String? fromCopyId;

  @override
  ConsumerState<BuilderScreen> createState() => _BuilderScreenState();
}

class _BuilderScreenState extends ConsumerState<BuilderScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 4, vsync: this);
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ref.read(builderProvider.notifier);
      final library = ref.read(scenarioLibraryProvider).valueOrNull;
      final copyId = widget.fromCopyId;
      if (copyId != null) {
        final entry = library
            ?.where((e) => e.scenarioId == copyId)
            .firstOrNull;
        if (entry != null) {
          controller.fromCopy(LightEntry(
            id: entry.scenarioId,
            name: entry.name,
            description: entry.description,
            author: entry.author,
            scenario: entry.scenario,
          ));
          return;
        }
      }
      // درخواست ویرایش از لیست
      final editId = ref.read(editTargetProvider);
      if (editId != null) {
        final entry = library
            ?.where((e) => e.scenarioId == editId)
            .firstOrNull;
        if (entry != null) {
          controller.loadForEdit(LightEntry(
            id: entry.scenarioId,
            name: entry.name,
            description: entry.description,
            author: entry.author,
            scenario: entry.scenario,
          ));
        }
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(builderProvider);
    final controller = ref.read(builderProvider.notifier);
    final colors = AppColors.of(context);
    final s = state.scenario;

    if (s == null) return const SizedBox.shrink();

    final result = controller.validate(s);

    return Scaffold(
      appBar: AppBar(
        title: Text(state.name.isEmpty ? 'سناریوی جدید' : state.name),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          labelColor: colors.primary,
          unselectedLabelColor: colors.subtext,
          indicatorColor: colors.primary,
          tabs: const [
            Tab(text: 'نقش‌ها'),
            Tab(text: 'شب'),
            Tab(text: 'روز'),
            Tab(text: 'شرط برد'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _RolesTab(state: state, controller: controller),
                _NightTab(state: state, controller: controller),
                _DayTab(state: state, controller: controller),
                _WinTab(state: state, controller: controller),
              ],
            ),
          ),
          // پنل اعتبارسنجی زنده
          _ValidationPanel(result: result),
          // نوار پایین مشترک
          _BottomBar(
            onBalance: () => _showBalance(context, result),
            onSave: result.isValid && state.name.trim().isNotEmpty
                ? () => _save(controller)
                : null,
            onShare: result.isValid && state.name.trim().isNotEmpty
                ? () => _share(controller)
                : null,
          ),
        ],
      ),
    );
  }

  Future<void> _save(BuilderController controller) async {
    final state = ref.read(builderProvider);
    final entry = await const ScenarioStore().save(
      scenario: state.scenario!,
      name: state.name.trim(),
      description: state.description.trim(),
      author: state.author.trim().isEmpty ? 'گرداننده' : state.author.trim(),
      scenarioId: state.scenarioId,
    );
    ref.invalidate(scenarioLibraryProvider);
    if (!mounted) return;
    // ذخیرهٔ تازه = سناریو با id جدید ادامه پیدا کند
    if (state.scenarioId == null) {
      ref.read(editTargetProvider.notifier).state = entry.scenarioId;
    }
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سناریو در کتابخانه ذخیره شد ✓')));
  }

  Future<void> _share(BuilderController controller) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final state = ref.read(builderProvider);
      await const GrdnShare().shareFile(
        bytes: await const ScenarioStore()
            .save(
              scenario: state.scenario!,
              name: state.name.trim(),
              description: state.description.trim(),
              author: state.author.trim().isEmpty
                  ? 'گرداننده'
                  : state.author.trim(),
              scenarioId: state.scenarioId,
            )
            .then((e) => e.bytes),
        scenarioName: state.name.trim(),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  void _showBalance(BuildContext context, ValidationResult result) {
    final colors = AppColors.of(context);
    final maxWeight =
        result.balance.values.fold(1.0, (m, v) => v > m ? v : m);
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface3,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('⚖️ گیج ترازو — وزن تقریبی تیم‌ها',
                style: TextStyle(
                    color: colors.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 18),
            ...result.balance.entries.map((e) {
              final pct = e.value / maxWeight;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.key,
                        style:
                            TextStyle(color: colors.subtext, fontSize: 12)),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 14,
                        backgroundColor: colors.surface,
                        valueColor:
                            const AlwaysStoppedAnimation(BrandColors.gold),
                      ),
                    ),
                  ],
                ),
              );
            }),
            Text(
              'وزن بلوک‌ها: حمله=۳، نجات=۲، بازرسی=۲، محافظت=۲، بقیه=۱',
              style: TextStyle(color: colors.subtext, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================== تب نقش‌ها

class _RolesTab extends ConsumerWidget {
  const _RolesTab({required this.state, required this.controller});

  final BuilderState state;
  final BuilderController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final s = state.scenario!;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        TextField(
          decoration: const InputDecoration(
              labelText: 'نام سناریو', hintText: 'مثلاً مافیای محله ما'),
          controller: TextEditingController(text: state.name),
          onChanged: controller.setName,
        ),
        const SizedBox(height: 10),
        TextField(
          decoration:
              const InputDecoration(labelText: 'توضیح (اختیاری)'),
          controller: TextEditingController(text: state.description),
          onChanged: controller.setDescription,
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            _Stepper(
              label: 'کمترین بازیکن',
              value: s.playersMin,
              onChanged: controller.setPlayersMin,
            ),
            const SizedBox(width: 12),
            _Stepper(
              label: 'بیشترین بازیکن',
              value: s.playersMax,
              onChanged: controller.setPlayersMax,
            ),
          ],
        ),
        const SizedBox(height: 18),
        SwitchListTile(
          title: Text('تیم فرقه (سطح ۱ — شرط برد آماده دارد)',
              style: TextStyle(color: colors.text, fontSize: 14)),
          value: controller.hasCult,
          activeThumbColor: BrandColors.cult,
          onChanged: controller.toggleCultTeam,
        ),
        const Divider(height: 32),
        Text('نقش‌ها (${s.totalCards.fa} کارت)',
            style: TextStyle(
                color: colors.text,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        for (final role in s.roles)
          _RoleCard(
            role: role,
            teamName: s.teamById(role.team)?.name ?? role.team,
            onMinus: () => controller.updateRoleCount(role.id, -1),
            onPlus: () => controller.updateRoleCount(role.id, 1),
            onDelete: s.roles.length > 2 ? () => controller.removeRole(role.id) : null,
          ),
        const SizedBox(height: 12),
        _AddRoleButton(controller: controller, hasCult: controller.hasCult),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.teamName,
    required this.onMinus,
    required this.onPlus,
    required this.onDelete,
  });

  final GrdnRole role;
  final String teamName;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final abilityNames = role.abilities
        .where((b) => b.type != 'immunity')
        .map((b) => b.name)
        .join('، ');
    final immune = role.abilities.any((b) => b.type == 'immunity');

    return GooeyCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(iconGlyph(role.icon), style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Text('${role.name} — تیم $teamName',
                    style: TextStyle(
                        color: colors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
              ),
              IconButton(
                  onPressed: onMinus, icon: const Icon(Icons.remove)),
              Text('${role.count}'.fa,
                  style: TextStyle(
                      color: colors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              IconButton(onPressed: onPlus, icon: const Icon(Icons.add)),
              if (onDelete != null)
                IconButton(
                    onPressed: onDelete,
                    icon: Icon(Icons.close, color: colors.subtext)),
            ],
          ),
          if (abilityNames.isNotEmpty)
            Text('توانایی: $abilityNames',
                style: TextStyle(color: colors.subtext, fontSize: 12)),
          if (immune)
            Text('مصونیت از بازرسی دارد',
                style: TextStyle(color: BrandColors.info, fontSize: 12)),
        ],
      ),
    );
  }
}

class _AddRoleButton extends ConsumerStatefulWidget {
  const _AddRoleButton({required this.controller, required this.hasCult});

  final BuilderController controller;
  final bool hasCult;

  @override
  ConsumerState<_AddRoleButton> createState() => _AddRoleButtonState();
}

class _AddRoleButtonState extends ConsumerState<_AddRoleButton> {
  final _nameController = TextEditingController();
  String _team = '';
  String _ability = 'none';
  bool _immune = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final s = ref.watch(builderProvider).scenario!;
    if (_team.isEmpty || s.teamById(_team) == null) {
      _team = s.teams.first.id;
    }

    return GooeyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('➕ افزودن نقش',
              style: TextStyle(
                  color: colors.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(hintText: 'نام نقش'),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              for (final t in s.teams)
                ChoiceChip(
                  label: Text(t.name),
                  selected: _team == t.id,
                  onSelected: (_) => setState(() => _team = t.id),
                ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _ability,
            dropdownColor: colors.surface3,
            decoration: const InputDecoration(labelText: 'توانایی'),
            items: const [
              DropdownMenuItem(value: 'none', child: Text('بدون توانایی (شهروند)')),
              DropdownMenuItem(value: 'attack', child: Text('حمله — کشتن')),
              DropdownMenuItem(value: 'save', child: Text('نجات')),
              DropdownMenuItem(value: 'inspect', child: Text('بازرسی')),
              DropdownMenuItem(value: 'protect', child: Text('محافظت')),
            ],
            onChanged: (v) => setState(() => _ability = v ?? 'none'),
          ),
          SwitchListTile(
            title: Text('مصونیت از بازرسی (مثل گودفادر)',
                style: TextStyle(color: colors.text, fontSize: 13)),
            value: _immune,
            activeThumbColor: colors.primary,
            onChanged: (v) => setState(() => _immune = v),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: () {
              final name = _nameController.text.trim();
              if (name.isEmpty) return;
              widget.controller.addRole(
                  name: name,
                  teamId: _team,
                  abilityType: _ability,
                  immuneToInspect: _immune);
              _nameController.clear();
              setState(() {
                _ability = 'none';
                _immune = false;
              });
            },
            child: const Text('افزودن'),
          ),
        ],
      ),
    );
  }
}

// =========================================================== تب شب

class _NightTab extends ConsumerWidget {
  const _NightTab({required this.state, required this.controller});

  final BuilderState state;
  final BuilderController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final s = state.scenario!;
    final night = s.phases.firstWhere((p) => p.kind == 'night');
    final dawn = s.phases.firstWhere((p) => p.kind == 'dawn');

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('ترتیب بیداری شب',
            style: TextStyle(
                color: colors.text,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('نقش‌های دارای بلوک شبانه به ترتیب بیدار می‌شوند. کشیدن نیست — با فلش‌ها جابه‌جا کن.',
            style: TextStyle(color: colors.subtext, fontSize: 12)),
        const SizedBox(height: 12),
        for (var i = 0; i < night.wakeList.length; i++)
          _WakeRow(
            title: _wakeTitle(s, night.wakeList[i]),
            isFirst: i == 0,
            isLast: i == night.wakeList.length - 1,
            onUp: () => controller.moveWakeEntry(i, -1),
            onDown: () => controller.moveWakeEntry(i, 1),
          ),
        const Divider(height: 36),
        _TimerRow(
          label: '⏱️ تایمر شب',
          seconds: night.timer,
          onChanged: (v) => controller.setPhaseTimer('night', v),
        ),
        const SizedBox(height: 10),
        _TimerRow(
          label: '🌅 تایمر سپیده‌دم',
          seconds: dawn.timer,
          onChanged: (v) => controller.setPhaseTimer('dawn', v),
        ),
      ],
    );
  }

  String _wakeTitle(GrdnScenario s, String entry) {
    if (entry.endsWith('*')) {
      final teamId = entry.substring(0, entry.length - 1);
      return 'همه تیم ${s.teamById(teamId)?.name ?? teamId} (یکجا)';
    }
    return 'نقش ${s.roleById(entry)?.name ?? entry}';
  }
}

class _WakeRow extends StatelessWidget {
  const _WakeRow({
    required this.title,
    required this.isFirst,
    required this.isLast,
    required this.onUp,
    required this.onDown,
  });

  final String title;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onUp;
  final VoidCallback onDown;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return GooeyCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Text(title, style: TextStyle(color: colors.text, fontSize: 14)),
          const Spacer(),
          IconButton(
            onPressed: isFirst ? null : onUp,
            icon: Icon(Icons.arrow_upward, color: colors.primary, size: 20),
          ),
          IconButton(
            onPressed: isLast ? null : onDown,
            icon: Icon(Icons.arrow_downward, color: colors.primary, size: 20),
          ),
        ],
      ),
    );
  }
}

class _TimerRow extends ConsumerWidget {
  const _TimerRow({
    required this.label,
    required this.seconds,
    required this.onChanged,
  });

  final String label;
  final int seconds;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    return GooeyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label — ${seconds.fa} ثانیه',
              style: TextStyle(color: colors.text, fontSize: 14)),
          Slider(
            value: seconds.toDouble(),
            min: 15,
            max: 300,
            divisions: 19,
            activeColor: colors.primary,
            onChanged: (v) => onChanged(v.round()),
          ),
        ],
      ),
    );
  }
}

// =========================================================== تب روز

class _DayTab extends ConsumerWidget {
  const _DayTab({required this.state, required this.controller});

  final BuilderState state;
  final BuilderController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = state.scenario!;
    final day = s.phases.firstWhere((p) => p.kind == 'day');
    final vote = s.phases.firstWhere((p) => p.kind == 'vote');

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _TimerRow(
          label: '☀️ تایمر بحث روز',
          seconds: day.timer,
          onChanged: (v) => controller.setPhaseTimer('day', v),
        ),
        const SizedBox(height: 10),
        _TimerRow(
          label: '🗳️ تایمر رأی‌گیری',
          seconds: vote.timer,
          onChanged: (v) => controller.setPhaseTimer('vote', v),
        ),
        const SizedBox(height: 10),
        SwitchListTile(
          title: Text('شب اول کشتن ندارد (شب آشنایی)',
              style: TextStyle(color: AppColors.of(context).text, fontSize: 14)),
          subtitle: Text('اگر خاموش باشد، مافیا همان شب اول هم می‌تواند بکشد',
              style: TextStyle(color: AppColors.of(context).subtext, fontSize: 12)),
          value: !s.rules.firstNightKill,
          activeThumbColor: AppColors.of(context).primary,
          onChanged: (v) => controller.setFirstNightKill(!v),
        ),
        SwitchListTile(
          title: Text('دکتر می‌تواند خودش را نجات دهد',
              style: TextStyle(color: AppColors.of(context).text, fontSize: 14)),
          value: s.rules.doctor.selfSave,
          activeThumbColor: AppColors.of(context).primary,
          onChanged: controller.setDoctorSelfSave,
        ),
      ],
    );
  }
}

// =========================================================== تب شرط برد

class _WinTab extends ConsumerWidget {
  const _WinTab({required this.state, required this.controller});

  final BuilderState state;
  final BuilderController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final s = state.scenario!;

    final hasStandard = s.winConditions.any((w) =>
        w.team == 'city' &&
        w.terms.any((t) => t.left == 'aliveCount:mafia' && t.op == '=='));
    final hasCult = s.winConditions.any((w) => w.team == 'cult');

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('شرط برد از پریست‌های آماده (سطح ۱)',
            style: TextStyle(
                color: colors.text,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('در سطح ۳ (طلایی) می‌توانی فرمول شرط برد را خودت با تراشه بسازی.',
            style: TextStyle(color: colors.subtext, fontSize: 12)),
        const SizedBox(height: 16),
        SwitchListTile(
          title: Text('استاندارد شهر/مافیا',
              style: TextStyle(color: colors.text, fontSize: 14)),
          subtitle: Text(
              'شهر: همه مافیاها حذف شوند — مافیا: تعدادشان >= شهر شود',
              style: TextStyle(color: colors.subtext, fontSize: 12)),
          value: hasStandard,
          activeThumbColor: colors.primary,
          onChanged: (v) => controller.setWinPreset(v, hasCult),
        ),
        if (s.teamById('cult') != null)
          SwitchListTile(
            title: Text('برد فرقه',
                style: TextStyle(color: colors.text, fontSize: 14)),
            subtitle: Text('۲ نفر زنده فرقه تا گردش ۵',
                style: TextStyle(color: colors.subtext, fontSize: 12)),
            value: hasCult,
            activeThumbColor: BrandColors.cult,
            onChanged: (v) => controller.setWinPreset(hasStandard, v),
          ),
        const SizedBox(height: 20),
        GooeyCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('👑 سطوح ۲ و ۳ و ۴ سناریوساز',
                  style: TextStyle(
                      color: colors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                'بلوک‌ساز توانایی، شرط‌برد بصری تراشه‌ای و رویدادهای تصادفی در گردون طلایی باز می‌شوند.',
                style: TextStyle(color: colors.subtext, fontSize: 13)),
              TextButton(
                onPressed: PremiumGate.isGolden
                    ? null
                    : () => context.go('/premium'),
                child: Text(PremiumGate.isGolden
                    ? 'طلایی فعالی — به‌زودی ✓'
                    : 'دیدن گردون طلایی'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =========================================================== اجزای مشترک

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Expanded(
      child: GooeyCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: colors.subtext, fontSize: 11)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                    onPressed: () => onChanged(value - 1),
                    icon: const Icon(Icons.remove, size: 18)),
                Text(value.fa,
                    style: TextStyle(
                        color: colors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                IconButton(
                    onPressed: () => onChanged(value + 1),
                    icon: const Icon(Icons.add, size: 18)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ValidationPanel extends StatelessWidget {
  const _ValidationPanel({required this.result});

  final ValidationResult result;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    if (result.errors.isEmpty && result.warnings.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Text('✓ سناریو سالم و متعادل به نظر می‌رسد',
            style: TextStyle(color: BrandColors.city, fontSize: 12)),
      );
    }
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface3,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final e in result.errors)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('🔴 ${e.text}',
                  style: const TextStyle(color: BrandColors.mafia, fontSize: 12)),
            ),
          for (final w in result.warnings)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('🟡 ${w.text}',
                  style:
                      TextStyle(color: BrandColors.gold, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.onBalance,
    required this.onSave,
    required this.onShare,
  });

  final VoidCallback onBalance;
  final VoidCallback? onSave;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'گیج ترازو',
            onPressed: onBalance,
            icon: const Icon(Icons.balance),
            color: colors.primary,
          ),
          const Spacer(),
          OutlinedButton(
            onPressed: onSave,
            child: const Text('💾 ذخیره'),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: onShare,
            child: const Text('📤 خروجی .grdn'),
          ),
        ],
      ),
    );
  }
}

/// هدف ویرایش از لیست سناریوساز
final editTargetProvider = StateProvider<String?>((ref) => null);
