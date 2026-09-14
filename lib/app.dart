/// MaterialApp + تم + مسیریابی — طبق agents.md بخش ۳
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'data/settings.dart';
import 'features/builder/builder_list_screen.dart';
import 'features/builder/builder_screen.dart';
import 'features/home/home_screen.dart';
import 'features/library/library_screen.dart';
import 'features/premium/premium_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/splash/splash_screen.dart';
import 'features/table/host/host_screen.dart';
import 'features/table/role_deal/role_deal_screen.dart';
import 'features/table/setup/table_setup_screen.dart';

final _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/table/setup',
      builder: (context, state) => const TableSetupScreen(),
    ),
    GoRoute(
      path: '/table/deal',
      builder: (context, state) => const RoleDealScreen(),
    ),
    GoRoute(
      path: '/table/play',
      builder: (context, state) => const HostScreen(),
    ),
    GoRoute(
      path: '/builder',
      builder: (context, state) => const BuilderListScreen(),
    ),
    GoRoute(
      path: '/builder/edit',
      builder: (context, state) => const BuilderScreen(),
    ),
    GoRoute(
      path: '/builder/edit/copy/:id',
      builder: (context, state) =>
          BuilderScreen(fromCopyId: state.pathParameters['id']),
    ),
    GoRoute(
      path: '/library',
      builder: (context, state) => const LibraryScreen(),
    ),
    GoRoute(
      path: '/premium',
      builder: (context, state) => const PremiumScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);

class GardoonApp extends ConsumerWidget {
  const GardoonApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    // جهت متن راست‌به‌چپ — فقط فارسی (agents.md بخش ۱)
    return Directionality(
      textDirection: TextDirection.rtl,
      child: MaterialApp.router(
        title: 'گردون',
        debugShowCheckedModeBanner: false,
        themeMode: _modeOf(settings.themeMode),
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        routerConfig: _router,
      ),
    );
  }

  ThemeMode _modeOf(GardoonThemeMode mode) {
    switch (mode) {
      case GardoonThemeMode.dark:
        return ThemeMode.dark;
      case GardoonThemeMode.light:
        return ThemeMode.light;
      case GardoonThemeMode.system:
        return ThemeMode.system;
    }
  }
}
