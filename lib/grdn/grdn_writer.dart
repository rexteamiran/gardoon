/// ساخت فایل `.grdn` — ZIP + checksum
///
/// گردش کار طبق architecture.md بخش ۵:
/// مدل → json_codec → data.grdn.json → ZIP { manifest + data } → checksum
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';

import '../engine/json_codec.dart';
import '../engine/models/scenario.dart';

/// مشخصات سطح فایل — معادل manifest.grdn.json
class GrdnFileMeta {
  const GrdnFileMeta({
    required this.scenarioId,
    required this.name,
    this.description = '',
    this.author = 'گردون',
    this.locked = false,
    this.premium = false,
    this.createdAt,
    this.updatedAt,
  });

  final String scenarioId;
  final String name;
  final String description;
  final String author;
  final bool locked;
  final bool premium;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}

class GrdnWriter {
  const GrdnWriter();

  /// خروجی bytes فایل .grdn
  Uint8List write(GrdnScenario scenario, GrdnFileMeta meta) {
    final now = DateTime.now().toUtc().toIso8601String();
    final dataMap = const GrdnJsonCodec().encode(scenario);
    final dataBytes = utf8.encode(json.encode(dataMap));

    // checksum از محتوای data.grdn.json
    final checksum = 'sha256:${sha256.convert(dataBytes).toString()}';

    final manifest = <String, dynamic>{
      'format': 'GRDN',
      'formatVersion': 1,
      'appMinVersion': '1.0.0',
      'scenarioId': meta.scenarioId,
      'name': meta.name,
      'description': meta.description,
      'author': meta.author,
      'createdAt': meta.createdAt?.toUtc().toIso8601String() ?? now,
      'updatedAt': meta.updatedAt?.toUtc().toIso8601String() ?? now,
      'playersMin': scenario.playersMin,
      'playersMax': scenario.playersMax,
      'locked': meta.locked,
      'premium': meta.premium,
      'checksum': checksum,
    };
    final manifestBytes = utf8.encode(json.encode(manifest));

    final archive = Archive()
      ..addFile(ArchiveFile.bytes('manifest.grdn.json', manifestBytes))
      ..addFile(ArchiveFile.bytes('data.grdn.json', dataBytes));

    final zipped = ZipEncoder().encode(archive);
    return Uint8List.fromList(zipped);
  }
}
