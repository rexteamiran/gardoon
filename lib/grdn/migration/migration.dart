/// مهاجرت نسخه‌های فرمت `.grdn`
///
/// قانون آهنین (scenario-format.md بخش ۵):
/// migration فقط افزودنی/تغییردهنده است — هرگز داده کاربر را حذف نمی‌کند.
library;

/// نسخه فعلی اسکیما — فعلاً ۱
const int kCurrentFormatVersion = 1;

/// قرارداد هر مهاجرت
abstract class GrdnMigration {
  int get from;
  int get to;

  Map<String, dynamic> migrate(Map<String, dynamic> json);
}

/// مهاجرت‌های ثبت‌شده — به‌ترتیب اجرا می‌شوند
const List<GrdnMigration> kMigrations = [
  // فعلاً خالی — با تغییر ناسازگار بعدی، v1_to_v2 اینجا اضافه می‌شود
];

class GrdnMigrator {
  const GrdnMigrator();

  Map<String, dynamic> migrate(
      Map<String, dynamic> json, int fromVersion, int toVersion) {
    var data = json;
    var version = fromVersion;
    while (version < toVersion) {
      final GrdnMigration? step = _find(version);
      if (step == null) break;
      data = step.migrate(data);
      version = step.to;
    }
    return data;
  }

  GrdnMigration? _find(int from) {
    for (final m in kMigrations) {
      if (m.from == from) return m;
    }
    return null;
  }
}
