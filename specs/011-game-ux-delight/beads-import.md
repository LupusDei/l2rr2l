# Game UX Delight Overhaul - Beads

**Feature**: 011-game-ux-delight
**Generated**: 2026-03-05
**Source**: specs/011-game-ux-delight/tasks.md

## Root Epic

- **ID**: l2rr2l-011
- **Title**: Game UX Delight Overhaul
- **Type**: epic
- **Priority**: 1
- **Description**: Transform all 6 games into delightful, juice-filled experiences. Add micro-interaction animations, animated mascot character, persistent sticker/trophy collection, per-game UX polish, and celebration upgrades. Target: ages 3-6.

## Epics

### Phase 1 — Foundation: Animation System & Mascot Assets
- **ID**: l2rr2l-011.1
- **Type**: epic
- **Priority**: 1
- **Tasks**: 4

### Phase 2 — US1: Micro-Interaction Juice (MVP)
- **ID**: l2rr2l-011.2
- **Type**: epic
- **Priority**: 1
- **MVP**: true
- **Blocks**: Phase 4
- **Tasks**: 7

### Phase 3 — US2: Animated Mascot Character
- **ID**: l2rr2l-011.3
- **Type**: epic
- **Priority**: 1
- **Tasks**: 4

### Phase 4 — US3: Per-Game UX Improvements
- **ID**: l2rr2l-011.4
- **Type**: epic
- **Priority**: 2
- **Depends**: Phase 2
- **Tasks**: 6

### Phase 5 — US4: Persistent Reward System
- **ID**: l2rr2l-011.5
- **Type**: epic
- **Priority**: 2
- **Tasks**: 4

### Phase 6 — US5: Celebration & Transition Polish
- **ID**: l2rr2l-011.6
- **Type**: epic
- **Priority**: 3
- **Depends**: Phase 3, Phase 5
- **Tasks**: 4

## Tasks

### Phase 1 — Foundation

| T-ID | Title | Path | Bead |
|------|-------|------|------|
| T001 | Create JuiceAnimations shared module | Features/Shared/Animations/JuiceAnimations.swift | l2rr2l-011.1.1 |
| T002 | Create MascotView and MascotState | Features/Shared/Components/MascotView.swift, MascotState.swift | l2rr2l-011.1.2 |
| T003 | Create StickerBook data model and persistence | Features/Rewards/Models/Sticker.swift, StickerBook.swift | l2rr2l-011.1.3 |
| T004 | Create AnimationConfig constants | Features/Shared/Animations/AnimationConfig.swift | l2rr2l-011.1.4 |

### Phase 2 — US1: Micro-Interaction Juice (MVP)

| T-ID | Title | Path | Bead |
|------|-------|------|------|
| T005 | Juice Spelling Game interactions | SpellingGame/Views/ | l2rr2l-011.2.1 |
| T006 | Juice Memory Match interactions | MemoryGame/Views/ | l2rr2l-011.2.2 |
| T007 | Juice Phonics Game interactions | PhonicsGame/Views/ | l2rr2l-011.2.3 |
| T008 | Juice Rhyme Time interactions | RhymeGame/Views/ | l2rr2l-011.2.4 |
| T009 | Juice Word Builder interactions | WordBuilder/Views/ | l2rr2l-011.2.5 |
| T010 | Juice Read Aloud interactions | ReadAloud/Views/ | l2rr2l-011.2.6 |
| T011 | Universal button press animation | Shared/Animations + all games | l2rr2l-011.2.7 |

### Phase 3 — US2: Animated Mascot Character

| T-ID | Title | Path | Bead |
|------|-------|------|------|
| T012 | Implement MascotView animation states | Features/Shared/Components/MascotView.swift | l2rr2l-011.3.1 |
| T013 | Integrate mascot into all 6 games | All 6 game View files | l2rr2l-011.3.2 |
| T014 | Inactivity hint system | InactivityHintManager.swift + game VMs | l2rr2l-011.3.3 |
| T015 | Add mascot to completion screens | All 6 game completion views | l2rr2l-011.3.4 |

### Phase 4 — US3: Per-Game UX Improvements

| T-ID | Title | Path | Bead |
|------|-------|------|------|
| T016 | Spelling: hints + rainbow shimmer | SpellingGame/ | l2rr2l-011.4.1 |
| T017 | Memory: card peek + speed match | MemoryGame/ | l2rr2l-011.4.2 |
| T018 | Phonics: sound wave visualization | PhonicsGame/ | l2rr2l-011.4.3 |
| T019 | Rhyme: rhythmic word bounce | RhymeGame/ | l2rr2l-011.4.4 |
| T020 | Word Builder: emoji comes alive | WordBuilder/ | l2rr2l-011.4.5 |
| T021 | Read Aloud: waveform + practice mode | ReadAloud/ | l2rr2l-011.4.6 |

### Phase 5 — US4: Persistent Reward System

| T-ID | Title | Path | Bead |
|------|-------|------|------|
| T022 | Sticker earning logic in ViewModels | All 6 game VMs + StickerBook | l2rr2l-011.5.1 |
| T023 | Build TrophyRoomView | Features/Rewards/Views/TrophyRoomView.swift | l2rr2l-011.5.2 |
| T024 | Sticker fly-in animation | Features/Rewards/Views/StickerFlyInView.swift | l2rr2l-011.5.3 |
| T025 | Trophy room home screen access | Features/Home/Views/HomeView.swift | l2rr2l-011.5.4 |

### Phase 6 — US5: Celebration & Transition Polish

| T-ID | Title | Path | Bead |
|------|-------|------|------|
| T026 | Animated between-round transitions | All 6 games + RoundTransitionView | l2rr2l-011.6.1 |
| T027 | Personalized completion ceremony | All 6 game completion views | l2rr2l-011.6.2 |
| T028 | Personal best detection + celebration | Game VMs + PersonalBestView | l2rr2l-011.6.3 |
| T029 | Level-up ceremony animation | MemoryGame + ReadAloud | l2rr2l-011.6.4 |

## Summary

| Phase | Tasks | Priority | Bead |
|-------|-------|----------|------|
| 1: Foundation | 4 | 1 | l2rr2l-011.1 |
| 2: Juice MVP | 7 | 1 | l2rr2l-011.2 |
| 3: Mascot | 4 | 1 | l2rr2l-011.3 |
| 4: Per-Game UX | 6 | 2 | l2rr2l-011.4 |
| 5: Rewards | 4 | 2 | l2rr2l-011.5 |
| 6: Polish | 4 | 3 | l2rr2l-011.6 |
| **Total** | **29** | | |

## Dependency Graph

```
Phase 1: Foundation (l2rr2l-011.1)
    |
    +---+---+---+
    |       |   |
Phase 2   Phase 3   Phase 5
Juice     Mascot    Rewards
(011.2)   (011.3)   (011.5)
    |       |         |
Phase 4   +-----------+
Per-Game        |
(011.4)    Phase 6
           Polish
           (011.6)
```

## Improvements

Improvements (Level 4: l2rr2l-011.N.M.P) are NOT pre-planned here. They are created
during implementation when bugs, refactors, or extra tests are discovered. See
SKILL.md "Improvements (Post-Planning)" section for the workflow.
