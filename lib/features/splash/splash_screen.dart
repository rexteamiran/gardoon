/// اسپلش — چرخ شب/روز آهسته می‌چرخد، لوگو محو ظاهر می‌شود (design.md ۶.۱)
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/gardoon_wheel.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // حداکثر ۲ ثانیه — طبق design.md
    _timer = Timer(const Duration(milliseconds: 2100), () {
      if (mounted) context.go('/home');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const GardoonWheel(size: 140, spinning: true),
            const SizedBox(height: 28),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOut,
              builder: (context, v, child) =>
                  Opacity(opacity: v, child: child),
              child: Column(
                children: [
                  Text('گردون',
                      style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          color: colors.text)),
                  const SizedBox(height: 8),
                  Text('چرخه رو تو بگردون',
                      style: TextStyle(color: colors.subtext, fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
