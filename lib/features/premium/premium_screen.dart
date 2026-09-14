/// گردون طلایی 👑 — صفحه فروش (design.md ۶.۶)
///
/// نسخه ۱: پرداخت کافه بازار هنوز متصل نیست — فعال‌سازی محلی برای تست.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/settings.dart';

class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final settings = ref.watch(settingsProvider);
    final golden = settings.premium.isGolden;

    return Scaffold(
      appBar: AppBar(title: const Text('👑 گردون طلایی')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GooeyCard(
            color: colors.surface,
            child: Column(
              children: [
                const Text('👑', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 10),
                Text('گردون طلایی',
                    style: TextStyle(
                        color: BrandColors.gold,
                        fontSize: 24,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('اشتراک یک‌ساله',
                    style: TextStyle(color: colors.subtext, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _Benefit(icon: '🛠️', title: 'سناریوساز سطوح ۲ و ۳ و ۴'),
          _Benefit(icon: '🔓', title: 'همه سناریوهای ویژه بدون تبلیغ'),
          _Benefit(icon: '🎁', title: 'سناریوهای انحصاری طلایی'),
          _Benefit(icon: '🤖', title: 'گرداننده هوش مصنوعی (نسخه‌های بعد)'),
          const SizedBox(height: 24),
          if (golden)
            GooeyCard(
              child: Text(
                '✓ اشتراک طلایی فعال — تا ${settings.premium.goldenUntil?.toIso8601String().substring(0, 10) ?? ""}',
                style: TextStyle(color: BrandColors.city, fontSize: 15),
              ),
            )
          else ...[
            GooeyButton(
              label: 'خرید اشتراک از کافه بازار',
              height: 64,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'پرداخت کافه بازار به‌زودی فعال می‌شود — فعلاً دکمه فعال‌سازی محلی را بزن')),
                );
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () async {
                await ref
                    .read(settingsProvider.notifier)
                    .activateGoldenTrial();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'طلایی فعال شد (حالت تست تا اتصال پرداخت) 👑')),
                );
              },
              child: const Text('فعال‌سازی محلی (تست) — تا اتصال پرداخت'),
            ),
          ],
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.title});

  final String icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title,
                style: TextStyle(color: colors.text, fontSize: 15)),
          ),
        ],
      ),
    );
  }
}
