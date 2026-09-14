#!/usr/bin/env python3
"""ساخت ۵ سناریوی پیش‌فرض گردون با فرمت .grdn (ZIP + checksum)"""
import json, hashlib, io, os, zipfile, uuid

OUT = "/home/z/my-project/gardoon/assets/scenarios"
os.makedirs(OUT, exist_ok=True)

def block(bid, btype, name, *, count=1, scope="alive", self_allowed=False,
          same_team=False, must_not=None, not_nights=(0,), bypass=False,
          bypass_imm=False, result_mode="team", blocked_result="blocked",
          custom_text="", wake_group=1, uses=-1, cooldown=0, every=1):
    return {
        "id": bid, "type": btype, "name": name, "enabled": True,
        "targeting": {"count": count, "scope": scope, "selfAllowed": self_allowed,
                      "sameTeamAllowed": same_team, "repeatTarget": True,
                      "mustNotBe": must_not or []},
        "timing": {"when": "night", "everyNights": every, "cooldown": cooldown,
                   "usesTotal": uses, "onlyNightNumbers": [],
                   "notNightNumbers": list(not_nights)},
        "effect": {"resultMode": result_mode, "customResultText": custom_text,
                   "bypassProtection": bypass, "bypassImmunity": bypass_imm,
                   "onBlockedResult": blocked_result},
        "messages": {"success": "", "blocked": ""}, "wakeGroup": wake_group,
    }

def attack(name, **kw):  return block(name + "-b1", "attack", "کشتن", wake_group=1, **kw)
def save(name):          return block(name + "-b1", "save", "نجات", self_allowed=True, same_team=True, wake_group=2)
def inspect(name, mode="team"): return block(name + "-b1", "inspect", "بازرسی", result_mode=mode, wake_group=3)
def protect(name):       return block(name + "-b1", "protect", "محافظت", self_allowed=True, same_team=True, wake_group=4)
def immunity(name):      return block(name + "-b2", "immunity", "مصونیت", count=0, scope="self", self_allowed=True, same_team=True, not_nights=[], blocked_result="custom", custom_text="مافیا است", wake_group=0)
def convert(name):       return block(name + "-b1", "convert", "جذب", wake_group=2)
def revenge(name):       return block(name + "-b1", "revenge", "انتقام", wake_group=5)
def love(name):          return block(name + "-b1", "loveLink", "پیوند عشق", wake_group=5)

CITY = {"id": "city", "name": "شهر", "color": "#2E7D32", "icon": "builtin:dove"}
MAFIA = {"id": "mafia", "name": "مافیا", "color": "#B71C1C", "icon": "builtin:fedora"}
CULT = {"id": "cult", "name": "فرقه", "color": "#6A1B9A", "icon": "builtin:candle"}

def role(rid, name, team, count, icon, color, priority, desc, abilities, known=None):
    return {"id": rid, "name": name, "team": team, "count": count, "icon": icon,
            "cardColor": color, "cardFrame": "builtin:classic", "priority": priority,
            "knownTo": known or [], "description": desc, "abilities": abilities}

def phases(wake, night_t=45, dawn_t=15, day_t=120, vote_t=30):
    return [
        {"id": "night", "name": "شب", "kind": "night", "sound": "builtin:wolves",
         "autoWakeByPriority": True, "wakeList": wake, "timer": night_t},
        {"id": "dawn", "name": "سپیده‌دم", "kind": "dawn", "sound": "builtin:rooster",
         "autoWakeByPriority": False, "wakeList": [], "timer": dawn_t},
        {"id": "day", "name": "روز", "kind": "day", "sound": "builtin:bell",
         "autoWakeByPriority": False, "wakeList": [], "timer": day_t},
        {"id": "vote", "name": "رأی‌گیری", "kind": "vote", "sound": "builtin:drum",
         "autoWakeByPriority": False, "wakeList": [], "timer": vote_t},
    ]

RULES = {
    "firstNightKill": False, "showTeamAtStart": True, "deadCanSpeak": False,
    "lastWords": {"enabled": True, "seconds": 30},
    "vote": {"mode": "majority", "tieBreak": "revote", "abstain": True,
             "showCounts": True, "eliminatedReveal": "role"},
    "doctor": {"selfSave": True, "sameTargetTwice": False},
    "audio": {"phaseChange": True, "death": "builtin:gunshot"},
}

def win_std():
    return [
        {"team": "city", "join": "AND",
         "terms": [{"left": "aliveCount:mafia", "op": "==", "right": "0"}]},
        {"team": "mafia", "join": "AND",
         "terms": [{"left": "aliveCount:mafia", "op": ">=", "right": "aliveCount:city"}]},
    ]

def win_with_cult():
    return win_std() + [{
        "team": "cult", "join": "AND",
        "terms": [{"left": "aliveCount:cult", "op": ">=", "right": "2"},
                  {"left": "round", "op": ">=", "right": "5"}]}]

def scenario(teams, roles, wake, first_kill=False, rules_doctor=None):
    rules = json.loads(json.dumps(RULES))
    rules["firstNightKill"] = first_kill
    if rules_doctor is not None:
        rules["doctor"] = rules_doctor
    return {
        "meta": {"icon": "builtin:fedora", "color": "#1B2A4A", "language": "fa",
                 "defaultTimers": {"night": 45, "dawn": 15, "discussion": 120, "vote": 30}},
        "teams": teams, "roles": roles,
        "flow": {"cycle": ["night", "dawn", "day", "vote"], "zeroNight": True, "repeatFrom": "night"},
        "phases": phases(wake), "rules": rules,
        "winConditions": win_with_cult() if any(t["id"] == "cult" for t in teams) else win_std(),
        "events": [],
    }

def citizen(n=2):
    return role("citizen", "شهروند", "city", n, "builtin:person", "#37474F", 900,
                "با استدلال مافیاها را پیدا کن.", [])

SCENARIOS = []

# ۱) مافیا کلاسیک تهران — ۶ تا ۱۵ نفر
SCENARIOS.append({
    "file": "classic_tehran.grdn",
    "id": str(uuid.uuid5(uuid.NAMESPACE_URL, "gardoon:classic-tehran")),
    "name": "مافیا کلاسیک تهران",
    "description": "همان مافیای همیشگی، تمیز و متعادل — با کارآگاه و دکتر",
    "author": "گردون",
    "locked": False, "premium": False, "min": 6, "max": 15,
    "data": scenario(
        [CITY, MAFIA],
        [
            role("mafia", "مافیا", "mafia", 2, "builtin:fedora", "#B71C1C", 10,
                 "هر شب با هم‌تیمی‌ات یکی را بکش.", [attack("mafia")], ["mafia"]),
            role("detective", "کارآگاه", "city", 1, "builtin:magnifier", "#1565C0", 20,
                 "هر شب یک نفر را بازرسی کن و بفهم مافیا است یا نه.", [inspect("detective")]),
            role("doctor", "دکتر", "city", 1, "builtin:cross", "#2E7D32", 30,
                 "هر شب یک نفر را نجات بده.", [save("doctor")]),
            citizen(2),
        ],
        ["mafia*", "doctor", "detective"],
    ),
})

# ۲) مافیای حرفه‌ای — ۸ تا ۱۶ نفر
SCENARIOS.append({
    "file": "professional.grdn",
    "id": str(uuid.uuid5(uuid.NAMESPACE_URL, "gardoon:professional")),
    "name": "مافیای حرفه‌ای",
    "description": "گودفادر با مصونیت، تک‌تیرانداز و محافظ — بازی جدی‌تر",
    "author": "گردون",
    "locked": False, "premium": False, "min": 8, "max": 16,
    "data": scenario(
        [CITY, MAFIA],
        [
            role("godfather", "گودفادر", "mafia", 1, "builtin:fedora", "#7B1113", 10,
                 "رئیس مافیا — بازرسی روی او جواب نمی‌دهد.",
                 [attack("godfather"), immunity("godfather")], ["mafia"]),
            role("mafia", "مافیا", "mafia", 1, "builtin:gun", "#B71C1C", 12,
                 "هر شب با گودفادر یکی را بکش.", [attack("mafia")], ["mafia"]),
            role("sniper", "تک‌تیرانداز", "city", 1, "builtin:gun", "#1565C0", 15,
                 "تیرش از محافظت عبور می‌کند — فقط دو تیر داری.",
                 [block("sniper-b1", "attack", "شلیک", bypass=True, uses=2)]),
            role("detective", "کارآگاه", "city", 1, "builtin:magnifier", "#1565C0", 25,
                 "هر شب یک نفر را بازرسی کن.", [inspect("detective")]),
            role("doctor", "دکتر", "city", 1, "builtin:cross", "#2E7D32", 30,
                 "هر شب یک نفر را نجات بده.", [save("doctor")]),
            role("guard", "محافظ", "city", 1, "builtin:shield", "#00695C", 35,
                 "هر شب سپر یک نفر را نگه می‌داری.", [protect("guard")]),
            citizen(2),
        ],
        ["mafia*", "sniper", "doctor", "detective", "guard"],
    ),
})

# ۳) فرقه تاریکی — ۱۰ تا ۱۶ نفر
SCENARIOS.append({
    "file": "cult_darkness.grdn",
    "id": str(uuid.uuid5(uuid.NAMESPACE_URL, "gardoon:cult-darkness")),
    "name": "فرقه تاریکی",
    "description": "فرقه شهروندها را جذب می‌کند — سه‌طرفه و پرتنش",
    "author": "گردون",
    "locked": False, "premium": False, "min": 10, "max": 16,
    "data": scenario(
        [CITY, MAFIA, CULT],
        [
            role("mafia", "مافیا", "mafia", 2, "builtin:fedora", "#B71C1C", 10,
                 "هر شب با هم‌تیمی‌ات یکی را بکش.", [attack("mafia")], ["mafia"]),
            role("cultist", "فرقه‌ای", "cult", 1, "builtin:candle", "#6A1B9A", 15,
                 "هر شب یک نفر را به فرقه جذب کن.",
                 [convert("cultist")], ["cult"]),
            role("detective", "کارآگاه", "city", 1, "builtin:magnifier", "#1565C0", 25,
                 "هر شب یک نفر را بازرسی کن.", [inspect("detective")]),
            role("doctor", "دکتر", "city", 1, "builtin:cross", "#2E7D32", 30,
                 "هر شب یک نفر را نجات بده.", [save("doctor")]),
            citizen(5),
        ],
        ["mafia*", "cult*", "doctor", "detective"],
    ),
})

# ۴) کنستانتین — ویژه (طلایی)
SCENARIOS.append({
    "file": "constantine.grdn",
    "id": str(uuid.uuid5(uuid.NAMESPACE_URL, "gardoon:constantine")),
    "name": "کنستانتین",
    "description": "انتقام و پیوند عشق — هر شب عواقب دارد",
    "author": "گردون",
    "locked": False, "premium": True, "min": 8, "max": 14,
    "data": scenario(
        [CITY, MAFIA],
        [
            role("godfather", "گودفادر", "mafia", 1, "builtin:fedora", "#7B1113", 10,
                 "رئیس مافیا — بازرسی روی او جواب نمی‌دهد.",
                 [attack("godfather"), immunity("godfather")], ["mafia"]),
            role("mafia", "مافیا", "mafia", 1, "builtin:gun", "#B71C1C", 12,
                 "هر شب با گودفادر یکی را بکش.", [attack("mafia")], ["mafia"]),
            role("constantine", "کنستانتین", "city", 1, "builtin:fire", "#8D6E63", 15,
                 "نشانش را روی یک نفر می‌گذارد؛ اگر بمیرد، نشان‌شده هم می‌میرد.",
                 [revenge("constantine")]),
            role("lover", "عاشق", "city", 1, "builtin:heart", "#AD1457", 20,
                 "هر شب پیوند عشق می‌بندد؛ مرگ یکی، دیگری را هم می‌برد.",
                 [love("lover")]),
            role("detective", "کارآگاه", "city", 1, "builtin:magnifier", "#1565C0", 25,
                 "هر شب یک نفر را بازرسی کن.", [inspect("detective")]),
            role("doctor", "دکتر", "city", 1, "builtin:cross", "#2E7D32", 30,
                 "هر شب یک نفر را نجات بده.", [save("doctor")]),
            citizen(2),
        ],
        ["mafia*", "city*"],
    ),
})

# ۵) شهر بی‌رحم — ویژه (طلایی)
SCENARIOS.append({
    "file": "merciless_city.grdn",
    "id": str(uuid.uuid5(uuid.NAMESPACE_URL, "gardoon:merciless-city")),
    "name": "شهر بی‌رحم",
    "description": "شب اول کشتن دارد و هیچ دکتری نیست — فقط حرف و حداکثر استدلال",
    "author": "گردون",
    "locked": False, "premium": True, "min": 6, "max": 12,
    "data": scenario(
        [CITY, MAFIA],
        [
            role("mafia", "مافیا", "mafia", 2, "builtin:fedora", "#B71C1C", 10,
                 "از همان شب اول می‌کشی.", [attack("mafia")], ["mafia"]),
            role("sniper", "تک‌تیرانداز", "city", 1, "builtin:gun", "#1565C0", 15,
                 "تیرش از محافظت عبور می‌کند — فقط دو تیر داری.",
                 [block("sniper-b1", "attack", "شلیک", bypass=True, uses=2)]),
            citizen(3),
        ],
        ["mafia*", "sniper"],
        first_kill=True,
        rules_doctor={"selfSave": False, "sameTargetTwice": False},
    ),
})

def write_grdn(sc):
    data = json.dumps(sc["data"], ensure_ascii=False, indent=1, separators=(",", ": ")).encode("utf-8")
    checksum = "sha256:" + hashlib.sha256(data).hexdigest()
    manifest = {
        "format": "GRDN", "formatVersion": 1, "appMinVersion": "1.0.0",
        "scenarioId": sc["id"], "name": sc["name"], "description": sc["description"],
        "author": sc["author"], "createdAt": "2025-09-01T10:00:00Z",
        "updatedAt": "2025-09-01T10:00:00Z",
        "playersMin": sc["min"], "playersMax": sc["max"],
        "locked": sc["locked"], "premium": sc["premium"], "checksum": checksum,
    }
    mb = json.dumps(manifest, ensure_ascii=False, indent=1, separators=(",", ": ")).encode("utf-8")
    path = os.path.join(OUT, sc["file"])
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("manifest.grdn.json", mb)
        z.writestr("data.grdn.json", data)
    print("wrote", path, os.path.getsize(path), "bytes")

for sc in SCENARIOS:
    write_grdn(sc)
print("done")
