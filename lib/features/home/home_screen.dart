/// خانه گردون — طبق وایرفریم design.md ۶.۲
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/premium_gate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/gardoon_wheel.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final golden = PremiumGate.isGolden;

    // دکمه بازگشت اندروید در خانه = تأیید خروج، نه خروج ناگهانی
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await _confirmExit(context);
        if (leave && context.mounted) SystemNavigator.pop();
      },
      child: Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              // هدر
              Row(
                children: [
                  const GardoonWheel(size: 40),
                  const SizedBox(width: 10),
                  Text('گردون',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: colors.text)),
                  const Spacer(),
                  IconButton(
                    tooltip: 'گردون طلایی',
                    onPressed: () => context.push('/premium'),
                    icon: Icon(
                      Icons.workspace_premium,
                      color: golden ? BrandColors.gold : colors.subtext,
                      size: 28,
                    ),
                  ),
                  IconButton(
                    tooltip: 'تنظیمات',
                    onPressed: () => context.push('/settings'),
                    icon: Icon(Icons.tune, color: colors.text, size: 26),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              // دکمه اصلی — میزگرد جدید
              GooeyButton(
                label: 'میزگرد جدید',
                icon: Icons.casino_outlined,
                height: 92,
                onPressed: () => context.push('/table/setup'),
              ),
              const SizedBox(height: 20),
              // دو دکمه فرعی
              Row(
                children: [
                  Expanded(
                    child: _SecondaryCard(
                      icon: '🛠️',
                      title: 'سناریوساز',
                      subtitle: 'قانون خودت را بساز',
                      onTap: () => context.push('/builder'),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _SecondaryCard(
                      icon: '🏛️',
                      title: 'کتابخانه',
                      subtitle: 'سناریوهای آماده',
                      onTap: () => context.push('/library'),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // شعار
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  '🎡 چرخه رو تو بگردون',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.subtext, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Future<bool> _confirmExit(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('خروج از گردون؟'),
        content: const Text('می‌خواهید اپ را ببندید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('نه، می‌مانم'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('خروج'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _SecondaryCard extends StatelessWidget {
  const _SecondaryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return GooeyCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 10),
          Text(title,
              style: TextStyle(
                  color: colors.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: TextStyle(color: colors.subtext, fontSize: 12)),
        ],
      ),
    );
  }
}
