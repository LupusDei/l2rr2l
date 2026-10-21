#!/usr/bin/env python3
"""Records Star Voice lines and words with Runway text-to-speech and checks each
take by transcribing it back with whisper.cpp (retaking with other seeds on a miss).

  python3 tools/record_voice.py --missing          # everything voice_lines.json lists as missing
  python3 tools/record_voice.py --lines "The end!" --words big

Voice: Runway preset Maya on ElevenLabs v3, the one voice for the whole app.
Lines go to Media/voice/<slug>.m4a, words to Media/words/<word>.m4a, trimmed and
loudness-matched (see `finish`). Raw takes are kept in --takes for re-use.
Needs RUNWAYML_API_SECRET (from ~/code/ai/runwayml/.env), ffmpeg and whisper-cli.
"""
import argparse
import concurrent.futures as cf
import json
import os
import re
import subprocess
import sys
import tempfile
import time
import urllib.request

sys.path.insert(0, os.path.dirname(__file__))
from voice_lines import MEDIA, slug  # noqa: E402

BASE = "https://api.dev.runwayml.com/v1"
VOICE = "Maya"
MODEL = "eleven_v3"
SEEDS = [8, 21, 33, 47, 59]
WHISPER_MODEL = os.path.expanduser("~/.syl/episodes/ggml-base.en.bin")
# mean loudness of the finished files (dB); words a little quieter than lines
LINE_DB, WORD_DB = -21.0, -23.0


def _req(method, path, body=None):
    headers = {"Authorization": f"Bearer {os.environ['RUNWAYML_API_SECRET']}",
               "X-Runway-Version": "2024-11-06", "Content-Type": "application/json"}
    data = json.dumps(body).encode() if body is not None else None
    for attempt in range(5):
        try:
            with urllib.request.urlopen(urllib.request.Request(BASE + path, data=data, method=method, headers=headers),
                                        timeout=120) as r:
                raw = r.read()
                return json.loads(raw) if raw else {}
        except urllib.error.HTTPError as e:
            if e.code == 429 or e.code >= 500:
                time.sleep(4 * (attempt + 1))
                continue
            raise RuntimeError(f"{method} {path}: {e.code} {e.read()[:300]}")
    raise RuntimeError(f"{method} {path}: gave up")


# How the name is said: "CUTE-ee-see". Spelled out so the voice says it the same way every time.
SAY = {"Cutisie's": "Cutie-see's", "Cutisie": "Cutie-see"}


def spoken(text):
    for k, v in SAY.items():
        text = text.replace(k, v)
    return text


def tts(text, seed, dest):
    body = {"model": MODEL, "promptText": spoken(text), "voice": {"type": "runway-preset", "presetId": VOICE}, "seed": seed}
    task = _req("POST", "/text_to_speech", body)["id"]
    while True:
        t = _req("GET", f"/tasks/{task}")
        if t["status"] == "SUCCEEDED":
            break
        if t["status"] in ("FAILED", "CANCELED"):
            raise RuntimeError(f"{text!r}: {t.get('failure')}")
        time.sleep(3)
    urllib.request.urlretrieve(t["output"][0], dest)
    return dest


NUMBERS = {"practise": "practice", "1": "one", "2": "two", "5": "five", "6": "six", "10": "ten", "50": "fifty", "100": "one hundred"}


def norm(t):
    t = t.lower().replace("’", "'").replace("-", " ")
    t = re.sub(r"[^a-z0-9' ]+", " ", t)
    return " ".join(NUMBERS.get(w, w) for w in t.split()).split()


def heard(path):
    with tempfile.TemporaryDirectory() as tmp:
        wav = os.path.join(tmp, "a.wav")
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", path, "-ar", "16000", "-ac", "1",
                        "-af", "apad=pad_dur=0.6", wav], check=True)
        subprocess.run(["whisper-cli", "-m", WHISPER_MODEL, "-nt", "-np", "-otxt", "-l", "en", "-f", wav],
                       capture_output=True)
        return open(wav + ".txt").read().strip() if os.path.exists(wav + ".txt") else ""


def matches(want, got):
    """Every word heard as written. Whisper can't spell the made-up name, so the
    name may come back as any one or two words (checked by ear on a sample)."""
    w, g = norm(want), norm(got)
    if w == g:
        return True
    if len(w) == 1:
        return len(g) >= 1 and g[0].rstrip("s") == w[0].rstrip("s")
    pattern = "^" + " ".join(r"\S+( \S+)?" if x.startswith("cutisie") else re.escape(x) for x in w) + "$"
    return re.match(pattern, " ".join(g)) is not None


def finish(raw, dest, target_db):
    """Trim silence, mono 44.1 kHz AAC, mean loudness matched to `target_db`."""
    with tempfile.TemporaryDirectory() as tmp:
        trimmed = os.path.join(tmp, "t.wav")
        trim = ("silenceremove=start_periods=1:start_threshold=-55dB:start_silence=0.03,"
                "areverse,silenceremove=start_periods=1:start_threshold=-55dB:start_silence=0.06,areverse")
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", raw, "-af", trim, "-ac", "1", "-ar", "44100", trimmed],
                       check=True)
        out = subprocess.run(["ffmpeg", "-hide_banner", "-i", trimmed, "-af", "volumedetect", "-f", "null", "-"],
                             capture_output=True, text=True).stderr
        mean = float(re.search(r"mean_volume: (-?[\d.]+) dB", out).group(1))
        peak = float(re.search(r"max_volume: (-?[\d.]+) dB", out).group(1))
        gain = min(target_db - mean, -1.0 - peak)  # never clip
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", trimmed, "-af", f"volume={gain:.1f}dB",
                        "-c:a", "aac", "-b:a", "96k", dest], check=True)


def record(text, dest, target_db, takes_dir):
    key = os.path.splitext(os.path.basename(dest))[0]
    last = None
    for seed in SEEDS:
        raw = os.path.join(takes_dir, f"{key}.{seed}.mp3")
        if not os.path.exists(raw):
            try:
                # a lone word gets a full stop, or very short words can fail to generate
                tts(text if " " in text else text + ".", seed, raw)
            except RuntimeError as e:
                print("retry", key, seed, e, flush=True)
                continue
        got = heard(raw)
        last = (raw, got)
        if matches(text, got):
            finish(raw, dest, target_db)
            return key, True, got
    if last is None:
        return key, False, "(no take generated)"
    finish(last[0], dest, target_db)  # best effort, flagged in the report
    return key, False, last[1]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--lines", nargs="*", default=[])
    ap.add_argument("--words", nargs="*", default=[])
    ap.add_argument("--missing", action="store_true")
    ap.add_argument("--all", action="store_true", help="every line and word the app needs")
    ap.add_argument("--takes", default=os.path.expanduser("~/code/ai/runwayml/characters/cutisie/voice/takes-app"))
    args = ap.parse_args()
    lines, words = list(args.lines), list(args.words)
    if args.missing:
        d = json.load(open(os.path.join(MEDIA, "content/voice_lines.json")))
        lines += [d["lines"][k] for k in d["missing"]["lines"]]
        words += d["missing"]["words"]
    if args.all:
        d = json.load(open(os.path.join(MEDIA, "content/voice_lines.json")))
        lines += list(d["lines"].values())
        words += d["words"]
    os.makedirs(os.path.join(MEDIA, "voice"), exist_ok=True)
    jobs = [(t, os.path.join(MEDIA, "voice", slug(t) + ".m4a"), LINE_DB) for t in lines]
    jobs += [(w, os.path.join(MEDIA, "words", w.lower() + ".m4a"), WORD_DB) for w in words]
    os.makedirs(args.takes, exist_ok=True)
    report = {}
    with cf.ThreadPoolExecutor(6) as ex:
        for key, ok, got in ex.map(lambda j: record(*j, args.takes), jobs):
            report[key] = {"ok": ok, "heard": got}
            print("ok  " if ok else "MISS", key, "|", got, flush=True)
    path = os.path.join(args.takes, "report.json")
    old = json.load(open(path)) if os.path.exists(path) else {}
    old.update(report)
    json.dump(old, open(path, "w"), indent=1)


if __name__ == "__main__":
    main()
