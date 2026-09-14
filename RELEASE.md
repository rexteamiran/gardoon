# 🚀 RELEASE.md — ساخت نسخه و انتشار

## وضعیت نسخه ۱.۰.۰ (MVP آفلاین)

طبق `roadmap.md` فازهای ۰ تا ۵ به‌علاوه فاز ۸ (خروجی APK) پیاده‌سازی شده است:

| فاز | وضعیت |
|-----|--------|
| ۰–۱ راه‌اندازی + اسکلت | ✅ |
| ۲ موتور بازی (state machine، action executor، win checker، نقش‌کشه، validator) | ✅ + تست |
| ۳ فرمت `.grdn` (ZIP + SHA-256 checksum + migration chain + intent filter) | ✅ + تست roundtrip |
| ۴ میزگرد (راه‌اندازی، نقش‌کشه، شب/سپیده‌دم/روز/رأی‌گیری، پایان) | ✅ |
| ۵ سناریوساز سطح ۱ (فرم‌محور، ترتیب بیداری، پریست شرط برد، پنل اعتبارسنجی + گیج ترازو) | ✅ |
| ۶ پرداخت کافه بازار / تبلیغ | 🔶 جای‌گاه (`PremiumGate` + فعال‌سازی محلی برای تست — انتظار اتصال درآمدی) |
| ۷ سناریوساز سطوح ۲–۴ | 🔶 گیت‌گذاری‌شده (طلایی) — در نسخه‌های بعد |
| ۸ خروجی APK + سناریوهای باندل + صداها + آیکون | ✅ |

## ساخت APK

```bash
flutter pub get
flutter build apk --release
# خروجی: build/app/outputs/flutter-apk/app-release.apk
```

- امضای فعلی: کلید debug (برای انتشار در کافه بازار/گوگل‌پلی، keystore اختصاصی بسازید و در
  `android/app/build.gradle.kts` بخش `buildTypes.release` معرفی کنید).
- APK نهایی fat (arm32 + arm64 + x86_64) — برای کاهش حجم می‌توانید `--split-per-abi` بزنید.

## اسکریپت‌های تولید دارایی

| اسکریپت | خروجی |
|---------|-------|
| `scripts/make_scenarios.py` | ۵ سناریوی `.grdn` باندل (۳ رایگان + ۲ ویژه) |
| `scripts/make_sounds.py` | ۷ افکت صوتی WAV (`assets/sounds/`) |
| `scripts/make_icon.py` | آیکون چرخ شب/روز در همه چگالی‌ها |

## نکات محیط بیلد این مخزن

اگر محیط شما NDK کامل ندارد، این پروژه با این تنظیمات بیلد می‌شود:
- `path_provider_android: 2.2.15` (بدون وابستگی C++ به `jni`)
- `flutter_plugin_android_lifecycle: 2.0.22` (سازگار با compileSdk 34)
- یک NDK «نشانگر» (stub) با `source.properties` برای راضی کردن بررسی AGP + `llvm-strip`
  واقعی (LLVM 17) در مسیر `toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip`
  (در محیط‌های استاندارد Android Studio این موارد لازم نیست).
