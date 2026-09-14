# 📦 scenario-format.md — مشخصات کامل فرمت `.grdn`

> فرمت فایل سناریوی گردون — نسخه ۱.۰
> هر فایل `.grdn` یک سناریوی کامل بازی مافیا است: نقش‌ها، قوانین، فازها، شرط برد و دارایی‌ها.

---

## ۱. کلیات

| مورد | مقدار |
|------|--------|
| پسوند | `.grdn` |
| نوع کانتینر | ZIP (استاندارد، بدون رمز) |
| MIME | `application/x-gardoon-scenario` |
| انکودینگ JSON | UTF-8 |
| اعداد | همه int/double (نه رشته) |
| جهت متن‌ها | رشته‌های فارسی آزاد — ذخیره as-is |

### ساختار ZIP

```
my-scenario.grdn
├── manifest.grdn.json    ← مشخصات + نسخه + checksum
├── data.grdn.json        ← کل داده سناریو
├── assets/
│   ├── icons/            ← آیکون‌های سفارشی (png/webp — حداکثر 512×512)
│   ├── sounds/           ← صداهای سفارشی (ogg/mp3)
│   └── frames/           ← قاب‌های سفارشی کارت‌ها
└── (بدون فایل اضافه — هر فایل ناشناخته هنگام خواندن نادیده گرفته می‌شود)
```

**محدودیت حجم فایل:** ۵ مگابایت (تا QR هم شدنی بماند).

---

## ۲. `manifest.grdn.json`

```json
{
  "format": "GRDN",
  "formatVersion": 1,
  "appMinVersion": "1.0.0",
  "scenarioId": "550e8400-e29b-41d4-a716-446655440000",
  "name": "مافیا کلاسیک تهران",
  "description": "همان مافیای همیشگی، تمیز و متعادل",
  "author": "علی",
  "createdAt": "2025-06-15T10:30:00Z",
  "updatedAt": "2025-06-20T18:00:00Z",
  "playersMin": 6,
  "playersMax": 15,
  "locked": false,
  "premium": false,
  "checksum": "sha256:9f2c1a..."
}
```

| فیلد | نوع | اجباری | توضیح |
|------|-----|:---:|--------|
| `format` | string | ✅ | همیشه `"GRDN"` — امضای فرمت |
| `formatVersion` | int | ✅ | نسخه اسکیما — فعلاً `1` |
| `appMinVersion` | string | ✅ | کمترین نسخه اپ که این فایل را می‌فهمد (semver) |
| `scenarioId` | uuid | ✅ | یکتا و ثابت تا عمر سناریو — هویت در کتابخانه |
| `name` | string | ✅ | ۱ تا ۶۰ کاراکتر |
| `description` | string | ❌ | تا ۳۰۰ کاراکتر |
| `author` | string | ✅ | نام سازنده |
| `locked` | bool | ✅ | `true` = نقش‌ها تا لحظه بازی مخفی (سناریوی سورپرایز) |
| `premium` | bool | ✅ | `true` = باز شدن فقط با گردون طلایی یا تماشای تبلیغ |
| `checksum` | string | ✅ | SHA-256 از محتوای `data.grdn.json` — سلامت فایل |

---

## ۳. `data.grdn.json` — نقشه کامل

```json
{
  "meta":        { ... },
  "teams":       [ ... ],
  "roles":       [ ... ],
  "flow":        { ... },
  "phases":      [ ... ],
  "rules":       { ... },
  "winConditions": [ ... ],
  "events":      [ ... ]
}
```

---

### ۳.۱ `meta`

```json
{
  "icon": "builtin:fedora",
  "color": "#1B2A4A",
  "language": "fa",
  "defaultTimers": { "night": 60, "dawn": 15, "discussion": 180, "vote": 30 }
}
```

- `icon` — دو شکل: `builtin:نام` (آیکون داخلی اپ) یا `asset:icons/x.png` (فایل داخل ZIP)

---

### ۳.۲ `teams` — تیم‌ها

```json
[
  { "id": "city",       "name": "شهر",     "color": "#2E7D32", "icon": "builtin:dove"  },
  { "id": "mafia",      "name": "مافیا",   "color": "#B71C1C", "icon": "builtin:fedora"},
  { "id": "cult",       "name": "فرقه",    "color": "#6A1B9A", "icon": "builtin:candle"}
]
```

- حداقل ۲ تیم، حداکثر ۶ تیم
- `id` یکتا (lowercase-latin، بدون فاصله)

---

### ۳.۳ `roles` — نقش‌ها ⭐ قلب سناریو

```json
{
  "id": "detective",
  "name": "کارآگاه",
  "team": "city",
  "count": 1,
  "icon": "builtin:magnifier",
  "cardColor": "#1565C0",
  "cardFrame": "builtin:classic",
  "priority": 30,
  "knownTo": ["city"],
  "description": "هر شب یک نفر را بازرسی کن و بفهم مافیا است یا نه.",
  "deathReveal": "role",
  "abilities": [ /* آرایه بلوک‌های توانایی — بخش ۳.۴ */ ]
}
```

| فیلد | توضیح |
|------|--------|
| `team` | id تیم از بخش teams |
| `count` | چند کارت از این نقش در دسته است |
| `priority` | جایگاه بیداری شب — عدد ۱۰ تا ۹۰۰؛ مضرب ۱۰ برای جا بازکردن بین نقش‌ها |
| `knownTo` | چه کسی هویت این نقش را می‌داند: لیست `team:تیم` یا `role:نقش` — مثال: مافیا `["mafia"]` یعنی هم‌تیمی‌هایش او را می‌بینند |
| `deathReveal` | هنگام مرگ چه فاش شود: `"role"` نقش کامل / `"team"` فقط تیم / `"nothing"` هیچ |
| `abilities` | آرایه بلوک‌ها — می‌تواند خالی باشد (شهروند ساده) |

---

### ۳.۴ بلوک توانایی (`abilities[]`) — کامل‌ترین بخش فرمت

```json
{
  "id": "inspect-1",
  "type": "inspect",
  "name": "بازرسی",
  "enabled": true,

  "targeting": {
    "count": 1,
    "scope": "alive",
    "selfAllowed": false,
    "sameTeamAllowed": false,
    "repeatTarget": true,
    "mustNotBe": ["godfather"]
  },

  "timing": {
    "when": "night",
    "everyNights": 1,
    "cooldown": 0,
    "usesTotal": -1,
    "onlyNightNumbers": [],
    "notNightNumbers": [1]
  },

  "effect": {
    "resultMode": "team",
    "customResultText": "",
    "bypassProtection": false,
    "bypassImmunity": false,
    "onBlockedResult": "blocked"
  },

  "messages": {
    "success": "کارآگاه نتیجه بازرسی را دریافت کرد",
    "blocked": "بازرسی به نتیجه نرسید"
  },

  "wakeGroup": 1
}
```

#### انواع بلوک (`type`):

| type | نام | کاربرد |
|------|-----|--------|
| `attack` | حمله | کشتن/زخمی کردن هدف |
| `save` | نجات | نجات هدف از حمله این شب |
| `inspect` | بازرسی | کسب اطلاعات از هدف |
| `protect` | محافظت | سپر برای هدف |
| `silence` | سکوت | قطع گفتگوی هدف در روز بعد |
| `roleblock` | مسدودسازی | خنثی کردن اکشن‌های هدف |
| `convert` | تبدیل | تغییر تیم/نقش هدف |
| `voteWeight` | وزن رأی | رأی هدف =N رأی |
| `loveLink` | پیوند عشق | مرگ مشترک دو نفر |
| `immunity` | مصونیت | ضد بازرسی (گودفادر) |
| `revenge` | انتقام | حمله پس از مرگ |
| `reveal` | مکاشفه | فاش شدن نقش پس از مرگ |
| `transfer` | واگذاری | انتقال نقش به دیگری |
| `custom` | سفارشی | فقط پیام/نمایش برای گرداننده |

#### توضیح فیلدهای خاص:

**`targeting`:**
- `scope`: `"alive"` | `"all"` | `"team:mafia"` | `"role:doctor"` | `"dead"`
- `usesTotal`: `-1` = بی‌نهایت
- `mustNotBe`: هدف نمی‌تواند این نقش‌ها باشد (بازرسی گودفادر را مافیا نشان می‌دهد ولی تیرانداز نمی‌تواند به او شلیک کند و...)

**`timing`:**
- `everyNights`: `2` = یک شب در میان
- `cooldown`: بعد از استفاده، چند شب غیرفعال
- `onlyNightNumbers`: `[1]` = فقط شب ۱ | `notNightNumbers`: `[1]` = همه شب‌ها جز ۱

**`effect`:**
- `resultMode` (برای inspect): `"team"` مافیا/شهر | `"exact"` نقش دقیق | `"custom"` متن دلخواه
- `bypassProtection`: حمله این بلوک از محافظت عبور می‌کند (تک‌تیرانداز)
- `onBlockedResult`: وقتی هدف محافظت/مصونیت دارد، چه گزارش شود

**`wakeGroup`:** نقش‌هایی با `wakeGroup` یکسان **هم‌زمان** بیدار می‌شوند (مافیاها با هم).

---

### ۳.۵ `flow` — ترتیب فازها و چرخه

```json
{
  "cycle": ["night", "dawn", "day", "vote"],
  "zeroNight": true,
  "repeatFrom": "night"
}
```

- `cycle`: ترتیب فازهای هر گردش — اشاره به id فازهای بخش ۳.۶
- `zeroNight`: شب صفر (آشنایی) داشته باشد؟
- `repeatFrom`: چرخه از کجا تکرار شود

---

### ۳.۶ `phases` — تعریف هر فاز

```json
{
  "id": "night",
  "name": "شب",
  "kind": "night",
  "sound": "builtin:wolves",
  "autoWakeByPriority": true,
  "wakeList": ["mafia*", "doctor", "detective"],
  "timer": 90
}
```

| kind | رفتار |
|------|-------|
| `night` | اجرای بیداری‌ها بر اساس wakeList/اولویت |
| `dawn` | اعلام نتایج شب (مردها) |
| `day` | بحث آزاد + تایمر |
| `vote` | رأی‌گیری |
| `custom` | فقط تایمر و صدا — برای فازهای خاص (محاکمه و...) |

`wakeList`: ترتیب صریح بیداری — `"mafia*"` یعنی همه نقش‌های تیم مافیا یکجا.

---

### ۳.۷ `rules` — قوانین کلی بازی

```json
{
  "firstNightKill": false,
  "showTeamAtStart": true,
  "deadCanSpeak": false,
  "lastWords": { "enabled": true, "seconds": 30 },
  "vote": {
    "mode": "majority",
    "tieBreak": "revote",
    "abstain": true,
    "showCounts": true,
    "eliminatedReveal": "role"
  },
  "doctor": {
    "selfSave": false,
    "sameTargetTwice": false
  },
  "audio": { "phaseChange": true, "death": "builtin:gunshot" }
}
```

> `doctor` و شبیه‌ها shortcutهای سطح ۱ هستند که بلوک‌های نقش را override می‌کنند — برای سناریوساز ساده.

---

### ۳.۸ `winConditions` — شرط‌های برد

```json
[
  {
    "team": "mafia",
    "join": "AND",
    "terms": [
      { "left": "aliveCount:mafia", "op": ">=", "right": "aliveCount:city" }
    ]
  },
  {
    "team": "city",
    "join": "AND",
    "terms": [
      { "left": "aliveCount:mafia", "op": "==", "right": "0" }
    ]
  },
  {
    "team": "cult",
    "join": "AND",
    "terms": [
      { "left": "aliveCount:cult",  "op": ">=", "right": "2" },
      { "left": "round",            "op": ">=", "right": "5" }
    ]
  }
]
```

**عملوندهای مجاز (`left`/`right`):**
`aliveCount:تیم` • `aliveCount:role:نقش` • `aliveTotal` • `round` • `constant` (عدد)

**عملگرها (`op`):** `==` • `!=` • `>` • `<` • `>=` • `<=`

این دقیقاً همان چیزی است که بلوک‌ساز شرط‌برد بصری (سطح ۳) در پشت صحنه می‌سازد — کاربر تراشه می‌چیند، فلاتر این JSON را تولید می‌کند.

---

### ۳.۹ `events` — رویدادهای تصادفی (سطح ۴)

```json
{
  "id": "blackout",
  "name": "قطعی برق",
  "description": "امشب هیچ نتیجه‌ای اعلام نمی‌شود",
  "weight": 2,
  "frequency": { "fromRound": 2, "everyRounds": 3, "maxPerGame": 1 },
  "effects": { "hideDawnResults": true },
  "sound": "builtin:thunder"
}
```

- دک رویداد: در شروع هر گردش، بر اساس `weight` یکی قرعه‌کشی می‌شود
- `effects`: پرچم‌های آماده (`hideDawnResults`, `silenceOneRandom`, `doubleAttack`, `noVote`, ...)

---

## ۴. اعتبارسنجی — قوانین سخت (خطا) و نرم (هشدار)

### 🔴 خطا — فایل ذخیره/خروجی نمی‌شود:
- `teams` کمتر از ۲
- هر `role.team` به تیمی ناموجود اشاره کند
- مجموع `count` نقش‌ها خارج از بازه `playersMin..playersMax`
- هر بلوک با `when: night` ولی نقش بدون جایگاه در wakeList فاز شب
- `winConditions` خالی یا شرط برای تیم بدون عضو
- دو `id` تکراری در هر سطح
- `priority` خارج از ۱۰..۹۰۰

### 🟡 هشدار — مجاز ولی گوشزد می‌شود:
- تیمی بدون هیچ بلوک حمله (بردش ناممکن است)
- نسبت قدرت تخمینی نامتوازن (وزن بلوک‌ها: attack=3، save=2، inspect=2، protect=2، بقیه=1)
- `usesTotal=1` روی بلوک با `cooldown>0` (تناقض احتمالی)
- `everyNights>1` بدون تعریف در `notNightNumbers` شب اول

---

## ۵. نسخه‌بندی و Migration

- هر تغییر ناسازگار در این اسکیما → `formatVersion` +۱
- زنجیره migration در `lib/grdn/migration/`:
  ```dart
  abstract class GrdnMigration {
    int get from; int get to;
    Map<String, dynamic> migrate(Map<String, dynamic> json);
  }
  // خواننده: تا رسیدن به نسخه فعلی، مهاجرها را به‌ترتیب اجرا می‌کند
  ```
- قانون آهنین: **migration فقط افزودنی/تغییردهنده است — هرگز داده کاربر را حذف نمی‌کند**

---

## ۶. QR — اشتراک بدون فایل

```
فایل .grdn (بدون assets)
  → gzip → Base64 → prefix "GRDN1:" → QR
```
- سقف عملی QR: ~۲.۵ کیلوبایت پس از فشرده‌سازی — سناریوهای فقط-متنی
- سناریوهای با asset → فقط اشتراک فایل

---

## ۷. مثال کامل: سناریوی حداقلی ۶ نفره

```json
{
  "meta": { "icon": "builtin:fedora", "color": "#1B2A4A", "language": "fa",
            "defaultTimers": { "night": 45, "dawn": 15, "discussion": 120, "vote": 30 } },
  "teams": [
    { "id": "city",  "name": "شهر",   "color": "#2E7D32", "icon": "builtin:dove"   },
    { "id": "mafia", "name": "مافیا", "color": "#B71C1C", "icon": "builtin:fedora" }
  ],
  "roles": [
    { "id": "mafia", "name": "مافیا", "team": "mafia", "count": 2, "icon": "builtin:fedora",
      "cardColor": "#B71C1C", "cardFrame": "builtin:classic", "priority": 10,
      "knownTo": ["mafia"], "deathReveal": "role",
      "description": "هر شب با هم‌تیمی‌ات یکی را بکش.",
      "abilities": [ { "id": "k1", "type": "attack", "name": "کشتن", "enabled": true,
        "targeting": { "count": 1, "scope": "alive", "selfAllowed": false,
                       "sameTeamAllowed": false, "repeatTarget": true, "mustNotBe": [] },
        "timing": { "when": "night", "everyNights": 1, "cooldown": 0, "usesTotal": -1,
                     "onlyNightNumbers": [], "notNightNumbers": [0] },
        "effect": { "resultMode": "team", "customResultText": "",
                     "bypassProtection": false, "bypassImmunity": false, "onBlockedResult": "blocked" },
        "messages": { "success": "", "blocked": "" }, "wakeGroup": 1 } ] },
    { "id": "doctor", "name": "دکتر", "team": "city", "count": 1, "icon": "builtin:cross",
      "cardColor": "#2E7D32", "cardFrame": "builtin:classic", "priority": 20,
      "knownTo": [], "deathReveal": "role",
      "description": "هر شب یک نفر را نجات بده.",
      "abilities": [ { "id": "s1", "type": "save", "name": "نجات", "enabled": true,
        "targeting": { "count": 1, "scope": "alive", "selfAllowed": true,
                       "sameTeamAllowed": true, "repeatTarget": true, "mustNotBe": [] },
        "timing": { "when": "night", "everyNights": 1, "cooldown": 0, "usesTotal": -1,
                     "onlyNightNumbers": [], "notNightNumbers": [0] },
        "effect": { "resultMode": "team", "customResultText": "",
                     "bypassProtection": false, "bypassImmunity": false, "onBlockedResult": "blocked" },
        "messages": { "success": "", "blocked": "" }, "wakeGroup": 2 } ] },
    { "id": "citizen", "name": "شهروند", "team": "city", "count": 3, "icon": "builtin:person",
      "cardColor": "#37474F", "cardFrame": "builtin:classic", "priority": 900,
      "knownTo": [], "deathReveal": "nothing",
      "description": "با استدلال مافیاها را پیدا کن.",
      "abilities": [] }
  ],
  "flow": { "cycle": ["night", "dawn", "day", "vote"], "zeroNight": true, "repeatFrom": "night" },
  "phases": [
    { "id": "night", "name": "شب", "kind": "night", "sound": "builtin:wolves",
      "autoWakeByPriority": true, "wakeList": ["mafia*", "doctor", "citizen"], "timer": 45 },
    { "id": "dawn",  "name": "سپیده‌دم", "kind": "dawn", "sound": "builtin:rooster",
      "autoWakeByPriority": false, "wakeList": [], "timer": 15 },
    { "id": "day",   "name": "روز", "kind": "day", "sound": "builtin:bell",
      "autoWakeByPriority": false, "wakeList": [], "timer": 120 },
    { "id": "vote",  "name": "رأی‌گیری", "kind": "vote", "sound": "builtin:drum",
      "autoWakeByPriority": false, "wakeList": [], "timer": 30 }
  ],
  "rules": {
    "firstNightKill": false, "showTeamAtStart": true, "deadCanSpeak": false,
    "lastWords": { "enabled": true, "seconds": 30 },
    "vote": { "mode": "majority", "tieBreak": "revote", "abstain": true,
               "showCounts": true, "eliminatedReveal": "role" },
    "doctor": { "selfSave": true, "sameTargetTwice": true },
    "audio": { "phaseChange": true, "death": "builtin:gunshot" }
  },
  "winConditions": [
    { "team": "city",  "join": "AND",
      "terms": [ { "left": "aliveCount:mafia", "op": "==", "right": "0" } ] },
    { "team": "mafia", "join": "AND",
      "terms": [ { "left": "aliveCount:mafia", "op": ">=", "right": "aliveCount:city" } ] }
  ],
  "events": []
}
```
