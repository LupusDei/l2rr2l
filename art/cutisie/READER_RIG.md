# Cutisie's reading rig (Read Along)

Read Along needs Cutisie to sound out and read any word in the curriculum,
in sync with the recorded Star Voice. A video per word would mean hundreds of
clips (about 340 words today, more every stage), each one a Runway job, each
one drifting out of sync with the audio, and a new clip for every new word.

Instead she is a **puppet**: one still of her reading, plus seven small mouth
patches and a blink, swapped in real time. The app already knows every word's
sounds (`Word.soundKeys`) and has every recording, so it drives the mouth
itself. Nine pictures cover every word, forever.

| Piece | What it is | Made by |
|---|---|---|
| `base.png` | Cutisie sitting with her glowing book, mouth closed, looking at the viewer (the `read` pose) | Runway image, from `refs/master.png` + `poses/read.png` |
| `mouth_closed` | lips together: m, b, p, rest | Runway edit of base |
| `mouth_small` | slightly open: t, d, n, l, k, g, h, r, th | " |
| `mouth_open` | jaw dropped: a, o, u, ar, igh | " |
| `mouth_wide` | wide smile, teeth: e, i, ee, s, z, a_e | " |
| `mouth_round` | small round "oo": oo, oa, o_e, w, or | " |
| `mouth_pucker` | lips pushed out: sh, ch, j | " |
| `mouth_teeth` | top teeth on lip: f, v | " |
| `blink` | eyes gently closed | " |

All in `app/L2RR2L/Resources/Media/mascot/reader/`, made by
`tools/make_reader_rig.py` (about 0.5 MB in total).

## How the app uses it (`Mascot/CutisieReader.swift`, `Mascot/LipSync.swift`)

- **Sounding out:** as `PhonemeEngine` plays each sound, the mouth snaps to
  that sound's shape and her horn flashes.
- **Saying a word:** the word recording's loudness (1/30 s frames) decides
  open or closed; the word's sounds are spread over the voiced part, vowels
  longer. Computed once per word on device, no data files.
- **Reading along silently** (the child's turn): the same track with no audio.
- **Life:** blink every few seconds, breathing bob, hop and wobble reactions.
- **Big moments** (cheer, oops, round done) crossfade to the existing video
  takes from the art pack, then back to the rig.

Without the rig art the game still works: she uses the `read` pose and nods
with each sound.

## Making the takes

1. Generate `base.png`: the `read` pose, 1:1, transparent or plain background,
   **mouth closed in a soft smile**, camera locked.
2. For each shape, generate 3 or 4 takes with the base as the reference image:
   "the same picture, identical pose and camera; only her mouth changes:
   <shape description>". Save as `<shape>_1.png`, `<shape>_2.png` ... in one
   folder with `base.png`. Same for `blink_N.png`.
3. Remove backgrounds if needed so every take has alpha.
4. Run `python3 tools/make_reader_rig.py <folder> --horn x,y`. For each shape it
   lines every take up with the base, keeps the one that changed least
   outside the mouth, and cuts just the mouth area with a soft edge, so the
   rest of her stays pixel-identical. It writes `rig-preview.png` beside the
   takes: check every mouth by eye.
5. Set `--horn` to the horn tip as a fraction of the image (the beam to the
   word starts there), and `--mouth`/`--eyes` boxes if the pose differs.

Alternative for step 2: Runway Act-Two with a 15 s driving video mouthing
"mm, ah, ee, oo, sh, ff, la" gives every shape in one consistent take; export
frames as `<shape>_N.png` and run the same script.
