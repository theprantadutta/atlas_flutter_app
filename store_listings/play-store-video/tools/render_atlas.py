"""Atlas Play Store promo video, landscape 1920x1080, Daylight (light) look.

Adapted from the Snake Classic renderer: captions on the left, the phone
recording on the right, an intro and an outro card, original music.
Usage: python render_atlas.py <ffmpeg.exe> <scenes.json> <music.wav> <out.mp4>
"""

import json
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

D = Path(__file__).parent
APP = Path(r"G:\Personal\MyProjects\atlas\atlas_flutter_app")
FONTS, BRAND = APP / "assets" / "fonts", APP / "assets" / "brand"
FF, SCENES, MUSIC, OUT = sys.argv[1:5]
W, H = 1920, 1080

# Daylight tokens (lib/shared/themes/app_colors.dart)
CANVAS = (244, 241, 234)
PAPER = (255, 255, 255)
INK = (22, 20, 15)
MUTED = (110, 104, 94)
SUNRISE = [(255, 179, 107), (255, 94, 98), (142, 108, 255)]
LETTER = [(255, 231, 214), (255, 221, 227), (233, 226, 255)]

INTRO, OUTRO, FADE = 3.2, 5.0, 0.3
PH = 960
PW = round(PH * 1080 / 2340 / 2) * 2
PX, PY = 1240, (H - PH) // 2
RADIUS = 44
CAP_X, CAP_W = 150, 930


def font(family, weight, size):
    return ImageFont.truetype(str(FONTS / f"Funnel{family}-{weight}.ttf"), size)


def lerp(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def gradient(w, h, stops, horizontal=True):
    """A left-to-right (or top-to-bottom) gradient through the given stops."""
    img = Image.new("RGB", (w, h))
    d = ImageDraw.Draw(img)
    n = w if horizontal else h
    for i in range(n):
        t = i / max(1, n - 1)
        seg = min(int(t * (len(stops) - 1)), len(stops) - 2)
        local = t * (len(stops) - 1) - seg
        c = lerp(stops[seg], stops[seg + 1], local)
        if horizontal:
            d.line([(i, 0), (i, h)], fill=c)
        else:
            d.line([(0, i), (w, i)], fill=c)
    return img


def wrap(draw, text, f, width):
    lines, cur = [], ""
    for word in text.split():
        trial = f"{cur} {word}".strip()
        if draw.textlength(trial, font=f) <= width:
            cur = trial
        else:
            lines.append(cur)
            cur = word
    return lines + [cur]


def background():
    img = Image.new("RGB", (W, H), CANVAS)
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse((-380, -420, 760, 560), fill=SUNRISE[0] + (70,))
    gd.ellipse((1050, 340, 2350, 1500), fill=SUNRISE[2] + (46,))
    gd.ellipse((1250, -300, 2150, 500), fill=SUNRISE[1] + (36,))
    glow = glow.filter(ImageFilter.GaussianBlur(170))
    img.paste(glow, (0, 0), glow)
    return img


def chip(img, x, y, label):
    f = font("Sans", "ExtraBold", 30)
    d = ImageDraw.Draw(img)
    tw = d.textlength(label, font=f) + 2 * len(label)
    w, h = int(tw + 56), 60
    pill = gradient(w, h, SUNRISE)
    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, w - 1, h - 1), radius=h // 2, fill=255)
    img.paste(pill, (x, y), mask)
    cx = x + 28
    for ch in label:
        d.text((cx, y + h / 2), ch, font=f, fill=PAPER, anchor="lm")
        cx += d.textlength(ch, font=f) + 2
    return y + h


def caption_png(i, label, title, sub):
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    ft, fs = font("Display", "Bold", 88), font("Sans", "Medium", 42)
    tlines = wrap(d, title, ft, CAP_W)
    slines = wrap(d, sub, fs, CAP_W - 30)[:3]
    block = 60 + 44 + len(tlines) * 96 + 34 + len(slines) * 58
    y = (H - block) // 2
    y = chip(img, CAP_X, y, label.upper()) + 44
    for line in tlines:
        d.text((CAP_X - 4, y), line, font=ft, fill=INK)
        y += 96
    y += 34
    for line in slines:
        d.text((CAP_X, y), line, font=fs, fill=MUTED)
        y += 58
    p = D / f"cap{i}.png"
    img.save(p)
    return p


def phone_assets():
    bg = background()
    halo = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(halo).rounded_rectangle(
        (PX - 22, PY - 22, PX + PW + 22, PY + PH + 22), radius=RADIUS + 22, fill=SUNRISE[1] + (80,))
    halo = halo.filter(ImageFilter.GaussianBlur(34))
    bg.paste(halo, (0, 0), halo)
    ImageDraw.Draw(bg).rounded_rectangle(
        (PX - 9, PY - 9, PX + PW + 8, PY + PH + 8), radius=RADIUS + 9, fill=INK)
    bg.save(D / "stage.png")
    mask = Image.new("L", (PW, PH), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, PW - 1, PH - 1), radius=RADIUS, fill=255)
    mask.save(D / "mask.png")


def spark(size):
    return Image.open(BRAND / "splash_spark.png").convert("RGBA").resize((size, size), Image.LANCZOS)


def card(name, build):
    img = background()
    build(img, ImageDraw.Draw(img))
    p = D / f"{name}.png"
    img.save(p)
    return p


def intro(img, d):
    sp = spark(600)
    img.paste(sp, ((W - 600) // 2, 40), sp)
    d.text((W / 2, 640), "Atlas", font=font("Display", "Bold", 170), fill=INK, anchor="mm")
    d.text((W / 2, 790), "Every day, a small sunrise.", font=font("Sans", "Medium", 50),
           fill=MUTED, anchor="mm")


def outro(img, d):
    sp = spark(330)
    img.paste(sp, (95, 70), sp)
    d.text((360, 235), "Atlas", font=font("Display", "Bold", 130), fill=INK, anchor="lm")
    items = ["Habits, tasks and goals", "Aurora, your gentle companion",
             "Daily check-ins and weekly letters", "Works fully offline"]
    fi = font("Sans", "SemiBold", 48)
    y = 440
    for t in items:
        dot = gradient(36, 36, SUNRISE)
        m = Image.new("L", (36, 36), 0)
        ImageDraw.Draw(m).ellipse((0, 0, 35, 35), fill=255)
        img.paste(dot, (182, y), m)
        d.text((248, y + 18), t, font=fi, fill=INK, anchor="lm")
        y += 100
    bw, bh, bx, by = 620, 150, 1150, 420
    btn = Image.new("L", (bw, bh), 0)
    ImageDraw.Draw(btn).rounded_rectangle((0, 0, bw - 1, bh - 1), radius=bh // 2, fill=255)
    img.paste(Image.new("RGB", (bw, bh), INK), (bx, by), btn)
    d.text((bx + bw / 2, by + bh / 2), "Free on Google Play", font=font("Display", "Bold", 52),
           fill=CANVAS, anchor="mm")
    d.text((bx + bw / 2, by + bh + 70), "Gentle, never graded.", font=font("Sans", "Medium", 40),
           fill=MUTED, anchor="mm")


def main():
    scenes = json.loads(Path(SCENES).read_text(encoding="utf-8"))["segments"]
    phone_assets()
    caps = [caption_png(i, s["chip"], s["title"], s["sub"]) for i, s in enumerate(scenes)]
    intro_p, outro_p = card("intro", intro), card("outro", outro)
    gradient(W, 8, SUNRISE).save(D / "bar.png")

    durs = [s["b"] - s["a"] for s in scenes]
    demo_len = sum(durs)
    total = INTRO + demo_len + OUTRO

    srcs = sorted({s["src"] for s in scenes})
    inputs, idx = [], {}
    for sp in srcs:
        idx[sp] = len(inputs) // 2
        inputs += ["-i", str(D / sp)]
    n_src = len(srcs)
    inputs += ["-loop", "1", "-i", str(D / "stage.png")]
    inputs += ["-i", str(D / "mask.png")]
    inputs += ["-loop", "1", "-t", str(INTRO), "-i", str(intro_p)]
    inputs += ["-loop", "1", "-t", str(OUTRO), "-i", str(outro_p)]
    inputs += ["-loop", "1", "-i", str(D / "bar.png")]
    cap0 = n_src + 5
    for p, du in zip(caps, durs):
        inputs += ["-loop", "1", "-t", f"{du:.3f}", "-i", str(p)]
    music_i = cap0 + len(scenes)
    inputs += ["-i", MUSIC]

    fc = []
    uses = {sp: [i for i, s in enumerate(scenes) if s["src"] == sp] for sp in srcs}
    for sp, ids in uses.items():
        outs = "".join(f"[r{i}]" for i in ids)
        k = idx[sp]
        fc.append(f"[{k}:v]fps=30,split={len(ids)}{outs}" if len(ids) > 1 else f"[{k}:v]fps=30{outs}")
    for i, s in enumerate(scenes):
        fc.append(f"[r{i}]trim={s['a']}:{s['b']},setpts=PTS-STARTPTS[t{i}]")
    fc.append("".join(f"[t{i}]" for i in range(len(scenes))) + f"concat=n={len(scenes)}:v=1:a=0[rec]")
    fc.append(f"[rec]scale={PW}:{PH}:flags=lanczos,format=rgba[ph]")
    fc.append(f"[{n_src + 1}:v]format=gray[mk]")
    fc.append("[ph][mk]alphamerge[phr]")
    fc.append(f"[{n_src}:v]fps=30,trim=0:{demo_len:.3f},setpts=PTS-STARTPTS[stg]")
    fc.append(f"[stg][phr]overlay={PX}:{PY}:shortest=1[a0]")
    last, t = "a0", 0.0
    for i, du in enumerate(durs):
        fades = f"fade=in:st=0:d={FADE}:alpha=1,fade=out:st={du - FADE:.3f}:d={FADE}:alpha=1"
        fc.append(f"[{cap0 + i}:v]format=rgba,{fades},setpts=PTS-STARTPTS+{t:.3f}/TB[c{i}]")
        fc.append(f"[{last}][c{i}]overlay=0:0:eof_action=pass[b{i}]")
        last, t = f"b{i}", t + du
    fc.append(f"[{n_src + 4}:v]fps=30,trim=0:{demo_len:.3f},setpts=PTS-STARTPTS[bar]")
    fc.append(f"[{last}][bar]overlay=x='-{W}+{W}*t/{demo_len:.3f}':y={H - 8}:shortest=1,"
              f"format=yuv420p,setsar=1[demo]")
    fc.append(f"[{n_src + 2}:v]fps=30,format=yuv420p,fade=in:st=0:d=0.4,fade=out:st={INTRO - 0.4}:d=0.4,setsar=1[in]")
    fc.append(f"[{n_src + 3}:v]fps=30,format=yuv420p,fade=in:st=0:d=0.4,fade=out:st={OUTRO - 0.7}:d=0.7,setsar=1[out]")
    fc.append("[in][demo][out]concat=n=3:v=1:a=0[v]")
    fc.append(f"[{music_i}:a]atrim=0:{total:.3f},asetpts=PTS-STARTPTS,"
              f"afade=in:st=0:d=1.0,afade=out:st={total - 2.5:.3f}:d=2.5[aud]")

    cmd = [FF, "-hide_banner", "-loglevel", "error", "-y", *inputs, "-filter_complex", ";".join(fc),
           "-map", "[v]", "-map", "[aud]", "-t", f"{total:.2f}", "-c:v", "libx264", "-crf", "19",
           "-preset", "slow", "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "192k",
           "-movflags", "+faststart", OUT]
    subprocess.run(cmd, check=True)
    print("done", round(total, 2))


main()
