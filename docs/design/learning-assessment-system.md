# Learning Style & Progress Assessment System Design

## Overview

A gamified, engaging assessment experience that helps parents share information about their child's personality, learning preferences, current reading level, and interests. The system frames assessment as "discovery" rather than "testing" to reduce pressure and increase engagement.

---

## 1. Assessment Methodology

### Core Philosophy

- **Discovery, not Testing**: Frame everything as "learning about your unique learner"
- **Low Pressure**: No right/wrong answers for learning style questions
- **Parent-Guided**: Parents answer about their child (not child self-reporting)
- **Gamified Progress**: Visual progress, celebrations, and friendly mascot
- **Modular Design**: Sections can be completed in any order, saved mid-way

### Assessment Sections

| Section | Duration | Purpose | Gamification |
|---------|----------|---------|--------------|
| 1. Child Profile | 2 min | Name, age, avatar | Avatar builder game |
| 2. Personality Discovery | 3-4 min | How child learns best | Scenario cards |
| 3. Learning Style Quiz | 4-5 min | VAK preferences | "Superpower" discovery |
| 4. Letter Recognition | 3-5 min | Current letter knowledge | Interactive letter hunt |
| 5. Reading Assessment | 5-7 min | Word/sentence level | Story-based challenges |
| 6. Interest Explorer | 2-3 min | Topics for personalization | Visual category picker |

**Total: 20-26 minutes** (can pause/resume)

---

## 2. Detailed Section Design

### Section 1: Child Profile Setup

**UX Pattern**: Avatar builder game

**Flow**:
1. "Let's create your learner's profile!"
2. Enter child's name (with playful keyboard)
3. Select age (3-8 years, visual number bubbles)
4. Build avatar (hair, skin tone, accessories, outfit)
5. Preview: "Meet [Name]!" with animated avatar

**Data Collected**:
- `childName`: string
- `dateOfBirth`: Date (or age in years)
- `avatarConfig`: AvatarConfiguration

---

### Section 2: Personality Discovery

**UX Pattern**: Scenario cards with illustrated situations

**Question Format**: "When [situation], [Name] usually..."

**Sample Questions** (12 total, show 8 randomly):

1. **Learning new things**
   - Situation: "[Name] is learning something new"
   - Options:
     - Watches carefully first, then tries
     - Jumps right in and figures it out
     - Asks lots of questions before starting
     - Needs encouragement to begin

2. **Problem solving**
   - Situation: "A puzzle piece won't fit"
   - Options:
     - Keeps trying different ways quietly
     - Gets frustrated, needs help calming
     - Asks for hints or help
     - Moves to something else, comes back later

3. **Social learning**
   - Situation: "Learning with other kids"
   - Options:
     - Loves it, learns from watching others
     - Prefers learning alone
     - Enjoys taking turns
     - Gets distracted by others

4. **Attention span**
   - Situation: "During a favorite activity"
   - Options:
     - Can focus for 15+ minutes
     - Needs short breaks every 5-10 minutes
     - Focus varies a lot day to day
     - Best with very short activities (under 5 min)

5. **Motivation style**
   - Situation: "What motivates [Name] most?"
   - Options:
     - Praise and encouragement
     - Seeing their own progress
     - Fun games and rewards
     - Helping others

**Personality Dimensions Assessed**:
- Approach to learning (cautious ↔ adventurous)
- Persistence level
- Social preference (solo ↔ group)
- Attention capacity
- Motivation type

---

### Section 3: Learning Style Quiz (VAK Assessment)

**UX Pattern**: "Superpower Discovery" - finding their learning superpower

**Framework**: Visual-Auditory-Kinesthetic (VAK) model adapted for young children

**Question Design**: Each question maps to V, A, or K preference

**Sample Questions** (15 total):

1. **Remembering a new word**
   - "How does [Name] best remember a new word?"
   - 👁️ Seeing it written or in pictures (V)
   - 👂 Hearing it said out loud (A)
   - ✋ Acting it out or touching something related (K)

2. **Following instructions**
   - "When learning something new, [Name] does best with..."
   - 👁️ Pictures or demonstrations (V)
   - 👂 Spoken explanations (A)
   - ✋ Hands-on practice (K)

3. **Story engagement**
   - "During story time, [Name] enjoys most..."
   - 👁️ Looking at the pictures (V)
   - 👂 Listening to voices and sounds (A)
   - ✋ Touching the book, turning pages (K)

4. **Expressing ideas**
   - "[Name] usually expresses themselves by..."
   - 👁️ Drawing or showing (V)
   - 👂 Talking or making sounds (A)
   - ✋ Acting out or demonstrating (K)

5. **Getting excited about**
   - "[Name] gets most excited about..."
   - 👁️ Colorful pictures and videos (V)
   - 👂 Songs, rhymes, and funny voices (A)
   - ✋ Building, moving, and touching (K)

**Scoring**:
- Count responses per modality
- Primary style: highest count
- Secondary style: second highest
- Learning profile: e.g., "Visual-Kinesthetic Learner"

**Result Presentation**:
- "🌟 [Name]'s Learning Superpowers!"
- Primary: "Super Seer" (V) / "Super Listener" (A) / "Super Mover" (K)
- Visual badge/icon for profile
- Brief parent-friendly explanation

---

### Section 4: Letter Recognition Assessment

**UX Pattern**: Interactive letter hunt game

**Adaptive Design**: Difficulty adjusts based on responses

**Levels**:

**Level 1: Letter Identification**
- Show 4-6 letters, ask "Find the letter [X]"
- Track: correct/incorrect, response time
- Cover: all 26 letters (uppercase first, then lowercase)

**Level 2: Letter Sounds**
- Play a sound, ask "Which letter makes this sound?"
- Focus on common phonemes
- Track: phonemic awareness

**Level 3: Letter-Sound Matching**
- Show letter, play 3 sounds, pick the match
- Assesses phonics readiness

**Adaptive Logic**:
```
If correct >= 80% on Level 1 → proceed to Level 2
If correct < 50% on Level 1 → simplified assessment
If correct >= 70% on Level 2 → proceed to Level 3
```

**Gamification**:
- Letters "collected" into a treasure chest
- Stars for correct answers
- Encouraging feedback for wrong answers ("Good try! That's the letter [Y]")
- No visible "wrong" counter

**Data Collected**:
- Letters recognized (uppercase): boolean[26]
- Letters recognized (lowercase): boolean[26]
- Letter-sound associations: Map<letter, boolean>
- Overall letter recognition score: percentage
- Estimated letter stage: "learning" | "emerging" | "confident"

---

### Section 5: Reading Level Assessment

**UX Pattern**: Story-based mini-adventures

**Adaptive Levels**:

**Pre-Reader Assessment**:
- Word recognition: Show 3 pictures, hear word, match
- Print awareness: "Show me where to start reading"
- Concept of word: Count words in a short sentence

**Emerging Reader Assessment**:
- CVC words: cat, dog, sun, hat, etc.
- High-frequency words: the, and, is, it, a, to
- Simple sentences: "The cat sat."

**Early Reader Assessment**:
- CVCC/CCVC words: jump, stop, from
- Blends and digraphs: sh, ch, th, bl, st
- Short passages (2-3 sentences)

**Adaptive Flow**:
```
Start at Pre-Reader
If score >= 80% → move up one level
If score < 40% → stay and simplify
Continue until ceiling reached (< 60% at level)
```

**Question Types**:
1. **Word Recognition**: "Touch the word 'cat'" (show 3 words)
2. **Picture-Word Match**: Show word, pick matching picture
3. **Sentence Reading**: Read sentence, answer comprehension question
4. **Missing Word**: "The dog can ___" (run/blue/the)

**Gamification**:
- Each level is a "chapter" in an adventure
- Friendly animal guide gives hints
- Treasure/stars collected
- "You discovered [X] words!"

**Data Collected**:
- Reading level: "pre-reader" | "emerging" | "early" | "developing"
- CVC word accuracy: percentage
- High-frequency word recognition: string[]
- Comprehension indicator: basic assessment
- Estimated reading stage with substage

---

### Section 6: Interest Explorer

**UX Pattern**: Visual category picker with tap-to-select

**Categories** (tap all that apply):

**Animals & Nature**:
- 🐕 Dogs & Cats
- 🦁 Wild Animals
- 🦕 Dinosaurs
- 🐛 Bugs & Insects
- 🌊 Ocean Animals
- 🌸 Plants & Flowers

**Vehicles & Machines**:
- 🚗 Cars & Trucks
- 🚂 Trains
- ✈️ Planes
- 🚀 Space & Rockets
- 🏗️ Construction
- 🤖 Robots

**People & Stories**:
- 👸 Princesses & Princes
- 🦸 Superheroes
- 🧙 Magic & Wizards
- 👨‍👩‍👧 Family & Friends
- 🏥 Helpers (doctors, firefighters)

**Activities**:
- ⚽ Sports & Games
- 🎨 Art & Crafts
- 🎵 Music & Dancing
- 🍳 Cooking & Food
- 🏰 Building & Creating

**Other Interests** (free text optional):
- Parent can add specific interests

**Data Collected**:
- `selectedInterests`: string[] (category IDs)
- `customInterests`: string[] (free text)
- Interest intensity (if tapped multiple times = stronger interest)

---

## 3. Data Model

### TypeScript Interfaces

```typescript
// ============================================
// Core Types
// ============================================

type LearningStyle = 'visual' | 'auditory' | 'kinesthetic';
type ReadingLevel = 'pre-reader' | 'emerging' | 'early' | 'developing';
type LetterStage = 'learning' | 'emerging' | 'confident';
type AssessmentStatus = 'not_started' | 'in_progress' | 'completed';

// ============================================
// Child Profile
// ============================================

interface AvatarConfiguration {
  skinTone: string;          // hex color or preset ID
  hairStyle: string;         // preset ID
  hairColor: string;         // hex color or preset ID
  accessories: string[];     // preset IDs
  outfit: string;            // preset ID
}

interface ChildProfile {
  id: string;                // UUID
  parentId: string;          // UUID - link to parent account
  name: string;
  dateOfBirth: Date;
  avatarConfig: AvatarConfiguration;
  createdAt: Date;
  updatedAt: Date;
}

// ============================================
// Personality Assessment
// ============================================

interface PersonalityQuestion {
  id: string;
  situationText: string;     // "When learning something new..."
  options: PersonalityOption[];
  dimension: PersonalityDimension;
}

interface PersonalityOption {
  id: string;
  text: string;
  dimensionValue: string;    // e.g., "cautious", "adventurous"
}

type PersonalityDimension =
  | 'learning_approach'      // cautious ↔ adventurous
  | 'persistence'            // gives_up_easily ↔ highly_persistent
  | 'social_preference'      // solo ↔ group
  | 'attention_capacity'     // short ↔ extended
  | 'motivation_type';       // external ↔ internal

interface PersonalityResponse {
  questionId: string;
  selectedOptionId: string;
  timestamp: Date;
}

interface PersonalityProfile {
  learningApproach: number;  // -1 to 1 (cautious to adventurous)
  persistence: number;       // -1 to 1
  socialPreference: number;  // -1 to 1 (solo to group)
  attentionCapacity: number; // -1 to 1 (short to extended)
  motivationType: number;    // -1 to 1 (external to internal)
}

// ============================================
// Learning Style Assessment (VAK)
// ============================================

interface LearningStyleQuestion {
  id: string;
  questionText: string;
  context: string;           // Scenario description
  options: LearningStyleOption[];
}

interface LearningStyleOption {
  id: string;
  text: string;
  icon: string;              // emoji or icon ID
  modality: LearningStyle;   // 'visual' | 'auditory' | 'kinesthetic'
}

interface LearningStyleResponse {
  questionId: string;
  selectedOptionId: string;
  modality: LearningStyle;
  timestamp: Date;
}

interface LearningStyleProfile {
  visual: number;            // 0-100 percentage
  auditory: number;          // 0-100 percentage
  kinesthetic: number;       // 0-100 percentage
  primaryStyle: LearningStyle;
  secondaryStyle: LearningStyle | null;
  profileLabel: string;      // e.g., "Visual-Kinesthetic Learner"
}

// ============================================
// Letter Recognition Assessment
// ============================================

interface LetterAssessmentItem {
  letter: string;            // 'A', 'a', etc.
  case: 'upper' | 'lower';
  recognized: boolean;
  responseTimeMs: number;
  attemptedAt: Date;
}

interface LetterSoundItem {
  letter: string;
  soundRecognized: boolean;
  responseTimeMs: number;
  attemptedAt: Date;
}

interface LetterRecognitionProfile {
  uppercaseRecognized: string[];   // ['A', 'B', 'C', ...]
  uppercaseNotRecognized: string[];
  lowercaseRecognized: string[];
  lowercaseNotRecognized: string[];
  letterSoundAssociations: Map<string, boolean>;
  overallScore: number;            // 0-100 percentage
  stage: LetterStage;
  assessedAt: Date;
}

// ============================================
// Reading Level Assessment
// ============================================

interface ReadingAssessmentItem {
  id: string;
  type: 'word_recognition' | 'picture_match' | 'sentence_reading' | 'missing_word';
  level: ReadingLevel;
  prompt: string;
  correctAnswer: string;
  userAnswer: string;
  isCorrect: boolean;
  responseTimeMs: number;
  attemptedAt: Date;
}

interface ReadingProfile {
  level: ReadingLevel;
  subLevel: number;                // 1-3 within each level
  cvcWordAccuracy: number;         // 0-100
  highFrequencyWords: string[];    // words recognized
  comprehensionScore: number;      // 0-100
  assessedAt: Date;
  detailedResults: ReadingAssessmentItem[];
}

// ============================================
// Interest Profile
// ============================================

interface InterestCategory {
  id: string;
  name: string;
  icon: string;
  parentCategory: string | null;
}

interface InterestProfile {
  selectedCategories: string[];    // category IDs
  customInterests: string[];       // free text entries
  interestStrength: Map<string, number>; // categoryId → strength (1-3)
  assessedAt: Date;
}

// ============================================
// Complete Assessment
// ============================================

interface AssessmentSession {
  id: string;                      // UUID
  childId: string;                 // UUID
  status: AssessmentStatus;
  startedAt: Date;
  completedAt: Date | null;
  lastActivityAt: Date;

  // Section completion tracking
  sectionsCompleted: {
    profile: boolean;
    personality: boolean;
    learningStyle: boolean;
    letterRecognition: boolean;
    readingLevel: boolean;
    interests: boolean;
  };

  // Progress percentage
  progressPercent: number;
}

interface ChildAssessmentResult {
  id: string;                      // UUID
  childId: string;                 // UUID
  sessionId: string;               // UUID
  completedAt: Date;

  // All profiles
  personalityProfile: PersonalityProfile;
  learningStyleProfile: LearningStyleProfile;
  letterRecognitionProfile: LetterRecognitionProfile;
  readingProfile: ReadingProfile;
  interestProfile: InterestProfile;

  // Raw response data (for re-analysis)
  rawResponses: {
    personality: PersonalityResponse[];
    learningStyle: LearningStyleResponse[];
    letterRecognition: LetterAssessmentItem[];
    reading: ReadingAssessmentItem[];
  };

  // Generated recommendations
  recommendations: LearningRecommendations;
}

// ============================================
// Recommendations Engine Output
// ============================================

interface LearningRecommendations {
  // Personalized lesson approach
  preferredModalities: LearningStyle[];
  sessionDuration: number;         // recommended minutes
  breakFrequency: number;          // minutes between breaks

  // Content recommendations
  startingLetters: string[];       // letters to focus on first
  startingWords: string[];         // words to introduce
  contentThemes: string[];         // interest-based themes

  // Engagement strategies
  motivationStrategies: string[];
  socialSetting: 'individual' | 'with_parent' | 'with_siblings';

  // Gamification preferences
  rewardStyle: 'praise' | 'progress' | 'rewards' | 'helping';
}
```

### Database Schema (Future PostgreSQL)

```sql
-- Parents/Users
CREATE TABLE parents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(255),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Children
CREATE TABLE children (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  parent_id UUID REFERENCES parents(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  date_of_birth DATE,
  avatar_config JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Assessment Sessions
CREATE TABLE assessment_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  child_id UUID REFERENCES children(id) ON DELETE CASCADE,
  status VARCHAR(50) DEFAULT 'not_started',
  sections_completed JSONB DEFAULT '{}',
  progress_percent INTEGER DEFAULT 0,
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  last_activity_at TIMESTAMPTZ DEFAULT NOW()
);

-- Assessment Results (final computed profiles)
CREATE TABLE assessment_results (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  child_id UUID REFERENCES children(id) ON DELETE CASCADE,
  session_id UUID REFERENCES assessment_sessions(id),
  personality_profile JSONB,
  learning_style_profile JSONB,
  letter_recognition_profile JSONB,
  reading_profile JSONB,
  interest_profile JSONB,
  recommendations JSONB,
  completed_at TIMESTAMPTZ DEFAULT NOW()
);

-- Raw Responses (for re-analysis and audit)
CREATE TABLE assessment_responses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID REFERENCES assessment_sessions(id) ON DELETE CASCADE,
  section VARCHAR(50) NOT NULL,
  question_id VARCHAR(100),
  response_data JSONB NOT NULL,
  response_time_ms INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_children_parent ON children(parent_id);
CREATE INDEX idx_sessions_child ON assessment_sessions(child_id);
CREATE INDEX idx_results_child ON assessment_results(child_id);
CREATE INDEX idx_responses_session ON assessment_responses(session_id);
```

---

## 4. Wireframes

### Screen Flow Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                      ASSESSMENT FLOW                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  [Welcome] → [Profile] → [Personality] → [Learning Style]       │
│                              ↓                                   │
│            [Complete!] ← [Interests] ← [Reading] ← [Letters]    │
│                                                                  │
│  User can pause/resume at any section boundary                  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Wireframe 1: Welcome Screen

```
┌────────────────────────────────────────┐
│  ←                              ⋮      │
├────────────────────────────────────────┤
│                                        │
│         🌟 ✨ 🌟                       │
│                                        │
│     Let's Discover Your               │
│     Learner's Superpowers!            │
│                                        │
│   ┌────────────────────────────────┐  │
│   │                                │  │
│   │    [Friendly mascot image]    │  │
│   │         waving hello          │  │
│   │                                │  │
│   └────────────────────────────────┘  │
│                                        │
│   This quick adventure helps us       │
│   understand how your child learns    │
│   best so we can personalize their   │
│   reading journey.                    │
│                                        │
│   ⏱️ About 20 minutes                 │
│   💾 Save anytime and continue later  │
│                                        │
│   ┌────────────────────────────────┐  │
│   │     🚀 Start Adventure         │  │
│   └────────────────────────────────┘  │
│                                        │
│   Already started? [Continue →]       │
│                                        │
└────────────────────────────────────────┘
```

### Wireframe 2: Progress Header (All Screens)

```
┌────────────────────────────────────────┐
│  ←  Profile Setup              45%    │
├────────────────────────────────────────┤
│  [███████████░░░░░░░░░░░░░░]          │
│   1    2    3    4    5    6          │
│   ●────●────○────○────○────○          │
│   ✓   Now                             │
└────────────────────────────────────────┘
```

### Wireframe 3: Avatar Builder

```
┌────────────────────────────────────────┐
│  ←  Create [Name]'s Avatar     20%    │
├────────────────────────────────────────┤
│                                        │
│        ┌──────────────────┐           │
│        │                  │           │
│        │   [Live Avatar   │           │
│        │    Preview]      │           │
│        │                  │           │
│        └──────────────────┘           │
│                                        │
│   Skin Tone                           │
│   ○ ○ ○ ○ ○ ○ ○                       │
│                                        │
│   Hair Style                          │
│   ┌───┐ ┌───┐ ┌───┐ ┌───┐ ┌───┐      │
│   │ 1 │ │ 2 │ │ 3 │ │ 4 │ │ 5 │  →   │
│   └───┘ └───┘ └───┘ └───┘ └───┘      │
│                                        │
│   Hair Color                          │
│   ○ ○ ○ ○ ○ ○ ○                       │
│                                        │
│   Accessories                         │
│   ┌───┐ ┌───┐ ┌───┐ ┌───┐            │
│   │👓 │ │🎀 │ │🧢 │ │✨ │  ...        │
│   └───┘ └───┘ └───┘ └───┘            │
│                                        │
│   ┌────────────────────────────────┐  │
│   │          Next →                │  │
│   └────────────────────────────────┘  │
│                                        │
└────────────────────────────────────────┘
```

### Wireframe 4: Personality Question (Scenario Card)

```
┌────────────────────────────────────────┐
│  ←  Personality Discovery      35%    │
├────────────────────────────────────────┤
│                                        │
│   Question 3 of 8                     │
│                                        │
│   ┌────────────────────────────────┐  │
│   │  ┌──────────────────────────┐ │  │
│   │  │   [Illustration of       │ │  │
│   │  │    child with puzzle]    │ │  │
│   │  └──────────────────────────┘ │  │
│   │                                │  │
│   │  When a puzzle piece won't    │  │
│   │  fit, Emma usually...         │  │
│   └────────────────────────────────┘  │
│                                        │
│   ┌────────────────────────────────┐  │
│   │ ○  Keeps trying different     │  │
│   │    ways quietly               │  │
│   └────────────────────────────────┘  │
│                                        │
│   ┌────────────────────────────────┐  │
│   │ ○  Gets frustrated, needs     │  │
│   │    help calming down          │  │
│   └────────────────────────────────┘  │
│                                        │
│   ┌────────────────────────────────┐  │
│   │ ○  Asks for hints or help     │  │
│   └────────────────────────────────┘  │
│                                        │
│   ┌────────────────────────────────┐  │
│   │ ○  Moves to something else,   │  │
│   │    comes back later           │  │
│   └────────────────────────────────┘  │
│                                        │
└────────────────────────────────────────┘
```

### Wireframe 5: Learning Style Question

```
┌────────────────────────────────────────┐
│  ←  Superpower Discovery       50%    │
├────────────────────────────────────────┤
│                                        │
│         🦸 Finding Emma's             │
│         Learning Superpowers!         │
│                                        │
│   ┌────────────────────────────────┐  │
│   │  How does Emma best remember   │  │
│   │  a new word?                   │  │
│   └────────────────────────────────┘  │
│                                        │
│   ┌────────────────────────────────┐  │
│   │  👁️                            │  │
│   │  Seeing it written             │  │
│   │  or in pictures                │  │
│   └────────────────────────────────┘  │
│                                        │
│   ┌────────────────────────────────┐  │
│   │  👂                            │  │
│   │  Hearing it said               │  │
│   │  out loud                      │  │
│   └────────────────────────────────┘  │
│                                        │
│   ┌────────────────────────────────┐  │
│   │  ✋                            │  │
│   │  Acting it out or              │  │
│   │  touching something            │  │
│   └────────────────────────────────┘  │
│                                        │
└────────────────────────────────────────┘
```

### Wireframe 6: Letter Hunt Game

```
┌────────────────────────────────────────┐
│  ←  Letter Hunt!               65%    │
├────────────────────────────────────────┤
│                                        │
│   🏆 Letters Found: 12/26             │
│   ⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐              │
│                                        │
│         🔊 "Find the letter B!"       │
│                                        │
│   ┌────────────────────────────────┐  │
│   │                                │  │
│   │    ┌───┐    ┌───┐    ┌───┐    │  │
│   │    │   │    │   │    │   │    │  │
│   │    │ A │    │ B │    │ D │    │  │
│   │    │   │    │   │    │   │    │  │
│   │    └───┘    └───┘    └───┘    │  │
│   │                                │  │
│   │    ┌───┐    ┌───┐    ┌───┐    │  │
│   │    │   │    │   │    │   │    │  │
│   │    │ P │    │ R │    │ E │    │  │
│   │    │   │    │   │    │   │    │  │
│   │    └───┘    └───┘    └───┘    │  │
│   │                                │  │
│   └────────────────────────────────┘  │
│                                        │
│   [🔊 Hear Again]                     │
│                                        │
│   💡 Tap the letter you hear!         │
│                                        │
└────────────────────────────────────────┘
```

### Wireframe 7: Reading Challenge

```
┌────────────────────────────────────────┐
│  ←  Story Adventure            80%    │
├────────────────────────────────────────┤
│                                        │
│   📖 Chapter 2: Word Explorer         │
│                                        │
│   ┌────────────────────────────────┐  │
│   │  ┌──────────────────────────┐ │  │
│   │  │   [Picture of a cat     │ │  │
│   │  │    sitting on a mat]    │ │  │
│   │  └──────────────────────────┘ │  │
│   │                                │  │
│   │      The cat sat on the       │  │
│   │           _____.              │  │
│   │                                │  │
│   └────────────────────────────────┘  │
│                                        │
│   Which word completes the story?     │
│                                        │
│   ┌──────────┐  ┌──────────┐         │
│   │   mat    │  │   the    │         │
│   └──────────┘  └──────────┘         │
│                                        │
│   ┌──────────┐  ┌──────────┐         │
│   │   blue   │  │   cat    │         │
│   └──────────┘  └──────────┘         │
│                                        │
│                                        │
└────────────────────────────────────────┘
```

### Wireframe 8: Interest Picker

```
┌────────────────────────────────────────┐
│  ←  Interest Explorer          90%    │
├────────────────────────────────────────┤
│                                        │
│   What does Emma love? Tap all        │
│   that apply!                         │
│                                        │
│   Animals & Nature                    │
│   ┌────┐ ┌────┐ ┌────┐ ┌────┐        │
│   │ 🐕 │ │ 🦁 │ │ 🦕 │ │ 🐛 │        │
│   │Dogs│ │Wild│ │Dino│ │Bugs│        │
│   │ ✓  │ │    │ │ ✓  │ │    │        │
│   └────┘ └────┘ └────┘ └────┘        │
│                                        │
│   Vehicles & Machines                 │
│   ┌────┐ ┌────┐ ┌────┐ ┌────┐        │
│   │ 🚗 │ │ 🚂 │ │ ✈️ │ │ 🚀 │        │
│   │Cars│ │Tran│ │Plan│ │Spac│        │
│   │    │ │    │ │    │ │ ✓  │        │
│   └────┘ └────┘ └────┘ └────┘        │
│                                        │
│   Stories & Characters                │
│   ┌────┐ ┌────┐ ┌────┐ ┌────┐        │
│   │ 👸 │ │ 🦸 │ │ 🧙 │ │ 🏥 │        │
│   │Princ│ │Hero│ │Magi│ │Help│        │
│   │ ✓  │ │ ✓  │ │    │ │    │        │
│   └────┘ └────┘ └────┘ └────┘        │
│                                        │
│   ┌────────────────────────────────┐  │
│   │     See Emma's Profile! →      │  │
│   └────────────────────────────────┘  │
│                                        │
└────────────────────────────────────────┘
```

### Wireframe 9: Results Summary

```
┌────────────────────────────────────────┐
│                              ⋮        │
├────────────────────────────────────────┤
│                                        │
│   🎉 Emma's Learning Profile! 🎉      │
│                                        │
│   ┌────────────────────────────────┐  │
│   │        [Emma's Avatar]        │  │
│   │                                │  │
│   │     🌟 Visual Learner 🌟       │  │
│   │    with Kinesthetic Flair     │  │
│   └────────────────────────────────┘  │
│                                        │
│   Learning Superpowers                │
│   ┌────────────────────────────────┐  │
│   │ 👁️ Visual      ████████░░ 80%  │  │
│   │ ✋ Kinesthetic ██████░░░░ 60%  │  │
│   │ 👂 Auditory    ████░░░░░░ 40%  │  │
│   └────────────────────────────────┘  │
│                                        │
│   Letter Knowledge                    │
│   ┌────────────────────────────────┐  │
│   │ ✅ Knows 18/26 uppercase       │  │
│   │ 📚 Learning 12/26 lowercase    │  │
│   │ 🎯 Ready for: Letter sounds    │  │
│   └────────────────────────────────┘  │
│                                        │
│   Reading Level: Emerging Reader      │
│   ┌────────────────────────────────┐  │
│   │ [Pre] → [Emerging] → Early     │  │
│   │           ↑ You are here       │  │
│   └────────────────────────────────┘  │
│                                        │
│   Interests: 🦕🚀👸🦸🐕              │
│                                        │
│   ┌────────────────────────────────┐  │
│   │   Start Personalized Lessons   │  │
│   └────────────────────────────────┘  │
│                                        │
│   [See Detailed Report]               │
│                                        │
└────────────────────────────────────────┘
```

---

## 5. Implementation Plan

### Phase 1: Foundation (Sprint 1)

**Goal**: Core infrastructure and data layer

**Tasks**:
1. **Set up database** (if using PostgreSQL/SQLite)
   - Create schema migrations
   - Set up ORM (Prisma or Drizzle recommended)

2. **Create TypeScript types**
   - `src/types/assessment.ts` - All interfaces from data model
   - `src/types/child.ts` - Child profile types

3. **Build API routes**
   - `POST /api/children` - Create child profile
   - `GET /api/children/:id` - Get child profile
   - `POST /api/assessments` - Start assessment session
   - `PUT /api/assessments/:id` - Update assessment progress
   - `GET /api/assessments/:id/results` - Get assessment results

4. **Create base UI components**
   - `ProgressHeader` - Section progress indicator
   - `QuestionCard` - Base question display
   - `OptionButton` - Selectable option
   - `NavigationControls` - Back/Next buttons

### Phase 2: Profile & Personality (Sprint 2)

**Goal**: Child profile creation and personality assessment

**Tasks**:
1. **Avatar Builder**
   - Create avatar asset system (SVG parts)
   - Build `AvatarBuilder` component
   - Implement avatar preview

2. **Profile Form**
   - Name input with playful keyboard
   - Age selection (visual bubbles)
   - Save to backend

3. **Personality Questions**
   - Create question bank (12 questions)
   - Build scenario card component
   - Implement random question selection (8 of 12)
   - Calculate personality profile

### Phase 3: Learning Style Assessment (Sprint 3)

**Goal**: VAK assessment with superpower theming

**Tasks**:
1. **Question Bank**
   - Create 15 VAK questions with icons
   - Build question component with modality options

2. **Scoring Engine**
   - Calculate V/A/K percentages
   - Determine primary/secondary styles
   - Generate profile label

3. **Results Display**
   - "Superpower" reveal animation
   - Visual profile display

### Phase 4: Letter Recognition (Sprint 4)

**Goal**: Adaptive letter assessment game

**Tasks**:
1. **Letter Hunt Game**
   - Letter grid display component
   - Audio integration (letter sounds using ElevenLabs)
   - Touch/click detection with feedback

2. **Adaptive Engine**
   - Track correct/incorrect responses
   - Adjust difficulty based on performance
   - Move through levels (identify → sounds → matching)

3. **Progress Tracking**
   - Visual letter collection (treasure chest)
   - Star/reward animations

### Phase 5: Reading Assessment (Sprint 5)

**Goal**: Multi-level reading evaluation

**Tasks**:
1. **Assessment Levels**
   - Pre-reader activities (word matching, print awareness)
   - Emerging reader (CVC words, sight words)
   - Early reader (sentences, comprehension)

2. **Adaptive Flow**
   - Start at pre-reader
   - Advance or stay based on accuracy
   - Find ceiling level

3. **Story Integration**
   - Mini-adventure theme
   - Character guide with hints
   - Achievement celebrations

### Phase 6: Interests & Results (Sprint 6)

**Goal**: Interest capture and final results

**Tasks**:
1. **Interest Picker**
   - Visual category grid
   - Multi-select with tap feedback
   - Custom interest input

2. **Results Compilation**
   - Aggregate all section results
   - Generate learning recommendations
   - Store complete profile

3. **Results Display**
   - Summary dashboard
   - Detailed report view
   - Share/export options

### Phase 7: Polish & Testing (Sprint 7)

**Goal**: Production readiness

**Tasks**:
1. **UX Polish**
   - Animations and transitions
   - Loading states
   - Error handling

2. **Accessibility**
   - Screen reader support
   - Keyboard navigation
   - Color contrast verification

3. **Testing**
   - Unit tests for scoring engines
   - Integration tests for API
   - E2E tests for complete flow
   - Usability testing with parents

---

## 6. Technical Considerations

### State Management

Recommend using React Context + useReducer for assessment state:

```typescript
interface AssessmentState {
  session: AssessmentSession;
  currentSection: number;
  responses: Record<string, unknown>;
  isLoading: boolean;
  error: string | null;
}

type AssessmentAction =
  | { type: 'START_SESSION'; payload: AssessmentSession }
  | { type: 'RECORD_RESPONSE'; payload: { section: string; data: unknown } }
  | { type: 'NEXT_SECTION' }
  | { type: 'SAVE_PROGRESS' }
  | { type: 'COMPLETE_ASSESSMENT' };
```

### Audio Integration

Leverage existing ElevenLabs integration for:
- Letter sound pronunciation
- Question narration (optional)
- Celebration sounds
- Friendly mascot voice

### Offline Support (Future)

Consider IndexedDB for:
- Saving progress locally
- Offline assessment completion
- Sync when back online

### Analytics Events

Track for product insights:
- Section completion rates
- Drop-off points
- Time per section
- Question difficulty (by skip/retry rates)

---

## 7. Success Metrics

| Metric | Target |
|--------|--------|
| Assessment completion rate | > 80% |
| Average completion time | 20-25 minutes |
| Parent satisfaction score | > 4.5/5 |
| Assessment accuracy (vs expert) | > 85% |
| Return rate for re-assessment | > 60% at 3 months |

---

## Appendix A: Sample Question Banks

### Personality Questions (Full Set)

See separate file: `docs/content/personality-questions.json`

### VAK Questions (Full Set)

See separate file: `docs/content/vak-questions.json`

### Letter Recognition Items

Standard 26 uppercase + 26 lowercase, organized by:
- High frequency first: E, T, A, O, I, N, S, R, H, L
- Child's name letters prioritized
- Visually similar letters grouped for differentiation

### Reading Assessment Word Lists

See separate file: `docs/content/reading-word-lists.json`
- CVC words (100 words, graded)
- High-frequency words (Dolch list, graded)
- Decodable sentences (50 sentences, graded)
