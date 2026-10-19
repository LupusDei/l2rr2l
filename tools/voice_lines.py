#!/usr/bin/env python3
"""Lists everything the Star Voice must say, for recording.

Writes app/L2RR2L/Resources/Media/content/voice_lines.json:
  lines:   {slug: text}   narrator lines  -> Media/voice/<slug>.m4a
  words:   [word, ...]    single words    -> Media/words/<word>.m4a
  missing: which of those have no recording in the app yet

The app plays only recordings (no synthesized speech), so anything missing
here is silent in the app until it's recorded. Run:
  python3 tools/voice_lines.py
"""
import glob
import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
APP = os.path.join(ROOT, "app/L2RR2L")
MEDIA = os.path.join(APP, "Resources/Media")


def slug(text):
    """Same rule as VoiceSlug.make in Speaker.swift."""
    out, last_us = "", True
    for ch in text.lower().replace("'", ""):
        if ch.isascii() and ch.isalnum():
            out += ch
            last_us = False
        elif not last_us:
            out += "_"
            last_us = True
    return out.rstrip("_")[:80]


LINE_PATTERNS = [
    r'voice\.(?:say|announce)\(\s*"((?:[^"\\]|\\.)+)"',
    r'\.line\(\s*"((?:[^"\\]|\\.)+)"',
    r'\bline:\s*"((?:[^"\\]|\\.)+)"',
    r'resultLine\s*=\s*"((?:[^"\\]|\\.)+)"',
    r'\bline\s*=\s*"((?:[^"\\]|\\.)+)"',
    r'say\(\s*index == 0 \? "((?:[^"\\]|\\.)+)" : "((?:[^"\\]|\\.)+)"',
    r'announce\(\s*index == 0 \? "((?:[^"\\]|\\.)+)" : "((?:[^"\\]|\\.)+)"',
    r'say\(\s*fromSession \? "((?:[^"\\]|\\.)+)" : "((?:[^"\\]|\\.)+)"',
]


def collect_lines():
    lines = set()
    for path in glob.glob(os.path.join(APP, "**/*.swift"), recursive=True):
        src = open(path).read()
        for pat in LINE_PATTERNS:
            for m in re.finditer(pat, src):
                for g in m.groups():
                    if g and "\\(" not in g:
                        lines.add(g)
        # praise list, game intro lines, milestone lines
        for block in re.findall(r'praise = \[(.*?)\]', src, re.S):
            lines.update(re.findall(r'"([^"]+)"', block))
        for block in re.findall(r'var introLine: String \{(.*?)\n    \}', src, re.S):
            lines.update(re.findall(r'"([^"]+)"', block))
        for block in re.findall(r'let milestones: \[.*?\] = \[(.*?)\]\n', src, re.S):
            lines.update(t for t in re.findall(r'"([^"]+)"', block) if " " in t)
        for phrase in re.findall(r'phrase: "([^"]+)"', src):
            lines.add(f"means {phrase}!")
    return lines


def main():
    cur = json.load(open(os.path.join(MEDIA, "content/curriculum.json")))
    lines = collect_lines()
    for st in cur["stages"]:
        for s in st["sentences"]:
            lines.add(s["text"])
    words = set()
    for st in cur["stages"]:
        words.update(w["text"].lower() for w in st["words"])
        words.update(w["text"].lower() for c in st["chains"] for w in c)
        words.update(h.lower() for h in st["heartWords"])
        words.update(u["text"].lower() for u in st["unicornWords"])
    for w in cur.get("pictureWords", []):
        words.add(w["text"].lower())
    wu = cur.get("warmups", {})
    for r in wu.get("rhymeSets", []):
        words.update(x["text"] for x in r["words"])
    words.update(s["text"] for s in wu.get("syllables", []))
    for o in wu.get("onsets", []):
        words.update([o["word"], o["rime"]])

    def have(folder, name):
        return any(os.path.exists(os.path.join(MEDIA, folder, f"{name}.{e}")) for e in ("m4a", "mp3", "wav", "caf"))

    by_slug = {slug(t): t for t in sorted(lines)}
    out = {
        "voice": "Star Voice (Runway preset Serene): warm, slow, clear, smiling",
        "lines": by_slug,
        "words": sorted(words),
        "missing": {
            "lines": sorted(k for k in by_slug if not have("voice", k)),
            "words": sorted(w for w in words if not have("words", w)),
        },
    }
    path = os.path.join(MEDIA, "content/voice_lines.json")
    with open(path, "w") as f:
        json.dump(out, f, indent=1, ensure_ascii=False)
    print(f"{len(by_slug)} lines ({len(out['missing']['lines'])} missing), "
          f"{len(words)} words ({len(out['missing']['words'])} missing)")
    print("wrote", path)


if __name__ == "__main__":
    main()
