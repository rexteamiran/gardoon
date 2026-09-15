/// کتابخانه سناریوها — تب‌ها: پیش‌فرض | ویژه | من (design.md ۶.۵)
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
import '../../../grdn/grdn_reader.dart';
import '../../../grdn/share.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);
  bool _importing = false;

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final library = ref.watch(scenarioLibraryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('کتابخانه سناریوها'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: colors.primary,
          unselectedLabelColor: colors.subtext,
          indicatorColor: colors.primary,
          tabs: const [
            Tab(text: 'پیش‌فرض'),
            Tab(text: 'ویژه'),
            Tab(text: 'من'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _importFile,
        icon: const Icon(Icons.file_open_outlined),
        label: const Text('ورود فایل .grdn'),
      ),
      body: library.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('خطا در بارگذاری کتابخانه: $e',
              style: const TextStyle(color: BrandColors.mafia)),
        ),
        data: (list) {
          final bundled = list
              .where((e) => e.source == ScenarioSource.bundled)
              .toList();
          final special = list
              .where((e) => e.source == ScenarioSource.special)
              .toList();
          final mine =
              list.where((e) => e.source == ScenarioSource.mine).toList();

          return TabBarView(
            controller: _tabs,
            children: [
              _List(entries: bundled, onPlay: _play),
              _List(entries: special, onPlay: _playSpecial),
              _List(entries: mine, onPlay: _play, onDelete: _delete),
            ],
          );
        },
      ),
    );
  }

  void _play(LibraryEntry e) {
    // فقط انتخاب سناریو — بازیکن‌ها در صفحه راه‌اندازی وارد می‌شوند
    ref.read(selectedScenarioProvider.notifier).state = e.scenarioId;
    context.push('/table/setup');
  }

  void _playSpecial(LibraryEntry e) {
    if (!PremiumGate.canUse(PremiumFeature.premiumScenarios)) {
      context.push('/premium');
      return;
    }
    _play(e);
  }

  Future<void> _delete(LibraryEntry e) async {
    await const ScenarioStore().delete(e.scenarioId);
    ref.invalidate(scenarioLibraryProvider);
  }

  Future<void> _importFile() async {
    if (_importing) return;
    setState(() => _importing = true);
    try {
      final result = await const GrdnShare().pickAndRead();
      if (!mounted) return;
      if (result != null) {
        ref.invalidate(scenarioLibraryProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'سناریوی «${result.manifest['name']}» اضافه شد')),
        );
      }
    } on GrdnException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }
}

class _List extends StatelessWidget {
  const _List({required this.entries, required this.onPlay, this.onDelete});

  final List<LibraryEntry> entries;
  final ValueChanged<LibraryEntry> onPlay;
  final ValueChanged<LibraryEntry>? onDelete;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(
        child: Text('هنوز چیزی اینجا نیست',
            style: TextStyle(
                color: AppColors.of(context).subtext, fontSize: 14)),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        for (final e in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GooeyCard(
              onTap: () => onPlay(e),
              child: Row(
                children: [
                  Text(iconGlyph(e.scenario.meta.icon),
                      style: const TextStyle(fontSize: 30)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.name,
                            style: TextStyle(
                                color: AppColors.of(context).text,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(
                          '${e.author} • ${e.playersMin.fa}–${e.playersMax.fa} نفر',
                          style: TextStyle(
                              color: AppColors.of(context).subtext,
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (e.premium)
                    const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Icon(Icons.lock_outline,
                          size: 20, color: BrandColors.gold),
                    ),
                  if (onDelete != null)
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          color: AppColors.of(context).subtext),
                      onPressed: () => onDelete!(e),
                    ),
                  Icon(Icons.chevron_left,
                      color: AppColors.of(context).subtext),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
