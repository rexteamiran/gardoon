/// تست فرمت .grdn — roundtrip: بنویس ← بخوان ← برابر (طبق agents.md بخش ۷)
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gardoon/engine/json_codec.dart';
import 'package:gardoon/grdn/grdn_reader.dart';
import 'package:gardoon/grdn/grdn_writer.dart';

GrdnJsonCodec codec = const GrdnJsonCodec();

Map<String, dynamic> loadMinimalJson() {
  final raw = File('test/fixtures/minimal_scenario.json').readAsStringSync();
  return json.decode(raw) as Map<String, dynamic>;
}

void main() {
  test('roundtrip: نوشتن و خواندن مجدد داده یکسان می‌دهد', () {
    final originalJson = loadMinimalJson();
    final scenario = codec.decode(originalJson, playersMin: 6, playersMax: 6);

    final bytes = const GrdnWriter().write(
      scenario,
      const GrdnFileMeta(
        scenarioId: '550e8400-e29b-41d4-a716-446655440000',
        name: 'مافیا کلاسیک تهران',
        description: 'همان مافیای همیشگی',
        author: 'علی',
      ),
    );

    expect(bytes.length, greaterThan(100));

    final result = const GrdnReader().read(bytes);
    final reEncoded = json.encode(codec.encode(result.scenario));
    final originalEncoded = json.encode(codec.encode(scenario));
    expect(reEncoded, originalEncoded);

    expect(result.manifest['format'], 'GRDN');
    expect(result.manifest['formatVersion'], 1);
    expect(result.manifest['name'], 'مافیا کلاسیک تهران');
    expect(result.scenario.playersMin, 6);
    expect(result.scenario.roles.length, 3);
  });

  test('checksum دستکاری‌شده رد می‌شود', () {
    final scenario = codec.decode(loadMinimalJson());
    var bytes = const GrdnWriter().write(
      scenario,
      const GrdnFileMeta(scenarioId: 'x-id', name: 'تست'),
    );

    // دستکاری یک بایت از انتهای فایل
    final mutable = Uint8List.fromList(bytes);
    mutable[mutable.length - 5] = mutable[mutable.length - 5] ^ 0xFF;
    bytes = mutable;

    expect(() => const GrdnReader().read(bytes), throwsA(isA<GrdnException>()));
  });

  test('فایل غیر ZIP پیام فارسی می‌دهد', () {
    final bytes = Uint8List.fromList(utf8.encode('این یک فایل سناریو نیست'));
    expect(
      () => const GrdnReader().read(bytes),
      throwsA(isA<GrdnException>()),
    );
  });
}
