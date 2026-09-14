/// ذخیره‌سازی سناریوها — طبق architecture.md بخش ۶
///
/// سناریوهای باندل: assets/scenarios/*.grdn (readonly)
/// سناریوهای کاربر: documents/scenarios/*.grdn (فایل واقعی = قابل خروجی)
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../engine/models/scenario.dart';
import '../grdn/grdn_reader.dart';
import '../grdn/grdn_writer.dart';

enum ScenarioSource { bundled, special, mine }

/// یک آیتم کتابخانه — نام و مشخصات از manifest
class LibraryEntry {
  LibraryEntry({
    required this.scenarioId,
    required this.name,
    required this.description,
    required this.author,
    required this.source,
    required this.locked,
    required this.premium,
    required this.playersMin,
    required this.playersMax,
    required this.bytes,
    required this.scenario,
  });

  final String scenarioId;
  final String name;
  final String description;
  final String author;
  final ScenarioSource source;
  final bool locked; // سناریوی سورپرایز — نقش‌ها مخفی
  final bool premium; // ویژه — با طلایی باز می‌شود
  final int playersMin;
  final int playersMax;
  final Uint8List bytes;
  final GrdnScenario scenario;
}

class ScenarioStore {
  const ScenarioStore();

  /// سناریوهای همراه اپ
  Future<List<LibraryEntry>> loadBundled() async {
    final entries = <LibraryEntry>[];
    const files = [
      'assets/scenarios/classic_tehran.grdn',
      'assets/scenarios/professional.grdn',
      'assets/scenarios/cult_darkness.grdn',
      'assets/scenarios/constantine.grdn',
      'assets/scenarios/merciless_city.grdn',
    ];
    for (final path in files) {
      try {
        final bytes = await rootBundle.load(path);
        final data = bytes.buffer.asUint8List();
        final result = const GrdnReader().read(data);
        final isSpecial = path.contains('constantine') ||
            path.contains('merciless');
        entries.add(LibraryEntry(
          scenarioId: result.manifest['scenarioId'] as String? ?? path,
          name: result.manifest['name'] as String? ?? 'سناریو',
          description: result.manifest['description'] as String? ?? '',
          author: result.manifest['author'] as String? ?? '',
          source: isSpecial ? ScenarioSource.special : ScenarioSource.bundled,
          locked: result.manifest['locked'] as bool? ?? false,
          premium: result.manifest['premium'] as bool? ?? false,
          playersMin: result.scenario.playersMin,
          playersMax: result.scenario.playersMax,
          bytes: data,
          scenario: result.scenario,
        ));
      } catch (_) {
        // سناریوی خراب هرگز نباید اپ را ببندد (architecture.md بخش ۱۰)
      }
    }
    return entries;
  }

  /// سناریوهای ذخیره‌شده کاربر
  Future<List<LibraryEntry>> loadMine() async {
    final dir = await _userDir();
    final entries = <LibraryEntry>[];
    if (!dir.existsSync()) return entries;
    for (final file in dir.listSync()) {
      if (file is File && file.path.endsWith('.grdn')) {
        try {
          final data = await file.readAsBytes();
          final result = const GrdnReader().read(data);
          entries.add(LibraryEntry(
            scenarioId: result.manifest['scenarioId'] as String? ?? file.path,
            name: result.manifest['name'] as String? ?? 'سناریو',
            description: result.manifest['description'] as String? ?? '',
            author: result.manifest['author'] as String? ?? '',
            source: ScenarioSource.mine,
            locked: result.manifest['locked'] as bool? ?? false,
            premium: result.manifest['premium'] as bool? ?? false,
            playersMin: result.scenario.playersMin,
            playersMax: result.scenario.playersMax,
            bytes: data,
            scenario: result.scenario,
          ));
        } catch (_) {
          // فایل خراب نادیده گرفته می‌شود
        }
      }
    }
    return entries;
  }

  /// ذخیره یا به‌روزرسانی سناریوی کاربر
  Future<LibraryEntry> save({
    required GrdnScenario scenario,
    required String name,
    required String description,
    required String author,
    String? scenarioId,
  }) async {
    final dir = await _userDir();
    final id = scenarioId ?? _newUuid();
    final bytes = const GrdnWriter().write(
      scenario,
      GrdnFileMeta(
        scenarioId: id,
        name: name,
        description: description,
        author: author,
      ),
    );
    final file = File('${dir.path}/$id.grdn');
    await file.writeAsBytes(bytes, flush: true);
    return LibraryEntry(
      scenarioId: id,
      name: name,
      description: description,
      author: author,
      source: ScenarioSource.mine,
      locked: false,
      premium: false,
      playersMin: scenario.playersMin,
      playersMax: scenario.playersMax,
      bytes: bytes,
      scenario: scenario,
    );
  }

  Future<void> delete(String scenarioId) async {
    final dir = await _userDir();
    final file = File('${dir.path}/$scenarioId.grdn');
    if (file.existsSync()) await file.delete();
  }

  Future<Directory> _userDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/scenarios');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  String _newUuid() {
    final rnd = DateTime.now().microsecondsSinceEpoch;
    final hex = rnd.toRadixString(16).padLeft(12, '0');
    return '$hex-${hex.substring(0, 4)}-4${hex.substring(1, 4)}-8${hex.substring(2, 5)}-${hex.substring(3, 11)}${hex.substring(0, 1)}'.substring(0, 36);
  }
}

/// سناریوی انتخاب‌شده در راه‌اندازی میزگرد (از کتابخانه)
final selectedScenarioProvider = StateProvider<String?>((ref) => null);

/// کتابخانه کامل — باندل + من (بارگذاری یک‌بار)
final scenarioLibraryProvider =
    FutureProvider<List<LibraryEntry>>((ref) async {
  final store = const ScenarioStore();
  final bundled = await store.loadBundled();
  final mine = await store.loadMine();
  return [...bundled, ...mine];
});
