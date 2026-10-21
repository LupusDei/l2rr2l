#!/usr/bin/env python3
"""Builds app/L2RR2L/Resources/Media/content/curriculum.json from the
learning path (design/learning-path.md section 4).

Edit the lists below and re-run:  python3 tools/make_curriculum.py

Each word gets its graphemes (tiles), the sound key for each tile (for the
PhonemeEngine), a picture (emoji until word art lands; None for words that
are hard to picture) and up to two one-sound-off picture distractors chosen
automatically from words taught at or before its stage.
"""
import json
import os
from itertools import chain

# Multi-letter graphemes, longest first, and the stage each becomes a unit.
MULTI = [
    ("igh", 6), ("sh", 3), ("ch", 3), ("th", 3), ("wh", 3), ("ng", 3), ("nk", 3),
    ("ck", 2), ("ff", 2), ("ll", 2), ("ss", 2), ("qu", 2),
    ("ee", 6), ("ea", 6), ("ai", 6), ("ay", 6), ("oa", 6), ("ow", 6), ("oo", 6),
    ("ou", 6), ("oi", 6), ("oy", 6), ("ar", 6), ("or", 6), ("er", 6), ("ir", 6), ("ur", 6),
]
VOWELS = set("aeiou")

PICTURES = {
    # stage 1
    "man": "👨", "map": "🗺️", "pin": "📍", "tin": "🥫", "pan": "🍳", "dad": "👨‍👧", "mad": "😠",
    "dig": "⛏️", "pig": "🐷", "dog": "🐶", "cat": "🐱", "cot": "🛏️", "nap": "😴", "cap": "🧢",
    "kid": "🧒", "kit": "🧰", "pot": "🍲", "mop": "🧹", "sad": "😢", "tag": "🏷️", "sip": "🥤",
    "ant": "🐜",
    # stage 2
    "bed": "🛏️", "hen": "🐔", "pen": "🖊️", "ten": "🔟", "net": "🥅", "jet": "✈️", "leg": "🦵",
    "web": "🕸️", "red": "🔴", "wet": "💦", "bug": "🐛", "rug": "🧶", "cup": "🥤", "sun": "☀️",
    "bus": "🚌", "nut": "🥜", "mug": "☕️", "hug": "🤗", "run": "🏃", "cub": "🐻", "hat": "🎩",
    "bat": "🦇", "rat": "🐀", "fan": "🪭", "van": "🚐", "jam": "🍯", "ram": "🐏", "ham": "🍖",
    "bag": "👜", "fox": "🦊", "box": "📦", "log": "🪵", "hop": "🐇", "hot": "🔥", "lip": "👄",
    "zip": "🤐", "wig": "💇", "six": "6️⃣", "yak": "🐃", "kiss": "💋", "bell": "🔔", "hill": "⛰️",
    "doll": "🪆", "duck": "🦆", "sock": "🧦", "rock": "🪨", "lock": "🔒", "bun": "🍞", "fin": "🦈",
    "sub": "🥪", "lid": "🫙", "hip": "🦴", "pup": "🐶", "gum": "🍬", "mud": "🟤", "fig": "🍈",
    "vet": "🩺", "bib": "👶", "tub": "🛁", "jug": "🏺", "egg": "🥚", "quilt": "🛌",
    # stage 3
    "ship": "🚢", "shop": "🏪", "shell": "🐚", "fish": "🐟", "dish": "🍽️", "chip": "🍟",
    "chick": "🐤", "lunch": "🍱", "bath": "🛁", "moth": "🦋", "ring": "💍", "king": "🤴",
    "sing": "🎤", "wing": "🪽", "sink": "🚰", "pink": "🩷", "wink": "😉", "bank": "🏦",
    "neck": "🦒", "whip": "🍦", "chin": "🧔", "wish": "🌠", "thumb": "👍", "teeth": "🦷",
    "shed": "🛖", "chop": "🪓", "path": "🛤️",
    # stage 4
    "lamp": "💡", "jump": "🦘", "hand": "✋", "milk": "🥛", "tent": "⛺", "belt": "🥋", "nest": "🪺",
    "mask": "🎭", "desk": "🖥️", "gift": "🎁", "sand": "🏖️", "stop": "🛑", "frog": "🐸",
    "clap": "👏", "swim": "🏊", "drum": "🥁", "flag": "🚩", "crab": "🦀", "sled": "🛷",
    "plum": "🟣", "stamp": "📮", "trunk": "🐘", "plant": "🪴", "skunk": "🦨", "drink": "🧃",
    "twins": "👯", "camp": "🏕️", "brush": "🪥", "clock": "⏰", "dress": "👗", "black": "⚫",
    "snack": "🥨", "spill": "🫗", "smell": "👃",
    # stage 5
    "cape": "🦸", "cake": "🎂", "gate": "🚧", "lake": "🏞️", "snake": "🐍", "kite": "🪁",
    "bike": "🚲", "five": "5️⃣", "pine": "🌲", "rope": "🪢", "nose": "👃", "bone": "🦴",
    "home": "🏠", "cube": "🧊", "flute": "🪈", "tape": "📼", "robe": "🥋", "hose": "🚿",
    "plane": "✈️", "smile": "😊", "dime": "🪙", "mule": "🫏", "slide": "🛝", "grape": "🍇",
    "sunset": "🌅", "cupcake": "🧁",
    # stage 6
    "tree": "🌳", "bee": "🐝", "feet": "🦶", "sheep": "🐑", "leaf": "🍃", "seal": "🦭",
    "rain": "🌧️", "snail": "🐌", "train": "🚆", "tray": "🍽️", "boat": "⛵", "goat": "🐐",
    "coat": "🧥", "snow": "❄️", "bow": "🎀", "night": "🌃", "light": "💡", "moon": "🌙",
    "spoon": "🥄", "book": "📕", "foot": "🦶", "cloud": "☁️", "house": "🏠", "cow": "🐄",
    "owl": "🦉", "coin": "🪙", "boy": "👦", "toy": "🧸", "car": "🚗", "star": "⭐️",
    "fork": "🍴", "corn": "🌽", "horse": "🐎", "bird": "🐦", "girl": "👧", "purse": "👛",
    "shark": "🦈", "storm": "⛈️", "tail": "🐾", "queen": "👸", "peach": "🍑", "soap": "🧼",
    # stage 7
    "rabbit": "🐇", "picnic": "🧺", "kitten": "🐱", "muffin": "🧁", "jumping": "🦘",
}

# Sound overrides where letters don't say their default sound.
SOUND_OVERRIDES = {
    "cow": ["c", "ow_cow"], "owl": ["ow_cow", "l"], "book": ["b", "oo_book", "k"],
    "foot": ["f", "oo_book", "t"], "this": ["th_v", "i", "s"], "that": ["th_v", "a", "t"],
    "with": ["w", "i", "th_v"], "then": ["th_v", "e", "n"],
    "my": ["m", "y_i"], "happy": ["h", "a", "p", "", "y_e"],
}

STAGES = [
    {"id": 0, "name": "Sound Garden", "graphemes": list("satpinmd"),
     "words": [], "heart": [], "chains": [], "sentences": [], "unicorn": []},
    {"id": 1, "name": "First Words", "graphemes": list("satpinmdgock"),
     "words": "at in is it an am ant sat sam man mat sip nap map sit pin tin pan dad mad dig pig dog cat cot top can cap kid kit pot mop sad tag nod dot".split(),
     "heart": ["I", "a", "the", "is"],
     "chains": [["mat", "sat", "sad", "mad", "man", "can"], ["sit", "pit", "pin", "tin", "tip", "dip"],
                ["cat", "cot", "cog", "dog", "dig", "pig"], ["nap", "map", "mop", "top", "tip", "tin"],
                ["man", "pan", "pin", "pit", "pot", "dot"], ["kid", "kit", "sit", "sat", "pat", "pan"]],
     "sentences": [("a fat cat", "🐱", ["🐶", "🐷"]), ("a pig in a pit", "🐷🕳️", ["🐶🕳️", "🐷🛏️"]),
                   ("Sam sat.", "🧒🪑", ["🧒🏃", "🐱🪑"]), ("a dog on a mat", "🐶🟫", ["🐱🟫", "🐶🛏️"])],
     "unicorn": ["tam", "pim", "nid", "mip", "dat", "sog", "kip", "gan", "tod", "mig"]},
    {"id": 2, "name": "Vowel Islands", "graphemes": list("eurhbfljvwxyz") + ["ck", "ff", "ll", "ss", "qu"],
     "words": "bed hen pen ten net jet leg web red wet bug rug cup sun bus nut mug hug run cub hat bat rat fan van jam ram ham bag fox box log hop hot lip zip wig six yak kiss bell hill doll duck sock rock lock bun fin sub lid hip pup gum mud vet bib tub jug egg".split(),
     "heart": ["to", "no", "go", "he", "she", "we", "me", "be", "was", "you"],
     "chains": [["pin", "pan", "pen", "pun", "bun", "bug"], ["bed", "bad", "bag", "big", "bug", "rug"],
                ["hot", "hop", "hip", "hit", "hat", "hut"], ["fun", "fan", "fin", "fit", "fat", "fox"],
                ["web", "wet", "jet", "jot", "hot", "hut"], ["bell", "bill", "fill", "fell", "well", "yell"]],
     "sentences": [("The dog is on the bed.", "🐶🛏️", ["🐱🛏️", "🐶📦"]), ("Is the bug in the cup?", "🐛🥤", ["🐛📦", "🐜🥤"]),
                   ("The hen is red.", "🐔🔴", ["🐔🔵", "🐶🔴"]), ("A fox sat on a box.", "🦊📦", ["🦊🛏️", "🐶📦"])],
     "unicorn": ["zop", "fim", "vug", "hed", "jux", "bev", "wup", "yat", "lom", "ruz"]},
    {"id": 3, "name": "Sound Buddies", "graphemes": ["sh", "ch", "th", "wh", "ng", "nk"],
     "words": "ship shop shell fish dish chip chick lunch bath moth ring king sing wing sink pink wink bank neck whip chin wish thin this that when much shed chop path".split(),
     "heart": ["they", "said", "are", "of", "do", "my", "all", "have"],
     "chains": [["ship", "shop", "chop", "chip", "chin", "thin"], ["ring", "king", "sing", "sink", "pink", "wink"],
                ["fish", "dish", "wish", "with", "whip", "ship"], ["chick", "check", "neck", "deck", "duck", "dock"]],
     "sentences": [("The fish is in the dish.", "🐟🍽️", ["🐟🛁", "🐱🍽️"]), ("A king has a ring.", "🤴💍", ["👸💍", "🤴🔔"]),
                   ("The chick is on the ship.", "🐤🚢", ["🐤🛏️", "🐶🚢"])],
     "unicorn": ["shom", "chut", "thip", "wheg", "mong", "chab", "shen", "thup", "lich", "bink"]},
    {"id": 4, "name": "Blend Bridge", "graphemes": [],
     "words": "lamp jump hand milk tent belt nest mask desk gift sand stop frog clap swim drum flag crab sled plum stamp trunk plant skunk drink twins camp brush clock dress black snack spill smell".split(),
     "heart": ["here", "there", "where", "what", "come", "some", "one", "two", "like", "look"],
     "chains": [["top", "stop", "step", "stem", "stems", "steps"], ["lap", "clap", "clip", "slip", "slim", "swim"],
                ["hand", "band", "bend", "bent", "tent", "tend"], ["lamp", "camp", "clamp", "cramp", "crams", "clams"]],
     "sentences": [("The frog can jump.", "🐸⬆️", ["🐸💤", "🦘⬆️"]), ("A crab is in the sand.", "🦀🏖️", ["🦀🛁", "🐸🏖️"]),
                   ("Stop at the flag!", "🛑🚩", ["🏃🚩", "🛑🎁"])],
     "unicorn": ["blom", "fesk", "trap", "gromp", "slib", "drend", "plim", "stug", "frax", "clent"]},
    {"id": 5, "name": "Magic E", "graphemes": ["a_e", "i_e", "o_e", "u_e", "e_e"],
     "words": "cape cake gate lake snake kite bike five pine rope nose bone home cube flute tape robe hose plane smile dime mule slide grape sunset cupcake".split(),
     "heart": ["were", "your", "put", "push"],
     "chains": [["cap", "cape", "tap", "tape", "tub", "tube"], ["pin", "pine", "kit", "kite", "hop", "hope"],
                ["rob", "robe", "cub", "cube", "not", "note"], ["mad", "made", "hid", "hide", "rid", "ride"]],
     "sentences": [("The snake ate the cake.", "🐍🎂", ["🐍🍞", "🐸🎂"]), ("I like my kite.", "🧒🪁", ["🧒🚲", "🐱🪁"])],
     "unicorn": ["bame", "zike", "pome", "vate", "nibe", "jote", "fune", "sope", "dake", "tibe"]},
    {"id": 6, "name": "Vowel Teams", "graphemes": ["ee", "ea", "ai", "ay", "oa", "ow", "igh", "oo", "ou", "oi", "oy", "ar", "or", "er", "ir", "ur"],
     "words": "tree bee feet sheep leaf seal rain snail train tray boat goat coat snow bow night light moon spoon book foot cloud house cow owl coin boy toy car star fork corn horse bird girl purse shark storm tail queen peach soap".split(),
     "heart": [],
     "chains": [["boat", "coat", "goat", "goal", "coal", "coat"], ["rain", "pain", "paint", "faint", "fain", "rain"],
                ["moon", "soon", "spoon", "spook", "spool", "stool"], ["car", "card", "hard", "harm", "farm", "far"]],
     "sentences": [("A bee is in the tree.", "🐝🌳", ["🐝🌧️", "🐦🌳"]), ("The goat is in the boat.", "🐐⛵", ["🐐🚗", "🐑⛵"])],
     "unicorn": ["deeb", "zoat", "fight", "moop", "kair", "boyt", "sharf", "gurm", "plee", "vay"]},
    {"id": 7, "name": "Big Words", "graphemes": [],
     "words": "rabbit picnic kitten muffin napkin sunset jumping".split(),
     "heart": [],
     "chains": [], "sentences": [], "unicorn": []},
]


# Warm-ups (learning path section 5). Picture words only; nothing to read.
RHYME_SETS = [  # three rhyme, one doesn't (the last word is the odd one)
    ("cat", "hat", "bat", "dog"), ("pig", "wig", "dig", "sun"), ("bug", "rug", "mug", "hen"),
    ("ten", "hen", "pen", "box"), ("fox", "box", "sock", "cup"), ("cake", "snake", "lake", "bus"),
    ("moon", "spoon", "balloon", "car"), ("bee", "tree", "key", "fish"), ("star", "car", "jar", "bed"),
    ("goat", "boat", "coat", "pig"), ("king", "ring", "wing", "map"), ("bell", "shell", "well", "fan"),
]
SYLLABLE_WORDS = [  # word, picture, syllables
    ("cat", "🐱", 1), ("sun", "☀️", 1), ("frog", "🐸", 1), ("fish", "🐟", 1), ("tree", "🌳", 1),
    ("rabbit", "🐇", 2), ("pizza", "🍕", 2), ("apple", "🍎", 2), ("tiger", "🐯", 2), ("rocket", "🚀", 2),
    ("monkey", "🐒", 2), ("cupcake", "🧁", 2), ("butterfly", "🦋", 3), ("banana", "🍌", 3),
    ("elephant", "🐘", 3), ("dinosaur", "🦕", 3), ("tomato", "🍅", 3), ("kangaroo", "🦘", 3),
]
ONSET_ITEMS = [  # onset, rime, word
    ("c", "at", "cat"), ("p", "ig", "pig"), ("s", "un", "sun"), ("d", "og", "dog"), ("h", "en", "hen"),
    ("b", "ug", "bug"), ("f", "ox", "fox"), ("m", "ap", "map"), ("n", "et", "net"), ("b", "us", "bus"),
]
EXTRA_PICTURES = {"key": "🔑", "jar": "🫙", "well": "🪣", "balloon": "🎈"}


# Word picture cards from the art pack (art/cutisie/out/words/manifest.json):
# word -> "clear" | "weak". Weak cards never stand alone as a picture-pick clue.
_ART_MANIFEST = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                             "art/cutisie/out/words/manifest.json")
ART = {}
if os.path.exists(_ART_MANIFEST):
    with open(_ART_MANIFEST) as f:
        ART = {w: e.get("strength", "clear") for w, e in json.load(f)["pictures"].items()}


def pictureable(text):
    """Can stand as a picture-pick answer or distractor."""
    if ART.get(text) == "weak":
        return False
    return text in PICTURES or ART.get(text) == "clear"


def split(word, stage):
    """Greedy grapheme split using units taught by `stage` (and magic e)."""
    w = word.lower()
    out, i = [], 0
    units = [g for g, s in MULTI if s <= max(stage, 2)]
    while i < len(w):
        for g in units:
            if w.startswith(g, i):
                out.append(g)
                i += len(g)
                break
        else:
            out.append(w[i])
            i += 1
    return out


def sounds_for(word, graphemes, stage):
    if word in SOUND_OVERRIDES:
        return SOUND_OVERRIDES[word]
    s = list(graphemes)
    # magic e: vowel, consonant, final e  ->  long vowel, silent e
    if stage >= 5 and len(s) >= 3 and s[-1] == "e" and s[-3] in VOWELS and s[-2] not in VOWELS:
        s[-3] = s[-3] + "_e"
        s[-1] = ""
    # double letters split into separate tiles say one sound
    for i in range(1, len(s)):
        if s[i] == s[i - 1] and len(s[i]) == 1 and s[i] not in VOWELS:
            s[i] = ""
    return s


def pick_distractors(w, stage_id):
    target = w["graphemes"]
    scored = []
    pool = {t: PICTURES.get(t, "🖼️" + t) for t in set(PICTURES) | {a for a, s in ART.items() if s == "clear"}}
    for t, pic in pool.items():
        if t == w["text"] or pic == w["picture"] or not pictureable(t):
            continue
        g = split(t, stage_id)
        if len(g) == len(target):
            diff = sum(a != b for a, b in zip(g, target))
            pos = next((i for i, (a, b) in enumerate(zip(g, target)) if a != b), None)
            if diff == 1:
                scored.append((0, pos, t))
            elif diff == 2 and g[0] == target[0]:
                scored.append((1, pos, t))
        elif g[0] == target[0] and abs(len(g) - len(target)) == 1:
            scored.append((2, 0, t))
    scored.sort()
    picked, positions, pics = [], set(), {w["picture"]}
    for rank, pos, t in scored:
        if pool[t] in pics or (rank == 0 and pos in positions and len(scored) > 3):
            continue
        picked.append(t)
        positions.add(pos)
        pics.add(pool[t])
        if len(picked) == 2:
            break
    return picked


def build():
    taught_pictured = []  # (stage, text, graphemes) of pictured words so far
    stages = []
    for st in STAGES:
        stage_id = st["id"]
        words = []
        for text in st["words"]:
            g = split(text, stage_id)
            words.append({"text": text, "graphemes": g, "sounds": sounds_for(text, g, stage_id),
                          "picture": PICTURES.get(text) or ("🖼️" if ART.get(text) == "clear" else None),
                          "art": ART.get(text), "stage": stage_id})
            if PICTURES.get(text):
                taught_pictured.append((stage_id, text, g))
        # Picture distractors: the child only reads the target, so any word
        # with a picture can be a distractor. Prefer one sound off (so a right
        # pick can't be a first-letter guess), then same first sound.
        for w in words:
            w["distractors"] = pick_distractors(w, stage_id) if pictureable(w["text"]) else []
        chains = []
        for c in st["chains"]:
            chains.append([{"text": t, "graphemes": split(t, stage_id), "sounds": sounds_for(t, split(t, stage_id), stage_id),
                            "picture": PICTURES.get(t) or ("🖼️" if t in ART else None), "art": ART.get(t)} for t in c])
        stages.append({
            "id": stage_id, "name": st["name"], "graphemes": st["graphemes"], "words": words,
            "heartWords": st["heart"], "chains": chains,
            "sentences": [{"text": t, "picture": p, "distractors": d} for t, p, d in st["sentences"]],
            "unicornWords": [{"text": u, "graphemes": split(u, stage_id), "sounds": sounds_for(u, split(u, stage_id), stage_id)}
                             for u in st["unicorn"]],
        })
    pics = {**PICTURES, **EXTRA_PICTURES}
    warmups = {
        "rhymeSets": [{"words": [{"text": t, "picture": pics[t]} for t in group], "odd": group[-1]} for group in RHYME_SETS],
        "syllables": [{"text": t, "picture": p, "count": n} for t, p, n in SYLLABLE_WORDS],
        "onsets": [{"onset": o, "rime": r, "word": w, "picture": pics[w],
                    "distractors": [d["text"] for d in [{"text": x} for x in (pick_distractors({"text": w, "graphemes": split(w, 2), "picture": pics[w]}, 2))]]}
                   for o, r, w in ONSET_ITEMS],
    }
    for group in RHYME_SETS:
        for t in group:
            assert t in pics, f"no picture for rhyme word {t}"
    known = {w["text"] for st in stages for w in st["words"]} | {w["text"] for st in stages for c in st["chains"] for w in c}
    extra = [{"text": t, "graphemes": split(t, 6), "picture": PICTURES.get(t) or "🖼️", "art": ART.get(t)}
             for t in sorted((set(PICTURES) | set(ART)) - known)]
    return {"version": 1, "stages": stages, "warmups": warmups, "pictureWords": extra}


if __name__ == "__main__":
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    out = os.path.join(root, "app/L2RR2L/Resources/Media/content/curriculum.json")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    data = build()
    with open(out, "w") as f:
        json.dump(data, f, ensure_ascii=False, indent=1)
    for s in data["stages"]:
        playable = sum(1 for w in s["words"] if len(w["distractors"]) == 2)
        print(f"stage {s['id']} {s['name']}: {len(s['words'])} words ({playable} with picture choices), "
              f"{len(s['chains'])} chains, {len(s['heartWords'])} heart words, {len(s['sentences'])} sentences")
    print("wrote", out)
