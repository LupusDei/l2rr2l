# Media

Everything in here is copied into the app bundle as-is (a folder reference in
`project.yml`), so adding a file needs no project change.

| Folder | Contents | Used by |
|---|---|---|
| `mascot/poses/` | Cutisie's 17 pose stills from the art pack (640px) | `MascotView` when clips aren't bundled |
| `mascot/clips/` | **not committed**: the 52 HEVC-with-alpha `.mov` clips, copied in at build time from `art/cutisie/out/videos/alpha` by the "Bundle Cutisie clips" build step | `MascotClip`, `MascotVideoPlayer` |
| `scenes/` | **not committed**: game intro and story scenes, copied the same way from `art/cutisie/out/videos/scenes` | game intros (to come) |
| `backgrounds/` | painted scenes (`bg-home`, `bg-blend`, `bg-build`, `bg-catch`, `bg-treasure`, ...) | `SkyBackground(imageName:)` |
| `cutisie-sfx/` | art-pack sounds; several stand in for app effects (see `SoundEffects.packNames`) | `SoundEffects` |
| `narration/` | placeholder Star Voice lines for the story beats | story (to come) |
| `sfx/` | optional overrides named after `SoundEffect` cases | `SoundEffects` |
| `phonemes/` | pure letter sounds: `m.m4a`, `sh.m4a`, plus held `m-long.m4a` | `Speaker.sayLetterSound` |
| `words/` | spoken words: `cat.m4a` | `Speaker.sayWord` |

Clip ids and which moment uses them are in `MascotClip.takes`, matching
`art/cutisie/out/manifest.json`.
