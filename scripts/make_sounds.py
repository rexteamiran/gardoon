#!/usr/bin/env python3
"""تولید افکت‌های صوتی داخلی گردون (WAV های کوچک و سبک)"""
import math, os, random, struct, wave

SR = 22050
OUT = "/home/z/my-project/gardoon/assets/sounds"
os.makedirs(OUT, exist_ok=True)
rnd = random.Random(42)

def write(name, samples):
    path = os.path.join(OUT, name)
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(
            struct.pack("<h", max(-32767, min(32767, int(s * 32767)))) for s in samples))
    print(name, len(samples) / SR, "s", os.path.getsize(path), "bytes")

def env(t, dur, attack=0.005, release=0.05):
    if t < attack:
        return t / attack
    if t > dur - release:
        return max(0.0, (dur - t) / release)
    return 1.0

def tone(freq, dur, vol=0.6, shape="sine", slide_to=None):
    out = []
    for i in range(int(SR * dur)):
        t = i / SR
        f = freq if slide_to is None else freq + (slide_to - freq) * (t / dur)
        v = math.sin(2 * math.pi * f * t)
        if shape == "square":
            v = 1 if v > 0 else -1
        out.append(v * vol * env(t, dur))
    return out

def silence(dur):
    return [0.0] * int(SR * dur)

def click(vol=0.5):
    out = []
    for i in range(int(SR * 0.02)):
        t = i / SR
        out.append((rnd.uniform(-1, 1)) * vol * (1 - t / 0.02))
    return out

def noise_burst(dur, vol=0.9):
    out = []
    for i in range(int(SR * dur)):
        t = i / SR
        out.append(rnd.uniform(-1, 1) * vol * math.exp(-t * 9))
    return out

# تپ — کلیک کوتاه
write("tap.wav", click(0.4) + silence(0.08))

# چرخش گردونه — امضای گردون: تق‌تق‌تق... تِرِق
seq = []
gaps = [0.16, 0.13, 0.10, 0.08, 0.06, 0.05, 0.04, 0.035]
for g in gaps:
    seq += click(0.55) + silence(g)
seq += click(0.7) + tone(520, 0.10, 0.35, slide_to=760)
write("wheel.wav", seq)

# شب — زمزمه تاریک
night = tone(180, 1.6, 0.4, slide_to=95)
night += tone(120, 0.8, 0.3, slide_to=70)
write("night.wav", night)

# سپیده‌دم — دو نت بالا رونده
dawn = tone(440, 0.5, 0.5) + tone(660, 0.7, 0.5)
write("dawn.wav", dawn)

# مرگ — صدای شلیک
write("death.wav", noise_burst(0.5) + silence(0.15) + tone(90, 0.25, 0.5, slide_to=45))

# رأی — طبل
vote = tone(140, 0.18, 0.8, slide_to=80) + silence(0.08) + tone(110, 0.3, 0.9, slide_to=60)
write("vote.wav", vote)

# برد — آرپژ طلایی
win = []
for f in [523, 659, 784, 1047]:
    win += tone(f, 0.28, 0.55)
win += tone(1047, 0.6, 0.5)
write("win.wav", win)
print("done")
