# Implementation Plan: Game UX Delight Overhaul

**Branch**: `011-game-ux-delight` | **Date**: 2026-03-05
**Epic**: `l2rr2l-011` | **Priority**: P1

## Summary

Transform all 6 games from functional learning tools into delightful, juice-filled experiences that kids can't put down. Build a centralized animation system for consistent micro-interactions, add an animated mascot character that reacts to gameplay, create a persistent sticker/trophy collection system, and apply per-game UX polish. MVP focus is micro-interaction juice — making every tap, drag, and answer feel amazing.

## Bead Map

- `l2rr2l-011` - Root: Game UX Delight Overhaul
  - `l2rr2l-011.1` - Foundation: Animation System & Mascot Assets
    - `l2rr2l-011.1.1` - Create JuiceAnimations shared module
    - `l2rr2l-011.1.2` - Create MascotView and MascotState
    - `l2rr2l-011.1.3` - Create StickerBook data model and persistence
    - `l2rr2l-011.1.4` - Create AnimationConfig with centralized spring/timing constants
  - `l2rr2l-011.2` - Micro-Interaction Juice (MVP)
    - `l2rr2l-011.2.1` - Add juice to Spelling Game interactions
    - `l2rr2l-011.2.2` - Add juice to Memory Match interactions
    - `l2rr2l-011.2.3` - Add juice to Phonics Game interactions
    - `l2rr2l-011.2.4` - Add juice to Rhyme Time interactions
    - `l2rr2l-011.2.5` - Add juice to Word Builder interactions
    - `l2rr2l-011.2.6` - Add juice to Read Aloud interactions
    - `l2rr2l-011.2.7` - Add universal button press animation modifier
  - `l2rr2l-011.3` - Animated Mascot Character
    - `l2rr2l-011.3.1` - Implement MascotView with animation states
    - `l2rr2l-011.3.2` - Integrate mascot into all 6 game views
    - `l2rr2l-011.3.3` - Add inactivity hint system with contextual messages
    - `l2rr2l-011.3.4` - Add mascot to completion/results screens
  - `l2rr2l-011.4` - Per-Game UX Improvements
    - `l2rr2l-011.4.1` - Spelling: hint system + rainbow shimmer on completion
    - `l2rr2l-011.4.2` - Memory: card peek on first play + speed match bonus
    - `l2rr2l-011.4.3` - Phonics: sound wave visualization on option tap
    - `l2rr2l-011.4.4` - Rhyme: rhythmic word bounce animation
    - `l2rr2l-011.4.5` - Word Builder: emoji comes alive animation
    - `l2rr2l-011.4.6` - Read Aloud: colorful waveform + practice mode
  - `l2rr2l-011.5` - Persistent Reward System
    - `l2rr2l-011.5.1` - Implement sticker earning logic in game ViewModels
    - `l2rr2l-011.5.2` - Build TrophyRoomView (sticker book UI)
    - `l2rr2l-011.5.3` - Add sticker fly-in animation on game complete
    - `l2rr2l-011.5.4` - Add trophy room tab/button to home screen
  - `l2rr2l-011.6` - Celebration & Transition Polish
    - `l2rr2l-011.6.1` - Animated between-round transitions for all games
    - `l2rr2l-011.6.2` - Personalized completion ceremony with child name
    - `l2rr2l-011.6.3` - New personal best detection and celebration
    - `l2rr2l-011.6.4` - Level-up ceremony animation

## Technical Context

**Stack**: SwiftUI, Combine, AVFoundation, Swift 5.9+
**Storage**: UserDefaults / SwiftData for sticker persistence
**Testing**: XCTest, SwiftUI Previews
**Constraints**: 60fps on iPhone 12+, respect accessibilityReduceMotion, all spring animations must use SwiftUI native `.spring()` modifiers

## Architecture Decision

**Centralized Animation System**: Instead of scattering animation code across 6 games, create a `JuiceAnimations` module with reusable view modifiers:
- `.juicyTap()` - squash/stretch on tap
- `.juicyDrag()` - particle trail + scale on drag
- `.juicyCorrect()` - celebratory bounce + stars
- `.juicyIncorrect()` - gentle wobble (not scary)
- `.juicySnap()` - snap-into-place with pulse ring
- `.juicyFlip()` - 3D flip with overshoot

This approach ensures consistency across all games and makes it trivial to add juice to new games in the future. The mascot is a separate `MascotView` that observes game state and reacts via published events.

**Sticker Persistence**: Use SwiftData with a simple `Sticker` model. Lightweight, no API sync needed, survives app reinstall via iCloud backup.

## Files Changed

| File | Change |
|------|--------|
| `Features/Shared/Animations/JuiceAnimations.swift` | NEW - Reusable juice view modifiers |
| `Features/Shared/Animations/AnimationConfig.swift` | NEW - Centralized spring/timing constants |
| `Features/Shared/Animations/ParticleEmitter.swift` | NEW - Particle trail and burst effects |
| `Features/Shared/Animations/StarBurst.swift` | NEW - Star burst effect for correct answers |
| `Features/Shared/Components/MascotView.swift` | NEW - Animated mascot character |
| `Features/Shared/Components/MascotState.swift` | NEW - Mascot state machine |
| `Features/Shared/Components/InactivityHintManager.swift` | NEW - Hint timer and contextual messages |
| `Features/Rewards/Models/Sticker.swift` | NEW - Sticker data model |
| `Features/Rewards/Models/StickerBook.swift` | NEW - Collection manager |
| `Features/Rewards/Views/TrophyRoomView.swift` | NEW - Sticker book UI |
| `Features/Rewards/Views/StickerFlyInView.swift` | NEW - Sticker award animation |
| `Features/SpellingGame/Views/SpellingGameView.swift` | Modify - Add juice modifiers, mascot, hints |
| `Features/SpellingGame/Views/Components/LetterTile.swift` | Modify - Add .juicyTap() |
| `Features/SpellingGame/Views/Components/DropZone.swift` | Modify - Add .juicySnap() |
| `Features/MemoryGame/Views/MemoryGameView.swift` | Modify - Add juice, mascot, card peek |
| `Features/MemoryGame/Views/Components/FlipCard.swift` | Modify - Add .juicyFlip() |
| `Features/PhonicsGame/Views/PhonicsGameView.swift` | Modify - Add juice, mascot, sound wave |
| `Features/RhymeGame/Views/RhymeGameView.swift` | Modify - Add juice, mascot, rhythmic bounce |
| `Features/WordBuilder/Views/WordBuilderView.swift` | Modify - Add juice, mascot, emoji animation |
| `Features/ReadAloud/Views/ReadAloudGameView.swift` | Modify - Add juice, mascot, waveform |
| `Features/Home/Views/HomeView.swift` | Modify - Add trophy room button |
| `Theme/L2RTheme.swift` | Modify - Add animation constants |
| `Core/Services/SoundEffectService.swift` | Modify - Add new reward/mascot sounds |

## Phase 1: Foundation
Create the shared animation system, mascot component, and sticker data model. All subsequent phases depend on this.

## Phase 2: Micro-Interaction Juice (MVP)
Apply juice modifiers to all 6 games. Each game can be juiced in parallel since they touch different files. Add universal button press animation.

## Phase 3: Animated Mascot Character
Build the mascot view with all animation states, integrate into all 6 games, add inactivity hints, add to completion screens.

## Phase 4: Per-Game UX Improvements
Game-specific enhancements that require the juice system (Phase 2) to be in place. All 6 games can be improved in parallel.

## Phase 5: Persistent Reward System
Build sticker earning, trophy room UI, fly-in animation, and home screen integration. Requires foundation (Phase 1) for data model.

## Phase 6: Celebration & Transition Polish
Final polish layer: between-round transitions, personalized ceremonies, personal best detection, level-up animations. Depends on mascot (Phase 3) and rewards (Phase 5).

## Parallel Execution

- **Phase 2 tasks** (all 7): Can run in parallel — each game is independent
- **Phase 3 and Phase 5**: Can run in parallel after Phase 1 (no cross-dependencies)
- **Phase 4 tasks** (all 6): Can run in parallel after Phase 2
- **Phase 6**: Must wait for Phases 3 + 5

## Verification Steps

- [ ] Every tap/drag/answer in all 6 games has visible animated feedback
- [ ] Mascot appears and reacts appropriately in all games
- [ ] Trophy room shows earned stickers, persists across launches
- [ ] All animations maintain 60fps on iPhone 12 (Instruments profiling)
- [ ] All animations disabled/simplified when reduce-motion is on
- [ ] VoiceOver reads mascot speech bubbles and sticker names
- [ ] No "dead" interactions — every interactive element has feedback
