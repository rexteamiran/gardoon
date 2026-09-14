/// اعداد فارسی در UI — طبق agents.md بخش ۴ (اعداد فارسی همیشه)
library;

extension FaNumbers on int {
  String get fa {
    const digits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    if (this < 0) return '-${(-this).fa}';
    if (this < 10) return digits[this];
    return toString().split('').map((d) => digits[int.parse(d)]).join();
  }
}

extension FaNumbersString on String {
  String get fa {
    const en = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const fa = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    var out = this;
    for (var i = 0; i < en.length; i++) {
      out = out.replaceAll(en[i], fa[i]);
    }
    return out;
  }
}

/// ثانیه → «۰۲:۳۰» فارسی
String formatSeconds(int totalSeconds) {
  final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
  final s = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$m:$s'.fa;
}
