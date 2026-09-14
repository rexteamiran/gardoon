#!/usr/bin/env python3
"""آیکون اپ گردون — چرخ دو نیمه شب و روز (design.md بخش ۱)"""
import math, os
from PIL import Image, ImageDraw

SIZES = {
    "mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192,
}
BASE = 1024  # بزرگ‌رندر و بعد کوچک کنی

def make_icon(size):
    img = Image.new("RGBA", (size, size), (13, 19, 33, 255))  # #0D1321
    d = ImageDraw.Draw(img)
    cx = cy = size / 2
    R = size * 0.36

    # نیمه شب (بالا)
    d.pieslice([cx - R, cy - R, cx + R, cy + R], 180, 360, fill=(20, 32, 60, 255))
    # نیمه روز (پایین)
    d.pieslice([cx - R, cy - R, cx + R, cy + R], 0, 180, fill=(240, 180, 41, 255))

    # ماه
    mr = R * 0.22
    mx, my = cx - R * 0.42, cy - R * 0.42
    d.ellipse([mx - mr, my - mr, mx + mr, my + mr], fill=(245, 239, 230, 255))
    # دهانه‌های ماه
    for (ox, oy, r) in [(0.35, -0.2, 0.15), (-0.3, 0.4, 0.12)]:
        cr = mr * r * 3
        d.ellipse([mx + mr * ox - cr, my + mr * oy - cr,
                   mx + mr * ox + cr, my + mr * oy + cr], fill=(224, 216, 204, 255))

    # ستاره‌ها
    for (sx, sy, sr) in [(0.45, -0.62, 0.045), (0.72, -0.32, 0.035), (0.12, -0.82, 0.03)]:
        star_r = R * sr
        sxp, syp = cx + R * sx, cy + R * sy
        d.ellipse([sxp - star_r, syp - star_r, sxp + star_r, syp + star_r],
                  fill=(255, 255, 255, 220))

    # خورشید
    sr_ = R * 0.2
    sxp, syp = cx, cy + R * 0.45
    d.ellipse([sxp - sr_, syp - sr_, sxp + sr_, syp + sr_], fill=(43, 33, 24, 255))
    for i in range(8):
        a = i * math.pi / 4
        x1 = sxp + R * 0.3 * math.cos(a)
        y1 = syp + R * 0.3 * math.sin(a)
        x2 = sxp + R * 0.42 * math.cos(a)
        y2 = syp + R * 0.42 * math.sin(a)
        d.line([x1, y1, x2, y2], fill=(43, 33, 24, 255), width=max(2, int(R * 0.05)))

    # خط مرز شب/روز
    d.line([cx - R, cy, cx + R, cy], fill=(200, 135, 26, 255), width=max(2, int(size * 0.008)))

    # حلقه بیرونی
    ring = max(3, int(R * 0.1))
    d.ellipse([cx - R, cy - R, cx + R, cy + R], outline=(200, 135, 26, 255), width=ring)

    # محور مرکزی طلایی
    hub = R * 0.18
    d.ellipse([cx - hub, cy - hub, cx + hub, cy + hub], fill=(200, 135, 26, 255))
    d.ellipse([cx - hub, cy - hub, cx + hub, cy + hub],
              outline=(43, 33, 24, 180), width=max(2, int(hub * 0.2)))

    return img

out_dir = "/home/z/my-project/gardoon/android/app/src/main/res"
base = make_icon(BASE)
for name, px in SIZES.items():
    folder = os.path.join(out_dir, f"mipmap-{name}")
    os.makedirs(folder, exist_ok=True)
    img = base.resize((px, px), Image.LANCZOS)
    img.save(os.path.join(folder, "ic_launcher.png"))
    img.save(os.path.join(folder, "ic_launcher_round.png"))
    print("mipmap-" + name, px)
print("icon done")
