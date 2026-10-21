#!/usr/bin/env python3
"""Builds the app's letter sounds (Media/phonemes) in the Star Voice (Maya, ElevenLabs v3).

Sources, in ~/code/ai/runwayml/characters/cutisie/phonemes2:
- held sounds (m s sh a e...) and long vowels / teams (ay ee igh...): the round-2 build in out/,
  picked from several takes per sound by class fit, steadiness and vowel formants (see build2.py).
- quick sounds that round 2 cut far too short (p b d g j: 20 to 110 ms, too short to hear),
  re-recorded here as clipped teaching sounds ("Buh.") and cut to the burst plus the very start
  of the vowel (about 150 ms) so they're audible but don't say "buh".
- th, re-recorded (round 2's take was mostly voiced, not the breathy th of "thin").
Then every alias the app uses (ai, a_e, ea, ck, qu, y_i...) is written, and everything is
loudness-matched to the recorded words.

  RUNWAYML_API_SECRET=... python3 tools/make_letter_sounds.py
"""
import glob
import json
import math
import os
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.expanduser("~/code/ai/runwayml/characters/cutisie/phonemes2")
sys.path.insert(0, HERE)
sys.path.insert(0, SRC)
sys.path.insert(0, os.path.join(SRC, "../phonemes"))
import dsp  # noqa: E402
from record_voice import MEDIA, tts  # noqa: E402

SR = dsp.SR
OUT = os.path.join(MEDIA, "phonemes")
TAKES = os.path.join(SRC, "takes3")
SEEDS = [8, 21, 33]

# clipped teaching syllables: the vowel is cut away, only burst + transition stay
QUICK = {"p": ("Puh.", 0.13), "b": ("Buh.", 0.15), "d": ("Duh.", 0.15), "g": ("Guh.", 0.15), "j": ("Juh.", 0.17)}
TH = ["Thhhhhhhhhh... thin.", "Thhhhhhhhh... thumb, think."]

ALIASES = {  # app key: source key
    "ai": "ay", "a_e": "ay", "ea": "ee", "e_e": "ee", "y_e": "ee", "i_e": "igh", "y_i": "igh",
    "o_e": "ow", "oa": "ow", "ou": "ow_cow", "oi": "oy", "ir": "er", "ur": "er",
    "wh": "w", "ff": "f", "ll": "l", "ss": "s", "c": "k", "ck": "k",
}


def fade(x, fin=0.004, fout=0.05):
    x = list(x)
    a, b = int(fin * SR), int(fout * SR)
    for i in range(min(a, len(x))):
        x[i] *= i / a
    for i in range(min(b, len(x))):
        x[-1 - i] *= i / b
    return x


def onset(x, floor_db=-38):
    for i, db, _ in dsp.frames(x, win=0.005, hop=0.0025):
        if db > floor_db:
            return max(0, i - int(0.008 * SR))
    return 0


def rms_db(x):
    loud = [db for _, db, _ in dsp.frames(x) if db > -40]
    return sorted(loud)[len(loud) // 2] if loud else -60


def quick_sound(g):
    text, keep = QUICK[g]
    best = None
    for seed in SEEDS:
        raw = os.path.join(TAKES, f"{g}.{seed}.mp3")
        if not os.path.exists(raw):
            tts(text, seed, raw)
        x = dsp.load(raw)
        s = x[onset(x):]
        cut = s[: int(keep * SR)]
        # prefer the take with the strongest release right at the start
        head = cut[: int(0.04 * SR)]
        punch = max((abs(v) for v in head), default=0)
        if best is None or punch > best[0]:
            best = (punch, seed, cut)
    return fade(best[2], 0.002, 0.06), best[1]


def th_sound():
    """The breathy part before the voice comes in, as a held sound."""
    best = None
    for i, text in enumerate(TH):
        for seed in SEEDS:
            raw = os.path.join(TAKES, f"th.{i}.{seed}.mp3")
            if not os.path.exists(raw):
                tts(text, seed, raw)
            x = dsp.load(raw)
            x = x[onset(x, -45):]
            f = dsp.frames(x)
            # noisy frames: high zero-crossing rate; stop at the first voiced stretch
            run = 0
            for _, db, zc in f:
                if db < -45 or zc < 2200:
                    break
                run += 1
            dur = run * 0.01
            if best is None or dur > best[0]:
                best = (dur, f"{i}.{seed}", x[: int(dur * SR)])
    return best


def loop(s, xf=0.04):
    n = int(xf * SR)
    body = s[: len(s) - n]
    tail = s[len(s) - n:]
    for i in range(n):
        w = i / n
        body[i] = body[i] * w + tail[i] * (1 - w)
    return body


def match(x, target_db):
    gain = 10 ** ((target_db - rms_db(x)) / 20)
    peak = max((abs(v) for v in x), default=1) * gain
    if peak > 0.95:
        gain *= 0.95 / peak
    return [v * gain for v in x]


def main():
    os.makedirs(TAKES, exist_ok=True)
    built = os.path.join(SRC, "out")
    report = json.load(open(os.path.join(built, "report.json")))
    sounds = {}
    for path in glob.glob(os.path.join(built, "*.wav")):
        key = os.path.basename(path)[:-4]
        if key.split("-")[0] in QUICK or key.split("-")[0] == "th":
            continue
        sounds[key] = dsp.load(path)
    for g in QUICK:
        sounds[g], seed = quick_sound(g)
        report[g] = {"kind": "stop", "take": f"takes3/{g}.{seed}.mp3", "written_s": round(len(sounds[g]) / SR, 3)}
    dur, take, th = th_sound()
    if dur >= 0.3:
        steady = th[int(len(th) * 0.15): int(len(th) * 0.9)]
        lp = loop(steady)
        sounds["th"] = fade(th[: int(0.6 * SR)], 0.006, 0.06)
        sounds["th-long"] = lp * max(1, math.ceil(SR / len(lp)))
        report["th"] = {"kind": "continuous", "take": f"takes3/th.{take}.mp3", "dur": round(dur, 2)}
    else:
        print(f"th: no clean breathy take (best {dur:.2f} s); keeping the old one")
    # loudness: match the recorded words (their median active level)
    words = sorted(glob.glob(os.path.join(MEDIA, "words", "*.m4a")))[::8]
    target = sorted(rms_db(dsp.load(w)) for w in words)[len(words) // 2]
    for key, x in sounds.items():
        dsp.write_wav(os.path.join(OUT, key + ".wav"), match(x, target))
    for alias, src in ALIASES.items():
        for suffix in ("", "-long"):
            p = os.path.join(OUT, src + suffix + ".wav")
            if os.path.exists(p):
                shutil.copy2(p, os.path.join(OUT, alias + suffix + ".wav"))
    # qu = k then the start of w
    k, w = dsp.load(os.path.join(OUT, "k.wav")), dsp.load(os.path.join(OUT, "w.wav"))
    dsp.write_wav(os.path.join(OUT, "qu.wav"), fade(k + w[: int(0.16 * SR)], 0.002, 0.06))
    json.dump(report, open(os.path.join(TAKES, "report.json"), "w"), indent=1)
    print("target", round(target, 1), "dB;", len(sounds), "sounds +", len(ALIASES), "aliases + qu")


if __name__ == "__main__":
    main()
