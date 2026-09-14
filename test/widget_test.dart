/// تست دودی اپ — اسپلش و تم‌ها
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gardoon/app.dart';
import 'package:gardoon/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('تم تاریک و روشن هر دو تعریف شده‌اند (agents.md بخش ۵)', () {
    final dark = AppTheme.dark();
    final light = AppTheme.light();
    expect(dark.brightness, Brightness.dark);
    expect(light.brightness, Brightness.light);
    expect(dark.textTheme.bodyLarge?.fontFamily, 'Vazirmatn');
    expect(light.textTheme.bodyLarge?.fontFamily, 'Vazirmatn');
  });

  testWidgets('اپ بالا می‌آید و اسپلش نشان داده می‌شود', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: GardoonApp()),
    );
    await tester.pump(const Duration(milliseconds: 100));
    // اسپلش با لوگو و شعار
    expect(find.text('گردون'), findsWidgets);
    expect(find.text('چرخه رو تو بگردون'), findsOneWidget);
  });
}
