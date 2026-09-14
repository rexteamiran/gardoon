/// خواندن فایل `.grdn` — بازکردن ZIP + اعتبارسنجی checksum + migration
///
/// خطاها همیشه با پیام فارسی دوستانه (architecture.md بخش ۱۰).
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';

import '../engine/json_codec.dart';
import '../engine/models/scenario.dart';
import '../engine/validator.dart';
import 'migration/migration.dart';

/// خطای خواندن فایل سناریو با پیام فارسی
class GrdnException implements Exception {
  const GrdnException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// خروجی خواندن فایل
class GrdnReadResult {
  const GrdnReadResult({
    required this.manifest,
    required this.scenario,
    required this.warnings,
  });

  final Map<String, dynamic> manifest;
  final GrdnScenario scenario;
  final List<ValidationMessage> warnings;
}

class GrdnReader {
  const GrdnReader({ScenarioValidator? validator})
      : validator = validator ?? const ScenarioValidator();

  final ScenarioValidator validator;

  GrdnReadResult read(Uint8List bytes) {
    // ۱) باز کردن ZIP
    Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      throw const GrdnException('فایل سناریو قابل خواندن نیست — ساختار ZIP خراب است');
    }

    Map<String, dynamic>? manifest;
    Uint8List? dataBytes;
    for (final file in archive.files) {
      if (file.isFile) {
        final content = Uint8List.fromList(List<int>.from(file.content as List));
        if (file.name == 'manifest.grdn.json') {
          manifest = json.decode(utf8.decode(content)) as Map<String, dynamic>;
        } else if (file.name == 'data.grdn.json') {
          dataBytes = content;
        }
      }
      // فایل‌های ناشناخته نادیده گرفته می‌شوند (طبق فرمت)
    }

    // ۲) وجود فایل‌های لازم
    if (manifest == null || dataBytes == null) {
      throw const GrdnException('ساختار فایل سناریو معتبر نیست');
    }

    // ۳) امضای فرمت
    if (manifest['format'] != 'GRDN') {
      throw const GrdnException('این فایل یک سناریوی گردون نیست');
    }

    // ۴) نسخه فرمت و migration
    final version = manifest['formatVersion'] is int
        ? manifest['formatVersion'] as int
        : 1;
    if (version > kCurrentFormatVersion) {
      throw const GrdnException(
          'این سناریو با نسخه جدیدتر گردون ساخته شده — اپ را به‌روز کنید');
    }

    // ۵) checksum
    final expected = manifest['checksum'] as String? ?? '';
    final actual =
        'sha256:${sha256.convert(dataBytes).toString()}';
    if (expected.isNotEmpty && expected != actual) {
      throw const GrdnException('فایل سناریو سالم نیست — checksum تطبیق نکرد');
    }

    // ۶) migration زنجیره‌ای
    var dataMap = json.decode(utf8.decode(dataBytes)) as Map<String, dynamic>;
    dataMap = const GrdnMigrator().migrate(dataMap, version, kCurrentFormatVersion);

    // ۷) ساخت مدل
    final scenario = const GrdnJsonCodec().decode(
      dataMap,
      playersMin: manifest['playersMin'] is int
          ? manifest['playersMin'] as int
          : 6,
      playersMax: manifest['playersMax'] is int
          ? manifest['playersMax'] as int
          : 15,
    );

    // ۸) اعتبارسنجی — خطاها مانع ورود سناریو به کتابخانه می‌شوند
    final result = validator.validate(scenario);
    if (!result.isValid) {
      throw GrdnException(
          'سناریو ایراد دارد: ${result.errors.first.text}');
    }

    return GrdnReadResult(
      manifest: manifest,
      scenario: scenario,
      warnings: result.warnings,
    );
  }
}
