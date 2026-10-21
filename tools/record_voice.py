#!/usr/bin/env python3
"""Records Star Voice lines and words with Runway text-to-speech (preset Serene).

  python3 tools/record_voice.py --lines "Make the picture!" "The end!"
  python3 tools/record_voice.py --words big

Lines go to Media/voice/<slug>.m4a (slug as in voice_lines.py), words to
Media/words/<word>.m4a. Silence is trimmed and audio saved as mono AAC.
Needs RUNWAYML_API_SECRET in the environment (from ~/code/ai/runwayml/.env)
and ffmpeg.
"""
import argparse
import concurrent.futures as cf
import json
import os
import subprocess
import sys
import tempfile
import time
import urllib.request

sys.path.insert(0, os.path.dirname(__file__))
from voice_lines import MEDIA, slug  # noqa: E402

BASE = "https://api.dev.runwayml.com/v1"
VOICE = "Serene"


def _req(method, path, body=None):
    headers = {"Authorization": f"Bearer {os.environ['RUNWAYML_API_SECRET']}",
               "X-Runway-Version": "2024-11-06", "Content-Type": "application/json"}
    data = json.dumps(body).encode() if body is not None else None
    with urllib.request.urlopen(urllib.request.Request(BASE + path, data=data, method=method, headers=headers),
                                timeout=120) as r:
        raw = r.read()
        return json.loads(raw) if raw else {}


def tts(text, dest):
    task = _req("POST", "/text_to_speech", {"model": "eleven_multilingual_v2", "promptText": text,
                                            "voice": {"type": "runway-preset", "presetId": VOICE}})["id"]
    while True:
        t = _req("GET", f"/tasks/{task}")
        if t["status"] == "SUCCEEDED":
            break
        if t["status"] in ("FAILED", "CANCELED"):
            raise RuntimeError(f"{text!r}: {t.get('failure')}")
        time.sleep(3)
    with tempfile.NamedTemporaryFile(suffix=".mp3") as raw:
        urllib.request.urlretrieve(t["output"][0], raw.name)
        trim = ("silenceremove=start_periods=1:start_threshold=-45dB,"
                "areverse,silenceremove=start_periods=1:start_threshold=-45dB,areverse")
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", raw.name, "-af", trim, "-ac", "1",
                        "-ar", "44100", "-c:a", "aac", "-b:a", "96k", dest], check=True)
    return dest


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--lines", nargs="*", default=[])
    ap.add_argument("--words", nargs="*", default=[])
    args = ap.parse_args()
    jobs = [(t, os.path.join(MEDIA, "voice", slug(t) + ".m4a")) for t in args.lines]
    jobs += [(w, os.path.join(MEDIA, "words", w.lower() + ".m4a")) for w in args.words]
    os.makedirs(os.path.join(MEDIA, "voice"), exist_ok=True)
    with cf.ThreadPoolExecutor(6) as ex:
        for done in ex.map(lambda j: tts(*j), jobs):
            print("ok", os.path.relpath(done, MEDIA))


if __name__ == "__main__":
    main()
