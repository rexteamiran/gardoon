/// تنظیمات — تم تاریک/روشن، صدا، درباره (design.md: دو تم، انتخاب با کاربر)
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../data/settings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('تنظیمات')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('🌗 تم',
              style: TextStyle(
                  color: colors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          RadioGroup<GardoonThemeMode>(
            groupValue: settings.themeMode,
            onChanged: (v) =>
                controller.setThemeMode(v ?? GardoonThemeMode.dark),
            child: Column(
              children: [
                RadioListTile(
                  title: Text('تاریک (پیش‌فرض)',
                      style: TextStyle(color: colors.text)),
                  value: GardoonThemeMode.dark,
                  activeColor: colors.primary,
                ),
                RadioListTile(
                  title: Text('روشن', style: TextStyle(color: colors.text)),
                  value: GardoonThemeMode.light,
                  activeColor: colors.primary,
                ),
                RadioListTile(
                  title: Text('همراه سیستم',
                      style: TextStyle(color: colors.text)),
                  value: GardoonThemeMode.system,
                  activeColor: colors.primary,
                ),
              ],
            ),
          ),
          const Divider(height: 32),
          SwitchListTile(
            title: Text('🔊 صداها', style: TextStyle(color: colors.text)),
            subtitle: Text('افکت‌های میزگرد و چرخش گردونه',
                style: TextStyle(color: colors.subtext, fontSize: 12)),
            value: settings.soundOn,
            activeThumbColor: colors.primary,
            onChanged: controller.setSound,
          ),
          const Divider(height: 32),
          ListTile(
            leading: Icon(Icons.workspace_premium,
                color: BrandColors.gold, size: 28),
            title: Text('گردون طلایی',
                style: TextStyle(color: colors.text)),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => context.go('/premium'),
          ),
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('درباره گردون',
                    style: TextStyle(
                        color: colors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(
                  'نسخه ۱.۰.۰ — کاملاً آفلاین و کاملاً فارسی\n'
                  'فرمت سناریو: .grdn (ZIP + JSON باز)\n'
                  'ساخته‌شده برای گرداننده‌های مافیا 🎡',
                  style: TextStyle(
                      color: colors.subtext, fontSize: 12, height: 1.8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
