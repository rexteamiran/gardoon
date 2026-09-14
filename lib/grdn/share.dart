/// اشتراک‌گذاری و ورود فایل .grdn
///
/// اشتراک: ذخیره موقت + intent اشتراک اندروید
/// ورود: انتخاب فایل از حافظه (تلگرام/فایل‌منیجر)
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'grdn_reader.dart';

class GrdnShare {
  const GrdnShare();

  /// اشتراک‌گذاری فایل سناریو (تلگرام، واتساپ، ...)
  Future<bool> shareFile({
    required Uint8List bytes,
    required String scenarioName,
  }) async {
    final dir = await getTemporaryDirectory();
    final safeName = scenarioName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '-');
    final file = File('${dir.path}/$safeName.grdn');
    await file.writeAsBytes(bytes, flush: true);
    final result = await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/x-gardoon-scenario')],
      text: 'سناریوی «$scenarioName» از گردون 🎡',
    );
    return result.status == ShareResultStatus.success;
  }

  /// انتخاب فایل .grdn از حافظه دستگاه — null = انصراف کاربر
  Future<GrdnReadResult?> pickAndRead() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['grdn'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return null;
    final data = picked.files.single.bytes;
    if (data == null) return null;
    return const GrdnReader().read(data);
  }
}
