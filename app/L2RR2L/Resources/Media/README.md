# Media drop folder

Everything in here is copied into the app bundle as-is (it's a folder reference
in `project.yml`), so adding a file needs no project change. The code already
looks for these names and falls back to built-in placeholders when a file is
missing.

| Folder | Files | Used by |
|---|---|---|
| `mascot/` | `hello`, `cheer`, `dance`, `encourage`, `think`, `listen`, `fly`, `read`, `bird` as `.mp4`/`.mov` (HEVC with alpha works); stills `idle`, `wave`, `cheer`, `think`, `listen`, `fly`, `read`, `proud`, `bird` as `.png` | `MascotClip`, `MascotView` |
| `sfx/` | `tap`, `pick`, `drop`, `correct`, `oops`, `star`, `sticker`, `fanfare`, `whoosh`, `pop` as `.wav`/`.m4a`/`.caf` | `SoundEffects` (replaces the synth sound) |
| `phonemes/` | pure letter sounds: `m.m4a`, `sh.m4a` … plus optional held versions `m-long.m4a` for stretching | `Speaker.sayLetterSound` |
| `words/` | spoken words: `cat.m4a` … | `Speaker.sayWord` |

Painted backgrounds (`bg-home`, `bg-blend`, `bg-build`, `bg-catch`) go in
`Assets.xcassets` as image sets with those names.

Names match `art/cutisie/BRIEF.md`.
