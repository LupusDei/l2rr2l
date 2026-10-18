# L2RR2L: Cutisie's Sky

A reading game for a nearly-6-year-old, iPad first with iPhone support. Native SwiftUI.
Cutisie Cute, a winged baby unicorn, lives in a night sky; an off-screen narrator, the
Star Voice, does all the talking. The first web/iOS attempt lives in `archive/v1/`.

## Run it

```bash
cd app && xcodegen generate   # only after adding/removing source files
open L2RR2L.xcodeproj         # pick an iPad simulator, Run
```

Requires Xcode 26+, iOS 18 deployment target. `brew install xcodegen` if you change files.

## Layout

| Folder | What |
|---|---|
| `app/L2RR2L/App` | entry point, `AppServices` (shared systems + the "correct / oops / round done / sticker" moments), router |
| `app/L2RR2L/Design` | theme, living parallax sky, chunky 3D buttons, title lettering |
| `app/L2RR2L/Feedback` | synthesized sound palette (swap in real files), haptics (iPhone only; iPads have none) |
| `app/L2RR2L/Speech` | `Speaker` (TTS, IPA pure letter sounds, recordings win), `StarVoice` narrator, `PhonemeEngine` (holdable letter sounds for blending) |
| `app/L2RR2L/Mascot` | `MascotDirector` reactions and `MascotView` (video clip, still, or animated interim art) |
| `app/L2RR2L/Celebration` | confetti, fireworks, sticker reveal overlay |
| `app/L2RR2L/Progress` | saved progress: stages, word mastery over days, spaced review, error patterns, skills with prerequisites/bridges, milestones, stars, treats, egg, sticker book |
| `app/L2RR2L/Games` | game catalog, shared game screen, and the three playable games: Stretchy Blend, Word Machine, Star Catch (content in `Games/Content/WordBank.swift`) |
| `app/L2RR2L/Resources/Media` | drop folder for mascot clips, sounds, phonemes, words (see its README) |
| `art/cutisie` | mascot art brief and references |

## Adding a game

1. Create `app/L2RR2L/Games/<Name>/<Name>View.swift`.
2. Return it from the matching case in `GameID.makeView()` and flip `isReady`.
3. Use `AppServices` for everything that should feel the same across games:
   `voice.say(...)`, `voice.sayLetterSound(...)`, `celebrateCorrect(game:word:usedAudioHelp:responseTime:)`,
   `encourageRetry(game:word:errorTags:)`, `celebrateRoundComplete(game:)`, `mascot.react(...)`.
