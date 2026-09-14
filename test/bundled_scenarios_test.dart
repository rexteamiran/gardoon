/// سناریوهای باندل اپ باید همیشه سالم و معتبر باشند
library;

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:gardoon/grdn/grdn_reader.dart';

const kBundled = [
  'assets/scenarios/classic_tehran.grdn',
  'assets/scenarios/professional.grdn',
  'assets/scenarios/cult_darkness.grdn',
  'assets/scenarios/constantine.grdn',
  'assets/scenarios/merciless_city.grdn',
];

void main() {
  // بارگذاری pubspec assets در محیط تست
  TestWidgetsFlutterBinding.ensureInitialized();

  test('هر ۵ سناریوی باندل خوانده می‌شوند و اعتبار دارند', () async {
    for (final path in kBundled) {
      final data = await rootBundle.load(path);
      final result = const GrdnReader()
          .read(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
      expect(result.scenario.teams.length, greaterThanOrEqualTo(2),
          reason: path);
      expect(result.scenario.winConditions, isNotEmpty, reason: path);
      expect(result.scenario.totalCards, greaterThanOrEqualTo(6), reason: path);
    }
  });
}
