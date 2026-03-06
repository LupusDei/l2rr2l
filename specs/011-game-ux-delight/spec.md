# Feature Specification: Game UX Delight Overhaul

**Feature Branch**: `011-game-ux-delight`
**Created**: 2026-03-05
**Status**: Draft

## Context

L2RR2L is a reading app for children ages 3-6. The app has 6 games (Spelling, Memory Match, Phonics, Rhyme Time, Word Builder, Read Aloud) plus a Lesson Player. While functionally solid, the games lack the "juice" — the micro-interactions, persistent rewards, and character-driven delight — that make kids want to play again and again. Every tap should feel magical. Every correct answer should feel like a celebration. Every session should end with something to show for it.

## User Stories

### User Story 1 - Micro-Interaction Juice (Priority: P1, MVP)

Every interaction in every game feels satisfying and responsive. Letter tiles squash and stretch when tapped. Drag operations leave particle trails. Correct answers trigger bouncy, exaggerated animations. Drop zones "snap" with satisfying feedback. The app feels alive and tactile.

**Why this priority**: This is the foundation of delight — if individual interactions don't feel good, no reward system will compensate. Kids decide in milliseconds whether something is fun.

**Independent Test**: Play any game and verify every tap, drag, correct answer, and incorrect answer has visually distinct, satisfying animated feedback that goes beyond the current color change + haptic.

**Acceptance Scenarios**:

1. **Given** a child taps a letter tile in Spelling/Word Builder, **When** the tap lands, **Then** the tile squashes down (0.9x height, 1.1x width) then bounces back with spring animation, plays a pop sound
2. **Given** a child drags a letter in Spelling game, **When** dragging, **Then** a subtle particle trail follows the letter, the letter scales up 1.2x and has a shadow
3. **Given** a child answers correctly in any game, **When** the answer is confirmed, **Then** the correct element does a celebratory bounce (scale 1.3x → 1.0x with overshoot spring), stars burst outward from the element, and the score counter does a bump animation
4. **Given** a child answers incorrectly, **When** the wrong answer is shown, **Then** the element does a gentle wobble (not scary shake), with an encouraging "try again" animation (not punitive)
5. **Given** a letter is dropped into a drop zone in Spelling, **When** it snaps into place, **Then** it does a satisfying snap animation with a subtle pulse ring expanding outward
6. **Given** a card is flipped in Memory Match, **When** the flip completes, **Then** the card has a 3D flip with slight overshoot bounce at the end, with a sparkle effect on reveal
7. **Given** a child taps any button in any game, **When** the tap lands, **Then** the button does a micro-press animation (scale 0.95x) before executing its action

---

### User Story 2 - Animated Mascot Character (Priority: P1)

A friendly animated character (mascot) appears in games and reacts to the child's performance. The mascot celebrates correct answers, looks encouraging on mistakes, dances on streaks, and provides gentle hints when the child is stuck. The mascot creates emotional connection and makes the app feel like a companion.

**Why this priority**: Young children learn best with social-emotional connection. A mascot transforms a "tool" into a "friend" and dramatically increases engagement and return rate.

**Independent Test**: Play a full game session and verify the mascot appears, reacts appropriately to correct/incorrect answers, celebrates streaks, and offers hints after inactivity.

**Acceptance Scenarios**:

1. **Given** a child answers correctly, **When** the correct animation plays, **Then** the mascot does a happy dance/jump animation with a speech bubble ("Yay!", "Amazing!", random encouragement)
2. **Given** a child answers incorrectly, **When** the incorrect feedback shows, **Then** the mascot shows an encouraging expression (NOT sad/disappointed — supportive: thinking pose, "You can do it!" bubble)
3. **Given** a child gets a 3+ streak, **When** the streak milestone triggers, **Then** the mascot does an exaggerated celebration (confetti + mascot dance + larger speech bubble with "You're on fire!" style message)
4. **Given** a child hasn't interacted for 8+ seconds, **When** the inactivity timer fires, **Then** the mascot gently waves/bounces to re-engage, and after 15s shows a contextual hint (e.g., "Try tapping a letter!" with arrow pointing to letter bank)
5. **Given** the child completes a game session, **When** the results screen shows, **Then** the mascot appears large with a proud celebration animation

---

### User Story 3 - Per-Game UX Improvements (Priority: P2)

Each game gets targeted improvements to its unique mechanics, making it more intuitive and fun for its specific interaction pattern.

**Why this priority**: After the foundation (juice + mascot), each game needs its own personality and polish.

**Independent Test**: Play each game and verify its specific improvements are present and enhance the experience.

**Acceptance Scenarios**:

1. **Spelling Game**: **Given** a child builds a word correctly, **When** the last letter snaps in, **Then** the completed word does a rainbow shimmer animation and the emoji hint "comes alive" (bounces/sparkles). **Given** a child is stuck for 10s, **When** the hint timer fires, **Then** the next correct letter gently pulses in the letter bank.
2. **Memory Match**: **Given** it's the child's first play of a level, **When** the cards are dealt, **Then** all cards briefly peek (show face for 2s then flip back) to help the child. **Given** a child finds a match quickly (< 2s between flips), **Then** a "Speed Match!" bonus celebration plays with extra points.
3. **Phonics**: **Given** a sound option is shown, **When** the child taps it, **Then** the sound is spoken aloud with a subtle sound wave visualization rippling from the option card.
4. **Rhyme Time**: **Given** the target word is displayed, **When** the round starts, **Then** the word bounces in rhythmically (like it's being spoken in rhythm). Option words that rhyme subtly bounce in sync.
5. **Word Builder**: **Given** the child completes a word, **When** the last letter is placed, **Then** the emoji hint transforms into a mini-animation (e.g., the cat emoji meows, the sun emoji shines/rotates).
6. **Read Aloud**: **Given** the child is recording, **When** audio levels are detected, **Then** a more engaging waveform visualization plays (colorful bouncing bars instead of a ring). Practice mode: child can hear word, attempt, hear again without scoring.

---

### User Story 4 - Persistent Reward System (Priority: P2)

Children earn collectible rewards (stars, stickers) for game achievements. A trophy room/sticker book accessible from the home screen lets kids browse and admire their collection. Rewards persist across sessions and create long-term motivation.

**Why this priority**: Persistent rewards create the "come back tomorrow" loop. Kids love collecting things and showing them off.

**Independent Test**: Complete several game sessions, earn rewards, navigate to trophy room, and verify collection is displayed and persists across app launches.

**Acceptance Scenarios**:

1. **Given** a child completes any game session, **When** the results screen shows, **Then** a new sticker/star is awarded with a "New reward!" celebration animation. The sticker visually flies from the game to a sticker-book icon.
2. **Given** a child earns a perfect score (all correct), **When** the game ends, **Then** a special golden sticker is awarded (rarer, more exciting celebration)
3. **Given** a child opens the trophy room from the home screen, **When** the view loads, **Then** a colorful sticker book with categories per game shows earned stickers (colorful) and unearned slots (grey silhouettes)
4. **Given** a child has earned stickers, **When** they tap a sticker in the trophy room, **Then** the sticker does a pop-up animation with the date earned and which game it came from
5. **Given** a child completes a streak of 5 consecutive days, **When** they open the app on day 5, **Then** a special "Super Reader!" badge is awarded with extra fanfare

---

### User Story 5 - Celebration & Transition Polish (Priority: P3)

Level-up ceremonies, between-round transitions, and session-complete animations are upgraded with dancing characters, personalization (child's name), and smooth transitions that make the entire flow feel premium.

**Why this priority**: Polish layer that builds on all previous stories. Makes the app feel complete and high-quality.

**Independent Test**: Play through a complete game session and verify transitions between rounds are smooth and animated, and the completion ceremony uses the child's name and feels special.

**Acceptance Scenarios**:

1. **Given** a child finishes a round, **When** transitioning to the next round, **Then** a smooth animated transition plays (not just a state swap) — the old content slides/fades out, a brief "Round 3!" counter bumps in, and new content slides in
2. **Given** a child completes a game session, **When** the completion screen appears, **Then** the child's name is used ("Amazing job, [Name]!"), the mascot dances, confetti rains, earned sticker flies in, and the star rating animates filling up
3. **Given** a child achieves a new personal best (highest score/lowest moves), **When** the results show, **Then** a "New Record!" badge animates in with special fanfare sound
4. **Given** a child levels up in difficulty, **When** the next level unlocks, **Then** a "Level Up!" ceremony plays with the mascot, rising stars animation, and preview of the next challenge

---

### Edge Cases

- What happens if the child rapidly taps during an animation? → Animations should queue, not overlap or cancel. Input during celebrations should be buffered.
- What happens on older/slower devices? → Animations must degrade gracefully. Reduce particle count, skip shadows. Never drop frames on core interactions.
- What happens if VoiceOver is active? → Mascot speech bubbles become VoiceOver announcements. Animation descriptions added as accessibility labels.
- What happens if reduce motion is enabled? → All new animations respect `accessibilityReduceMotion`. Mascot shows static poses instead of animated reactions. Celebrations use simple fades instead of bounces.

## Requirements

### Functional Requirements

- **FR-001**: Every interactive element in all 6 games MUST have micro-animation feedback (tap, drag, correct, incorrect)
- **FR-002**: Animated mascot MUST appear in all 6 games with context-appropriate reactions
- **FR-003**: Trophy room / sticker book MUST persist rewards across app launches via local storage
- **FR-004**: All new animations MUST respect `accessibilityReduceMotion`
- **FR-005**: All new animations MUST maintain 60fps on iPhone 12 and later
- **FR-006**: Mascot hint system MUST activate after 8s inactivity with contextual guidance
- **FR-007**: Between-round transitions MUST be animated (not instant state swaps)
- **FR-008**: Child's name MUST be used in completion celebrations

### Key Entities

- **Sticker**: Reward collectible earned from game completion. Has type (normal/golden/special), game source, date earned, and display image.
- **StickerBook**: Collection of earned stickers organized by game category. Persisted in local storage.
- **MascotState**: Current mascot animation state (idle, celebrating, encouraging, hinting, dancing). Driven by game events.
- **AnimationConfig**: Per-element animation parameters (spring response, damping, scale factors). Centralised for consistency.

## Success Criteria

- **SC-001**: Every tap/drag/selection in all 6 games has visible animated feedback (zero "dead" interactions)
- **SC-002**: Mascot reacts within 300ms of game events (correct/incorrect/streak)
- **SC-003**: Children earn at least 1 reward per game session
- **SC-004**: Trophy room shows all earned rewards with correct game attribution
- **SC-005**: All animations maintain 60fps on target devices (iPhone 12+)
- **SC-006**: Accessibility: all features work with VoiceOver and reduce-motion enabled
