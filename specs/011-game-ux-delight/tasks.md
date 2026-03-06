# Tasks: Game UX Delight Overhaul

**Input**: Design documents from `/specs/011-game-ux-delight/`
**Epic**: `l2rr2l-011`

## Format: `[ID] [P?] [Story] Description`

- **T-IDs** (T001, T002): Sequential authoring IDs for this document
- **Bead IDs** (l2rr2l-011.N.M): Assigned in beads-import.md after bead creation
- **[P]**: Can run in parallel (different files, no deps)
- **[Story]**: User story label (US1-US5)

## Phase 1: Foundation — Animation System & Mascot Assets

**Purpose**: Create shared infrastructure that all subsequent phases depend on.

- [ ] T001 [P] Create JuiceAnimations module with reusable view modifiers (.juicyTap, .juicyDrag, .juicyCorrect, .juicyIncorrect, .juicySnap, .juicyFlip) in `Features/Shared/Animations/JuiceAnimations.swift`. Include ParticleEmitter and StarBurst sub-views. All modifiers must respect accessibilityReduceMotion.
- [ ] T002 [P] Create MascotView component with MascotState state machine (idle, celebrating, encouraging, hinting, dancing, proud) in `Features/Shared/Components/MascotView.swift` and `MascotState.swift`. Use SF Symbols or simple SwiftUI shapes for the mascot (friendly animal face). Include speech bubble overlay with randomized encouraging messages.
- [ ] T003 [P] Create StickerBook data model and persistence layer in `Features/Rewards/Models/Sticker.swift` and `StickerBook.swift`. Sticker has: id, type (normal/golden/special), gameSource, dateEarned, displayName, emoji. StickerBook manages collection with SwiftData persistence.
- [ ] T004 [P] Create AnimationConfig with centralized spring/timing constants in `Features/Shared/Animations/AnimationConfig.swift`. Define: tapSpring, dragScale, correctBounce, incorrectWobble, snapPulse, flipOvershoot, celebrationDuration. Add to L2RTheme as static constants.

**Checkpoint**: Foundation ready — all shared components available for game integration.

---

## Phase 2: Micro-Interaction Juice (MVP) — US1

**Goal**: Make every interaction in all 6 games feel satisfying and alive. MVP delivery.
**Independent Test**: Play each game — every tap, drag, correct answer, and incorrect answer has visible animated feedback.

- [ ] T005 [P] [US1] Add juice to Spelling Game: .juicyTap() on LetterTile, .juicySnap() on DropZone letter placement, .juicyDrag() on DraggableLetter, .juicyCorrect() on word completion, .juicyIncorrect() gentle wobble on wrong answer. Files: `SpellingGame/Views/SpellingGameView.swift`, `Components/LetterTile.swift`, `Components/DropZone.swift`, `Components/DraggableLetter.swift`
- [ ] T006 [P] [US1] Add juice to Memory Match: .juicyFlip() with overshoot on FlipCard, .juicyCorrect() star burst on match found, .juicyTap() on card tap, sparkle overlay on card reveal. Files: `MemoryGame/Views/MemoryGameView.swift`, `Components/FlipCard.swift`
- [ ] T007 [P] [US1] Add juice to Phonics Game: .juicyTap() on sound option cards, .juicyCorrect() on correct sound selection, scale-up with border glow on selection, .juicyIncorrect() gentle wobble. Files: `PhonicsGame/Views/PhonicsGameView.swift`
- [ ] T008 [P] [US1] Add juice to Rhyme Time: .juicyTap() on rhyme option cards, .juicyCorrect() on correct rhyme, bounce animation on option selection, .juicyIncorrect() wobble. Files: `RhymeGame/Views/RhymeGameView.swift`
- [ ] T009 [P] [US1] Add juice to Word Builder: .juicyTap() on letter tiles, .juicySnap() on letter placement in slots, .juicyCorrect() on word completion, .juicyIncorrect() wobble on wrong word. Files: `WordBuilder/Views/WordBuilderView.swift`
- [ ] T010 [P] [US1] Add juice to Read Aloud: .juicyTap() on mic button with pulse enhancement, .juicyCorrect() on successful pronunciation, bouncy score counter on points earned, .juicyIncorrect() gentle encouragement animation. Files: `ReadAloud/Views/ReadAloudGameView.swift`
- [ ] T011 [P] [US1] Create universal .juicyButtonPress() view modifier that applies micro-press (scale 0.95x → 1.0x spring) to all buttons across the app. Apply to game action buttons (Check, Clear, Shuffle, Next, Listen). File: `Features/Shared/Animations/JuiceAnimations.swift` + all game views

**Checkpoint**: MVP complete — all games feel juicy and alive.

---

## Phase 3: Animated Mascot Character — US2

**Goal**: Add a friendly mascot that reacts to gameplay and creates emotional connection.
**Independent Test**: Play a full game session, verify mascot appears and reacts to correct/incorrect/streak/inactivity.

- [ ] T012 [US2] Implement full MascotView with all animation states: idle (gentle floating), celebrating (jump + spin), encouraging (supportive nod + speech bubble), hinting (wave + pointing gesture), dancing (streak celebration), proud (game-complete pose). Add randomized speech bubble messages per state (8+ messages per category). File: `Features/Shared/Components/MascotView.swift`
- [ ] T013 [P] [US2] Integrate mascot into all 6 game views: position mascot in bottom-left or bottom-right corner, wire game ViewModel published state changes to MascotState transitions. Each game view gets a MascotView overlay. Files: all 6 game View files
- [ ] T014 [US2] Implement InactivityHintManager: 8s timer triggers mascot wave, 15s timer triggers contextual hint with speech bubble and subtle arrow pointing to the relevant UI element. Each game provides its own hint messages (e.g., Spelling: "Try tapping a letter!", Memory: "Tap a card to flip it!"). File: `Features/Shared/Components/InactivityHintManager.swift` + game ViewModels
- [ ] T015 [US2] Add mascot to all game completion/results screens: large mascot with proud animation, personalized speech bubble ("You did amazing, [Name]!"), mascot dances during confetti celebration. Files: all 6 game completion views

**Checkpoint**: Mascot fully integrated — kids have a companion in every game.

---

## Phase 4: Per-Game UX Improvements — US3

**Goal**: Each game gets unique UX improvements tailored to its mechanics.
**Independent Test**: Play each game and verify its specific improvements.

- [ ] T016 [P] [US3] Spelling Game improvements: (1) Hint system — after 10s stuck, next correct letter gently pulses in letter bank with glow effect. (2) Rainbow shimmer animation on completed word. (3) Emoji hint bounces/sparkles when word is correctly spelled. Files: `SpellingGame/Views/SpellingGameView.swift`, `SpellingGame/ViewModels/SpellingGameViewModel.swift`
- [ ] T017 [P] [US3] Memory Match improvements: (1) Card peek on first play of each level — all cards show face for 2s then flip back. (2) Speed Match bonus — if child matches within 2s of first flip, play "Speed Match!" celebration with bonus points. (3) Combo counter for consecutive matches. Files: `MemoryGame/Views/MemoryGameView.swift`, `MemoryGame/ViewModels/MemoryGameViewModel.swift`
- [ ] T018 [P] [US3] Phonics Game improvements: (1) Sound wave visualization — when a sound option is tapped, colorful ripple/wave animation expands from the card. (2) Sound is spoken aloud when option is tapped (not just on the target word). Files: `PhonicsGame/Views/PhonicsGameView.swift`, `PhonicsGame/ViewModels/PhonicsGameViewModel.swift`
- [ ] T019 [P] [US3] Rhyme Time improvements: (1) Target word bounces in rhythmically on round start (like it's being spoken in beat). (2) Rhyming option words subtly bounce in sync with target word rhythm. (3) Musical note particles on correct rhyme selection. Files: `RhymeGame/Views/RhymeGameView.swift`, `RhymeGame/ViewModels/RhymeGameViewModel.swift`
- [ ] T020 [P] [US3] Word Builder improvements: (1) Emoji "comes alive" animation when word is correctly built — emoji bounces, sparkles, and a brief related animation plays (cat meows, sun shines). (2) Building blocks visual metaphor — letters stack like blocks. Files: `WordBuilder/Views/WordBuilderView.swift`, `WordBuilder/ViewModels/WordBuilderViewModel.swift`
- [ ] T021 [P] [US3] Read Aloud improvements: (1) Colorful bouncing bar waveform during recording (replace ring visualization). (2) Practice mode toggle — child can hear word, attempt, hear again without scoring. (3) More engaging audio level visualization. Files: `ReadAloud/Views/ReadAloudGameView.swift`, `ReadAloud/ViewModels/ReadAloudViewModel.swift`

**Checkpoint**: All games have unique personality and polish.

---

## Phase 5: Persistent Reward System — US4

**Goal**: Children earn collectible stickers and can browse them in a trophy room.
**Independent Test**: Complete games, earn stickers, open trophy room, verify persistence across launches.

- [ ] T022 [US4] Implement sticker earning logic: each game ViewModel awards a sticker on session complete (normal sticker) or perfect score (golden sticker). Wire to StickerBook.addSticker(). Add sticker type variety per game (6 game-themed sticker sets, 5+ stickers each). Files: all 6 game ViewModels, `Features/Rewards/Models/StickerBook.swift`
- [ ] T023 [US4] Build TrophyRoomView: scrollable sticker book with 6 game category sections. Earned stickers shown colorfully with emoji + name. Unearned slots shown as grey silhouettes. Tap sticker for pop-up detail (date earned, game source). Sticker count header per category. File: `Features/Rewards/Views/TrophyRoomView.swift`
- [ ] T024 [US4] Create StickerFlyInView: when a sticker is earned on game complete, animate it flying from the results area to a sticker-book icon in the corner with a trail effect. Include "New Sticker!" text pop-up. File: `Features/Rewards/Views/StickerFlyInView.swift`
- [ ] T025 [US4] Add trophy room access to home screen: add a sticker book button/tab to HomeView. Show sticker count badge. Trophy room accessible from main navigation. Files: `Features/Home/Views/HomeView.swift`, navigation router updates

**Checkpoint**: Persistent reward loop complete — kids have a reason to come back.

---

## Phase 6: Celebration & Transition Polish — US5

**Goal**: Premium feel throughout — smooth transitions, personalized celebrations, personal bests.
**Independent Test**: Play through full sessions, verify all transitions are animated and completion uses child's name.

- [ ] T026 [P] [US5] Add animated between-round transitions to all 6 games: old content slides out with fade, "Round N!" counter bumps in with scale animation, new content slides in from opposite side. Consistent across all games via shared RoundTransitionView modifier. Files: all 6 game views, new `Features/Shared/Components/RoundTransitionView.swift`
- [ ] T027 [P] [US5] Enhance completion ceremony: use child's name ("Amazing job, [Name]!"), mascot proud dance, upgraded confetti with color-matched particles, star rating animates filling up one-by-one with delay, earned sticker flies in. Files: all 6 game completion views
- [ ] T028 [US5] Add personal best detection and celebration: track best score/moves per game in UserDefaults/SwiftData. On new record, show "New Record!" badge with special fanfare animation and sound. Files: game ViewModels, new `Features/Shared/Components/PersonalBestView.swift`
- [ ] T029 [US5] Level-up ceremony for games with multiple levels (Memory Match, Read Aloud): "Level Up!" animation with mascot, rising stars, preview of next challenge difficulty. Files: `MemoryGame/Views/MemoryGameView.swift`, `ReadAloud/Views/ReadAloudGameView.swift`

---

## Dependencies

- Phase 1 (Foundation) → blocks all other phases
- Phase 2 (Juice MVP) → can start after Phase 1; blocks Phase 4
- Phase 3 (Mascot) → can start after Phase 1; blocks Phase 6
- Phase 5 (Rewards) → can start after Phase 1; blocks Phase 6
- Phase 4 (Per-Game) → can start after Phase 2
- Phase 6 (Polish) → starts after Phases 3 + 5

## Parallel Opportunities

- T001, T002, T003, T004 (Phase 1): All parallel — different files
- T005-T011 (Phase 2): All parallel — each game is independent
- Phase 3 and Phase 5: Parallel tracks after Phase 1
- T016-T021 (Phase 4): All parallel — each game is independent
- T026, T027 (Phase 6): Parallel — different concerns
