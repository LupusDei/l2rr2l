#!/usr/bin/env python3
"""Cuts Cutisie's reading rig: a base still plus small mouth and blink patches.

Read Along lip-syncs Cutisie to any word by swapping seven mouth shapes over
one still of her reading (see art/cutisie/READER_RIG.md). This script turns
generated pictures of her in that pose into the app's rig:

  app/L2RR2L/Resources/Media/mascot/reader/
    base.png              the reading pose, mouth closed
    mouth_<shape>.png     same size as base; only the mouth area is opaque
    blink.png             same, eyes closed
    rig.json              horn tip, as a fraction of the image

Input: a folder of PNGs of the same pose, one or more takes per shape:
  base.png  closed_1.png closed_2.png  small_1.png  open_1.png  wide_1.png
  round_1.png  pucker_1.png  teeth_1.png  blink_1.png ...
Each take is lined up with the base (a small shift is fine), and of several
takes the one that changes least outside the mouth (or eyes) wins, so
generated pictures that drifted in pose are skipped automatically. Only the
mouth (or eye) area is kept, with a soft edge, so the rest of her stays
pixel-identical to the base.

  python3 tools/make_reader_rig.py art/cutisie/out/reader/takes \
      --horn 0.508,0.09 --mouth 0.41,0.44,0.59,0.56 --eyes 0.35,0.34,0.65,0.48

Boxes are fractions of the image (x0,y0,x1,y1). The defaults fit the `read`
pose. A contact sheet of every pick over the base is written next to the
takes as rig-preview.png for checking by eye.
Needs numpy and Pillow.
"""
import argparse
import glob
import json
import os
import re

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "app/L2RR2L/Resources/Media/mascot/reader")
SHAPES = ["closed", "small", "open", "wide", "round", "pucker", "teeth"]


def load(path, size=None):
    im = Image.open(path).convert("RGBA")
    if size and im.size != size:
        im = im.resize(size, Image.LANCZOS)
    return im


def gray(im):
    return np.asarray(im.convert("L"), dtype=np.float32) / 255


def shift_to(base, take):
    """Integer (dx, dy) that lines `take` up with `base` (phase correlation)."""
    a, b = gray(base), gray(take)
    window = np.outer(np.hanning(a.shape[0]), np.hanning(a.shape[1]))
    fa, fb = np.fft.fft2(a * window), np.fft.fft2(b * window)
    r = fa * np.conj(fb)
    r /= np.abs(r) + 1e-9
    corr = np.abs(np.fft.ifft2(r))
    dy, dx = np.unravel_index(np.argmax(corr), corr.shape)
    h, w = a.shape
    if dy > h // 2:
        dy -= h
    if dx > w // 2:
        dx -= w
    return int(dx), int(dy)


def moved(im, dx, dy):
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    out.paste(im, (dx, dy))
    return out


def box_px(box, size):
    w, h = size
    return (int(box[0] * w), int(box[1] * h), int(box[2] * w), int(box[3] * h))


def soft_mask(size, box, feather):
    """An ellipse filling `box`, blurred so the patch edge disappears."""
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).ellipse(box_px(box, size), fill=255)
    return mask.filter(ImageFilter.GaussianBlur(feather))


def drift(base, take, box):
    """How much the take differs from the base outside `box` (lower is better)."""
    a = np.asarray(base, dtype=np.float32)
    b = np.asarray(take, dtype=np.float32)
    keep = np.ones(a.shape[:2], bool)
    x0, y0, x1, y1 = box_px(box, base.size)
    keep[y0:y1, x0:x1] = False
    visible = (a[..., 3] > 32) | (b[..., 3] > 32)
    sel = keep & visible
    return float(np.abs(a[sel] - b[sel]).mean()) if sel.any() else 1e9


def best_take(base, paths, box):
    scored = []
    for p in paths:
        take = load(p, base.size)
        dx, dy = shift_to(base, take)
        take = moved(take, dx, dy)
        scored.append((drift(base, take, box), p, take, (dx, dy)))
    scored.sort(key=lambda s: s[0])
    return scored[0]


def patch(base, take, box, feather):
    mask = np.asarray(soft_mask(base.size, box, feather), dtype=np.float32) / 255
    rgba = np.asarray(take, dtype=np.float32).copy()
    rgba[..., 3] *= mask
    rgba[rgba[..., 3] < 1] = 0  # clear pixels compress to almost nothing
    return Image.fromarray(rgba.astype(np.uint8), "RGBA")


def fractions(text, n):
    v = [float(x) for x in text.split(",")]
    if len(v) != n:
        raise SystemExit(f"expected {n} numbers: {text}")
    return v


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("takes", help="folder with base.png and <shape>_<n>.png takes")
    ap.add_argument("--out", default=OUT)
    ap.add_argument("--horn", default="0.508,0.09")
    ap.add_argument("--mouth", default="0.41,0.44,0.59,0.56")
    ap.add_argument("--eyes", default="0.35,0.34,0.65,0.48")
    ap.add_argument("--size", type=int, default=768, help="output side in pixels")
    args = ap.parse_args()

    mouth_box = fractions(args.mouth, 4)
    eyes_box = fractions(args.eyes, 4)
    base = load(os.path.join(args.takes, "base.png"))
    base = base.resize((args.size, args.size), Image.LANCZOS)
    feather = args.size * 0.012

    groups = {}
    for p in sorted(glob.glob(os.path.join(args.takes, "*.png"))):
        m = re.match(r"([a-z]+)(?:_\d+)?\.png$", os.path.basename(p))
        if m and m.group(1) != "base" and not os.path.basename(p).startswith("rig-"):
            groups.setdefault(m.group(1), []).append(p)

    os.makedirs(args.out, exist_ok=True)
    base.save(os.path.join(args.out, "base.png"), optimize=True)
    picks = []
    for shape in SHAPES + ["blink"]:
        if shape not in groups:
            print(f"  missing {shape}: no takes")
            continue
        box = eyes_box if shape == "blink" else mouth_box
        score, path, take, (dx, dy) = best_take(base, groups[shape], box)
        name = "blink.png" if shape == "blink" else f"mouth_{shape}.png"
        patch(base, take, box, feather).save(os.path.join(args.out, name), optimize=True)
        picks.append((shape, take))
        print(f"  {shape:7s} <- {os.path.basename(path)}  shift {dx:+d},{dy:+d}  drift {score:.1f}"
              + ("  (high: check it)" if score > 12 else ""))

    hx, hy = fractions(args.horn, 2)
    with open(os.path.join(args.out, "rig.json"), "w") as f:
        json.dump({"hornTip": [hx, hy], "mouthBox": mouth_box, "eyesBox": eyes_box}, f, indent=2)

    # contact sheet: each patch over the base, cropped to her head
    if picks:
        x0, y0, x1, y1 = box_px((0.25, 0.15, 0.75, 0.65), base.size)
        tile = (x1 - x0, y1 - y0)
        sheet = Image.new("RGBA", (tile[0] * len(picks), tile[1]), (12, 16, 52, 255))
        for i, (shape, _) in enumerate(picks):
            name = "blink.png" if shape == "blink" else f"mouth_{shape}.png"
            layer = Image.open(os.path.join(args.out, name))
            frame = Image.alpha_composite(base, layer).crop((x0, y0, x1, y1))
            sheet.alpha_composite(frame, (i * tile[0], 0))
            ImageDraw.Draw(sheet).text((i * tile[0] + 8, 8), shape, fill=(255, 255, 255, 255))
        sheet.convert("RGB").save(os.path.join(args.takes, "rig-preview.png"))
    total = sum(os.path.getsize(os.path.join(args.out, f)) for f in os.listdir(args.out))
    print(f"rig written to {args.out} ({total / 1024:.0f} KB)")


if __name__ == "__main__":
    main()
