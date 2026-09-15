/// ورود بیلدر — لیست سناریوها → [+ جدید] از صفر یا کپی (design.md ۶.۴)
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants.dart';
import '../../../core/extensions/fa_numbers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/scenario_store.dart';
import 'builder_screen.dart' show editTargetProvider;

class BuilderListScreen extends ConsumerWidget {
  const BuilderListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final library = ref.watch(scenarioLibraryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('🛠️ سناریوساز')),
      body: library.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطا: $e')),
        data: (list) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            GooeyButton(
              label: 'سناریوی جدید',
              icon: Icons.add_circle_outline,
              height: 64,
              onPressed: () {
                ref.read(editTargetProvider.notifier).state = null;
                context.push('/builder/edit');
              },
            ),
            const SizedBox(height: 16),
            Text('از کپی پیش‌فرض شروع کن:',
                style: TextStyle(color: colors.subtext, fontSize: 13)),
            const SizedBox(height: 8),
            for (final e in list.where((e) => e.source != ScenarioSource.mine))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GooeyCard(
                  onTap: () => context.push('/builder/edit/copy/${e.scenarioId}'),
                  child: Row(
                    children: [
                      Text(iconGlyph(e.scenario.meta.icon),
                          style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text('کپی «${e.name}»',
                            style: TextStyle(
                                color: colors.text, fontSize: 14)),
                      ),
                      Icon(Icons.copy_all_outlined,
                          size: 18, color: colors.subtext),
                    ],
                  ),
                ),
              ),
            const Divider(height: 36),
            Text('سناریوهای من (${list.where((e) => e.source == ScenarioSource.mine).length.fa}):',
                style: TextStyle(
                    color: colors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            for (final e in list.where((e) => e.source == ScenarioSource.mine))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GooeyCard(
                  onTap: () {
                    ref.read(editTargetProvider.notifier).state =
                        e.scenarioId;
                    context.push('/builder/edit');
                  },
                  child: Row(
                    children: [
                      Text(iconGlyph(e.scenario.meta.icon),
                          style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.name,
                                style: TextStyle(
                                    color: colors.text,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600)),
                            Text('${e.playersMin.fa}–${e.playersMax.fa} نفر',
                                style: TextStyle(
                                    color: colors.subtext, fontSize: 11)),
                          ],
                        ),
                      ),
                      Icon(Icons.edit_outlined,
                          size: 20, color: colors.primary),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
