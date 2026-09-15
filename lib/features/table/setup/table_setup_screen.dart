/// راه‌اندازی بازی — نام بازیکن‌ها + انتخاب سناریو (design.md ۶.۳-۱)
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/fa_numbers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/scenario_store.dart';
import '../providers/table_controller.dart';

class TableSetupScreen extends ConsumerStatefulWidget {
  const TableSetupScreen({super.key});

  @override
  ConsumerState<TableSetupScreen> createState() => _TableSetupScreenState();
}

class _TableSetupScreenState extends ConsumerState<TableSetupScreen> {
  final _nameController = TextEditingController();
  final List<String> _names = [];
  LibraryEntry? _selected;

  @override
  void initState() {
    super.initState();
    // اگر از کتابخانه سناریویی انتخاب شده، همان اول انتخاب باشد
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pre = ref.read(selectedScenarioProvider);
      if (pre == null || _selected != null) return;
      final library = ref.read(scenarioLibraryProvider).valueOrNull;
      if (library == null) return;
      final match = library.where((e) => e.scenarioId == pre).firstOrNull;
      if (match != null) {
        setState(() => _selected = match);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addName() {
    final name = _nameController.text.trim();
    if (name.isEmpty || _names.contains(name)) return;
    setState(() {
      _names.add(name);
      _nameController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final library = ref.watch(scenarioLibraryProvider);

    // سناریوهای قابل بازی برای این تعداد بازیکن
    final playable = library.whenOrNull(
          data: (list) => list.where((e) => !e.locked).toList(),
        ) ??
        const <LibraryEntry>[];

    final error = _validationError(playable);

    return Scaffold(
      appBar: AppBar(title: const Text('میزگرد جدید')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('۱. بازیکن‌ها',
              style: TextStyle(
                  color: colors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addName(),
                  decoration:
                      const InputDecoration(hintText: 'اسم بازیکن…'),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                onPressed: _addName,
                icon: const Icon(Icons.person_add_alt_1),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _names
                .map((n) => InputChip(
                      label: Text(n),
                      onDeleted: () => setState(() => _names.remove(n)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 24),
          Text('۲. سناریو',
              style: TextStyle(
                  color: colors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...playable.map((e) => _ScenarioRow(
                entry: e,
                selected: _selected?.scenarioId == e.scenarioId,
                onTap: () => setState(() => _selected = e),
              )),
          const SizedBox(height: 24),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(error,
                  style: const TextStyle(
                      color: BrandColors.mafia, fontSize: 14)),
            ),
          GooeyButton(
            label: 'بریم نقش‌کشه 🎲',
            onPressed: error == null && _selected != null
                ? () {
                    ref
                        .read(tableProvider.notifier)
                        .startGame(_selected!, _names);
                    context.push('/table/deal');
                  }
                : null,
          ),
        ],
      ),
    );
  }

  String? _validationError(List<LibraryEntry> playable) {
    if (_names.isEmpty) return null;
    if (_names.length < 5) {
      return 'حداقل ۵ بازیکن لازم است (الان: ${_names.length.fa})';
    }
    if (_selected == null) return null;
    final s = _selected!;
    if (_names.length < s.playersMin || _names.length > s.playersMax) {
      return 'سناریوی «${s.name}» برای ${s.playersMin.fa} تا ${s.playersMax.fa} نفر است';
    }
    return null;
  }
}

class _ScenarioRow extends StatelessWidget {
  const _ScenarioRow({
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  final LibraryEntry entry;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return GooeyCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(
            selected
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: selected ? colors.primary : colors.subtext,
            size: 22,
          ),
          const SizedBox(width: 6),
          Text(entry.name,
              style: TextStyle(
                  color: colors.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(
            '${entry.playersMin.fa}–${entry.playersMax.fa} نفر',
            style: TextStyle(color: colors.subtext, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
