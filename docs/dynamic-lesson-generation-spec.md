# L2RR2L Dynamic Lesson Generation System

## Technical Specification & Educational Framework

**Version:** 1.0
**Date:** January 2026
**Status:** Research & Planning Complete

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Educational Framework](#2-educational-framework)
3. [System Architecture](#3-system-architecture)
4. [Data Models](#4-data-models)
5. [Lesson Structure Templates](#5-lesson-structure-templates)
6. [Progression Paths](#6-progression-paths)
7. [Adaptive Difficulty Algorithm](#7-adaptive-difficulty-algorithm)
8. [Integration Points](#8-integration-points)
9. [Implementation Roadmap](#9-implementation-roadmap)

---

## 1. Executive Summary

### 1.1 Purpose

This specification defines a dynamic lesson generation system for L2RR2L (Learn to Read, Read to Learn), an early childhood reading education application targeting children ages 4-6. The system generates personalized lesson plans on-the-fly based on each child's current level, learning style, interests, and progress.

### 1.2 Key Design Principles

- **Science of Reading Aligned**: Based on decades of cognitive science research
- **Structured Literacy Approach**: Systematic, cumulative, explicit, and diagnostic
- **Adaptive & Personalized**: Adjusts difficulty, pace, and content to individual learners
- **Multi-Sensory**: Engages visual, auditory, and kinesthetic learning channels
- **Engagement-First**: Gamification and interest-based content selection

### 1.3 Core Educational Pillars

Based on the National Reading Panel's Five Pillars:

1. **Phonemic Awareness** - Hearing and manipulating sounds in spoken words
2. **Phonics** - Understanding letter-sound relationships
3. **Fluency** - Reading with speed, accuracy, and expression
4. **Vocabulary** - Word knowledge and meaning
5. **Comprehension** - Understanding and interpreting text

---

## 2. Educational Framework

### 2.1 Pedagogical Approach

The system implements **Structured Literacy**, distinguished by:

| Principle | Implementation |
|-----------|---------------|
| **Systematic** | Follows logical order from simple to complex |
| **Cumulative** | Each step builds on previous mastery |
| **Explicit** | Direct instruction with clear explanations |
| **Diagnostic** | Continuous assessment informs instruction |
| **Multi-sensory** | Engages multiple learning pathways |

### 2.2 Letter Introduction Sequence

Research supports teaching letters in a strategic order rather than A-Z:

**Phase 1 - Foundation Letters (Weeks 1-3)**
```
s, a, t, p, i, n
```
These enable early word formation: at, an, it, in, sat, pat, tan, pin, etc.

**Phase 2 - High-Utility Consonants (Weeks 4-6)**
```
m, d, c, h, r
```

**Phase 3 - Common Letters (Weeks 7-9)**
```
b, f, g, k, o
```

**Phase 4 - Remaining Common (Weeks 10-12)**
```
l, e, u, w
```

**Phase 5 - Digraphs & Less Common (Weeks 13-16)**
```
sh, th, ch, wh, ck
j, v, x, y, z, qu
```

### 2.3 Phonics Scope & Sequence

#### Kindergarten Progression

| Stage | Skills | Example Words |
|-------|--------|---------------|
| 1 | Letter sounds, short vowels | a, m, s, t |
| 2 | VC words | am, at, it, in |
| 3 | CVC words | cat, sit, mop |
| 4 | Word families | -at, -an, -it, -op |
| 5 | Beginning digraphs | sh-, ch-, th- |
| 6 | Ending digraphs | -ck, -sh, -th |
| 7 | Beginning blends | bl-, cl-, st- |
| 8 | Long vowels intro | CVCe: make, bike |

#### First Grade Progression

| Stage | Skills | Example Words |
|-------|--------|---------------|
| 9 | Ending blends | -nd, -mp, -st |
| 10 | CCVC words | stop, clap, flag |
| 11 | CVCC words | fast, jump, milk |
| 12 | Silent-e patterns | cake, bike, rope |
| 13 | Vowel teams | ai, ay, ee, ea |
| 14 | R-controlled vowels | ar, or, er, ir, ur |
| 15 | Diphthongs | oi, oy, ou, ow |
| 16 | Multi-syllable words | sunset, rabbit |

### 2.4 Sight Words Integration

The system incorporates high-frequency words using a hybrid approach:

**Decodable Sight Words** (taught through phonics):
- Regular patterns: can, did, get, him, not, run, will

**Tricky Words** (taught as wholes with explanation):
- Irregular patterns: the, said, was, of, you, are

**Progression by Frequency** (based on Dolch/Fry lists):

| Level | Words | Examples |
|-------|-------|----------|
| Pre-K | 40 | the, and, a, to, in |
| K | 52 | he, was, for, on, are |
| 1st | 41 | his, that, she, or, an |
| 2nd | 46 | would, very, your, its |
| 3rd | 41 | about, better, carry |

---

## 3. System Architecture

### 3.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        CLIENT (React)                           │
├─────────────────────────────────────────────────────────────────┤
│  LessonPlayer  │  ActivityEngine  │  ProgressDashboard          │
│       ↓               ↓                   ↓                     │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              State Management (Context/Store)            │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ REST API
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                       SERVER (Express)                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │   Lesson     │  │   Progress   │  │    Voice     │         │
│  │  Generator   │  │   Tracker    │  │   Service    │         │
│  └──────────────┘  └──────────────┘  └──────────────┘         │
│         │                 │                 │                   │
│         ▼                 ▼                 ▼                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              Adaptive Algorithm Engine                   │   │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐    │   │
│  │  │Difficulty│  │ Content │  │  Pace   │  │Interest │    │   │
│  │  │ Adjuster │  │Selector │  │ Manager │  │ Matcher │    │   │
│  │  └─────────┘  └─────────┘  └─────────┘  └─────────┘    │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                  │
└──────────────────────────────│──────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                        DATA LAYER                               │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │   Content    │  │    Child     │  │   Session    │         │
│  │   Library    │  │   Profiles   │  │    Data      │         │
│  └──────────────┘  └──────────────┘  └──────────────┘         │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 Lesson Generator Service

The core service responsible for creating personalized lessons:

```typescript
interface LessonGeneratorService {
  // Generate a complete lesson based on child profile
  generateLesson(childId: string): Promise<Lesson>;

  // Generate next activity within current lesson
  generateNextActivity(sessionId: string): Promise<Activity>;

  // Adjust lesson based on real-time performance
  adaptLesson(sessionId: string, performance: PerformanceData): Promise<void>;

  // Get recommended review content
  getReviewContent(childId: string): Promise<ReviewContent>;
}
```

### 3.3 Component Breakdown

#### Lesson Generator
- Queries child profile for current skill levels
- Selects appropriate content from curriculum library
- Structures activities following pedagogical sequence
- Incorporates spaced repetition for mastery

#### Progress Tracker
- Records activity outcomes in real-time
- Calculates mastery levels per skill
- Identifies struggling areas and strengths
- Triggers alerts for parent dashboard

#### Adaptive Algorithm Engine
- Processes performance data streams
- Adjusts difficulty within sessions
- Selects content based on interests
- Manages pacing for engagement

#### Voice Service (Existing)
- Text-to-speech for phoneme pronunciation
- Word reading demonstrations
- Story narration
- Pronunciation feedback

---

## 4. Data Models

### 4.1 Child Profile

```typescript
interface ChildProfile {
  id: string;
  name: string;
  age: number;                    // 4-6 years
  avatarId: string;
  createdAt: Date;

  // Learning characteristics
  learningStyle: LearningStyle;
  interests: Interest[];
  preferredSessionLength: number; // minutes

  // Current progress
  currentLevel: SkillLevels;
  masteredSkills: string[];
  strugglingSkills: string[];

  // Engagement metrics
  streakDays: number;
  totalSessionsCompleted: number;
  averageSessionDuration: number;

  // Personalization
  voicePreference: string;        // ElevenLabs voice ID
  themePreference: string;
  rewardPreferences: RewardType[];
}

interface LearningStyle {
  visual: number;      // 0-1 preference weight
  auditory: number;
  kinesthetic: number;
  readingPace: 'slow' | 'medium' | 'fast';
  attentionSpan: 'short' | 'medium' | 'long';
}

interface Interest {
  category: InterestCategory;
  weight: number;      // 0-1 preference strength
}

type InterestCategory =
  | 'animals'
  | 'vehicles'
  | 'nature'
  | 'space'
  | 'fantasy'
  | 'sports'
  | 'food'
  | 'music'
  | 'art';
```

### 4.2 Skill Levels

```typescript
interface SkillLevels {
  // Phonemic Awareness
  phonemicAwareness: {
    rhyming: MasteryLevel;
    syllableAwareness: MasteryLevel;
    onsetRime: MasteryLevel;
    phonemeIsolation: MasteryLevel;
    phonemeBlending: MasteryLevel;
    phonemeSegmentation: MasteryLevel;
    phonemeManipulation: MasteryLevel;
  };

  // Phonics
  phonics: {
    letterRecognition: LetterMastery;
    letterSounds: LetterMastery;
    shortVowels: VowelMastery;
    longVowels: VowelMastery;
    cvcWords: MasteryLevel;
    digraphs: DigraphMastery;
    blends: BlendMastery;
    cvceWords: MasteryLevel;
    vowelTeams: VowelTeamMastery;
    rControlled: MasteryLevel;
  };

  // Sight Words
  sightWords: {
    preK: SightWordMastery;
    kindergarten: SightWordMastery;
    firstGrade: SightWordMastery;
  };

  // Fluency
  fluency: {
    accuracy: number;          // 0-100%
    wordsPerMinute: number;
    prosody: MasteryLevel;
  };

  // Comprehension
  comprehension: {
    literal: MasteryLevel;
    inferential: MasteryLevel;
    vocabulary: number;        // estimated word count
  };
}

type MasteryLevel =
  | 'not_introduced'
  | 'emerging'      // < 60% accuracy
  | 'developing'    // 60-79% accuracy
  | 'proficient'    // 80-94% accuracy
  | 'mastered';     // >= 95% accuracy

interface LetterMastery {
  uppercase: Record<string, MasteryLevel>;  // A-Z
  lowercase: Record<string, MasteryLevel>;  // a-z
}
```

### 4.3 Lesson Structure

```typescript
interface Lesson {
  id: string;
  childId: string;
  createdAt: Date;

  // Lesson metadata
  targetSkills: string[];
  estimatedDuration: number;     // minutes
  difficulty: DifficultyLevel;
  theme: InterestCategory;

  // Lesson structure
  warmUp: WarmUpActivity;
  coreActivities: Activity[];
  review: ReviewActivity;
  coolDown: CoolDownActivity;

  // Adaptive parameters
  adaptiveConfig: AdaptiveConfig;
}

interface Activity {
  id: string;
  type: ActivityType;
  skill: string;
  difficulty: DifficultyLevel;
  content: ActivityContent;

  // Timing
  estimatedDuration: number;     // seconds
  maxAttempts: number;

  // Success criteria
  successThreshold: number;      // 0-1

  // Engagement
  reward: Reward;
  encouragements: string[];
}

type ActivityType =
  // Phonemic Awareness
  | 'rhyme_match'
  | 'syllable_clap'
  | 'sound_isolation'
  | 'sound_blending'
  | 'sound_segmentation'

  // Letter Recognition
  | 'letter_identification'
  | 'letter_tracing'
  | 'letter_sound_match'

  // Phonics
  | 'word_building'
  | 'word_reading'
  | 'word_sorting'
  | 'word_family_practice'

  // Sight Words
  | 'sight_word_flash'
  | 'sight_word_sentence'
  | 'tricky_word_practice'

  // Reading
  | 'decodable_text'
  | 'guided_reading'
  | 'echo_reading'

  // Games
  | 'letter_hunt'
  | 'word_puzzle'
  | 'story_sequence';
```

### 4.4 Session & Performance Data

```typescript
interface LearningSession {
  id: string;
  childId: string;
  lessonId: string;
  startedAt: Date;
  endedAt?: Date;

  // Performance tracking
  activities: ActivityResult[];

  // Engagement metrics
  totalTime: number;             // seconds
  activeTime: number;            // seconds engaged
  pauseCount: number;

  // Adaptive adjustments made
  difficultyAdjustments: DifficultyAdjustment[];
}

interface ActivityResult {
  activityId: string;
  skill: string;
  startedAt: Date;
  completedAt: Date;

  // Performance
  attempts: AttemptResult[];
  finalScore: number;            // 0-1
  timeSpent: number;             // seconds

  // Engagement signals
  hesitationEvents: number;
  requestedHelp: boolean;
  usedHint: boolean;

  // Outcome
  outcome: 'completed' | 'skipped' | 'struggled';
}

interface AttemptResult {
  timestamp: Date;
  correct: boolean;
  responseTime: number;          // milliseconds
  response: any;                 // varies by activity type
  errorType?: ErrorType;
}

type ErrorType =
  | 'visual_confusion'           // b/d, p/q confusion
  | 'phoneme_confusion'          // similar sounds
  | 'vowel_error'
  | 'blend_error'
  | 'sight_word_error'
  | 'timing_error'
  | 'random_guess';
```

---

## 5. Lesson Structure Templates

### 5.1 Standard Lesson Template (15-20 minutes)

```
┌────────────────────────────────────────────────────────────┐
│  WARM-UP (2-3 min)                                         │
│  - Greeting with character/avatar                          │
│  - Quick review of previous skill (3-5 items)             │
│  - Engagement hook related to theme                        │
├────────────────────────────────────────────────────────────┤
│  INTRODUCTION (2-3 min)                                    │
│  - New concept presentation                                │
│  - Multi-sensory demonstration                             │
│  - Guided example with voice support                       │
├────────────────────────────────────────────────────────────┤
│  GUIDED PRACTICE (5-7 min)                                 │
│  - Activity 1: Scaffolded practice                         │
│  - Activity 2: Interactive game                            │
│  - Real-time feedback and encouragement                    │
├────────────────────────────────────────────────────────────┤
│  INDEPENDENT PRACTICE (3-5 min)                            │
│  - Activity 3: Less scaffolded                             │
│  - Activity 4: Application context                         │
│  - Adaptive difficulty based on performance                │
├────────────────────────────────────────────────────────────┤
│  REVIEW & REWARD (2-3 min)                                 │
│  - Summary of learned skill                                │
│  - Mixed review (new + old)                                │
│  - Reward/celebration                                      │
│  - Preview of next lesson                                  │
└────────────────────────────────────────────────────────────┘
```

### 5.2 Activity Templates by Skill Area

#### Letter Sound Activity Template

```typescript
const letterSoundTemplate: ActivityTemplate = {
  type: 'letter_sound_match',
  structure: {
    introduction: {
      showLetter: true,
      playSound: true,          // ElevenLabs TTS
      showKeyword: true,        // "A says /a/ like apple"
      duration: 5000            // ms
    },
    practice: {
      promptType: 'audio',      // Play sound, find letter
      options: 4,               // Multiple choice count
      distractors: 'visually_similar',
      feedback: 'immediate',
      maxAttempts: 3
    },
    variations: [
      'letter_to_sound',        // See letter, select sound
      'sound_to_letter',        // Hear sound, select letter
      'keyword_to_letter',      // See picture, select letter
      'tracing_with_sound'      // Trace letter, hear sound
    ]
  }
};
```

#### Word Building Activity Template

```typescript
const wordBuildingTemplate: ActivityTemplate = {
  type: 'word_building',
  structure: {
    introduction: {
      showTargetWord: true,
      segmentWord: true,        // Show phoneme breakdown
      playBlending: true,       // "/c/ /a/ /t/ ... cat"
      duration: 6000
    },
    practice: {
      mode: 'drag_and_drop',
      letterBank: 'targeted',   // Only relevant letters
      scaffolding: 'progressive',
      steps: [
        'full_scaffolding',     // Letter positions shown
        'partial_scaffolding',  // First letter shown
        'no_scaffolding'        // Blank boxes only
      ]
    },
    feedback: {
      onCorrect: 'celebration_animation',
      onIncorrect: 'highlight_error',
      playWordOnComplete: true
    }
  }
};
```

#### Decodable Reading Activity Template

```typescript
const decodableReadingTemplate: ActivityTemplate = {
  type: 'decodable_text',
  structure: {
    setup: {
      textLevel: 'calculated',  // Based on child's phonics level
      wordCount: 20-50,
      newWords: 2-3,            // Unfamiliar but decodable
      sightWords: 'mastered_only',
      theme: 'from_interests'
    },
    reading: {
      mode: 'guided',
      highlighting: 'word_by_word',
      voiceModel: 'echo_reading',  // Child reads after model
      pacing: 'child_controlled',
      helpAvailable: true
    },
    comprehension: {
      questions: 2-3,
      types: ['literal', 'picture_match'],
      timing: 'after_passage'
    }
  }
};
```

### 5.3 Warm-Up Patterns

```typescript
const warmUpPatterns: WarmUpPattern[] = [
  {
    name: 'letter_review',
    description: 'Quick flashcard review of recent letters',
    duration: 90,              // seconds
    items: 5,
    selectionCriteria: 'recently_learned',
    format: 'rapid_fire'
  },
  {
    name: 'sound_play',
    description: 'Fun phonemic awareness game',
    duration: 120,
    activities: ['rhyme_game', 'odd_one_out', 'syllable_jump'],
    format: 'game'
  },
  {
    name: 'sight_word_flash',
    description: 'Speed review of sight words',
    duration: 60,
    items: 8,
    selectionCriteria: 'spaced_repetition',
    format: 'timed_flash'
  }
];
```

---

## 6. Progression Paths

### 6.1 Main Progression Track

```
LEVEL 0: PRE-READING FOUNDATION
├── Phonemic Awareness Basics
│   ├── Rhyme recognition
│   ├── Syllable awareness
│   └── Initial sound isolation
├── Letter Familiarity
│   ├── Letter name recognition (uppercase)
│   └── Letter shape discrimination
└── Print Concepts
    ├── Book handling
    ├── Left-to-right tracking
    └── Word vs. letter awareness

LEVEL 1: ALPHABET MASTERY
├── Phase 1 Letters: s, a, t, p, i, n
│   ├── Letter recognition (upper & lower)
│   ├── Letter-sound correspondence
│   └── Letter formation (tracing)
├── VC Word Introduction
│   ├── Word family: -at
│   └── Word family: -an
├── First Sight Words
│   └── the, a, I, and

LEVEL 2: CVC FOUNDATIONS
├── Phase 2 Letters: m, d, c, h, r
├── CVC Words
│   ├── Word families: -at, -an, -it, -in
│   └── Mixed CVC decoding
├── Phoneme Blending
│   └── Oral blending → written words
├── More Sight Words
│   └── is, to, we, he, she

LEVEL 3: EXPANDING CVC
├── Phase 3 Letters: b, f, g, k, o
├── Extended Word Families
│   ├── -ot, -op, -ob
│   └── -ig, -ip, -ib
├── Decodable Sentences
│   └── Simple 3-4 word sentences
├── Sight Word Sentences
│   └── "I can see the cat."

LEVEL 4: DIGRAPHS
├── Phase 4 Letters: l, e, u, w
├── Consonant Digraphs
│   ├── sh- words
│   ├── ch- words
│   ├── th- words (voiced & unvoiced)
│   └── -ck words
├── Short Vowel Review
│   └── All 5 short vowels mixed
├── Decodable Stories
│   └── 30-50 word passages

LEVEL 5: BLENDS
├── Phase 5 Letters: j, v, x, y, z, qu
├── Beginning Blends
│   ├── L-blends: bl, cl, fl, gl, pl, sl
│   ├── R-blends: br, cr, dr, fr, gr, pr, tr
│   └── S-blends: sc, sk, sm, sn, sp, st, sw
├── CCVC Words
│   └── stop, clap, frog, step
├── Fluency Building
│   └── Phrase reading, expression

LEVEL 6: LONG VOWELS
├── Silent-E Pattern (CVCe)
│   ├── a_e: make, cake, lake
│   ├── i_e: bike, like, time
│   ├── o_e: bone, home, note
│   ├── u_e: cute, tube, flute
│   └── e_e: Pete, theme
├── Vowel Teams Introduction
│   ├── ai, ay: rain, play
│   └── ee, ea: tree, team
├── Chapter Book Readiness
│   └── Multi-paragraph stories

LEVEL 7: ADVANCED PHONICS
├── More Vowel Teams
│   ├── oa, ow: boat, show
│   ├── oo (long): moon, food
│   ├── oo (short): book, foot
│   └── ou, ow: house, cow
├── R-Controlled Vowels
│   ├── ar: car, star
│   ├── or: for, storm
│   └── er, ir, ur: her, bird, turn
├── Diphthongs
│   ├── oi, oy: coin, boy
│   └── ou, ow (diphthong): loud, now

LEVEL 8: MULTISYLLABLE
├── Syllable Types
│   ├── Closed syllables
│   ├── Open syllables
│   ├── VCe syllables
│   └── Vowel team syllables
├── Compound Words
│   └── sunlight, baseball, cupcake
├── Prefixes & Suffixes Intro
│   ├── un-, re-
│   └── -ing, -ed, -er, -est
├── Reading Fluency Goals
│   └── 60+ WPM with expression
```

### 6.2 Parallel Skill Tracks

Skills are developed in parallel, not strictly sequential:

```
Timeline →
─────────────────────────────────────────────────────────────►

Phonemic    ████████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
Awareness   [Intensive early, then maintenance]

Letter      ░░░░████████████████████░░░░░░░░░░░░░░░░░░░░░░░░
Knowledge   [Builds through Level 3]

Phonics     ░░░░░░░░████████████████████████████████████████
            [Begins Level 1, continues throughout]

Sight       ░░░░░░░░░░░░████████████████████████████████████
Words       [Begins Level 1, continuous growth]

Fluency     ░░░░░░░░░░░░░░░░░░░░████████████████████████████
            [Builds as decoding automates]

Comprehension ░░░░░░░░░░░░░░░░░░░░░░░░████████████████████████
              [Formal instruction begins Level 4]
```

### 6.3 Mastery Requirements for Advancement

```typescript
interface LevelMasteryRequirements {
  level: number;
  requirements: {
    skills: SkillRequirement[];
    assessmentScore: number;     // Minimum % on level assessment
    consistencyDays: number;     // Days maintaining mastery
  };
}

const level1Requirements: LevelMasteryRequirements = {
  level: 1,
  requirements: {
    skills: [
      { skill: 'letter_recognition_satpin', mastery: 'proficient' },
      { skill: 'letter_sounds_satpin', mastery: 'proficient' },
      { skill: 'vc_words_at_an', mastery: 'developing' },
      { skill: 'sight_words_set1', mastery: 'developing' }
    ],
    assessmentScore: 80,
    consistencyDays: 3
  }
};
```

---

## 7. Adaptive Difficulty Algorithm

### 7.1 Algorithm Overview

The adaptive system operates on three time scales:

1. **Real-time (within activity)**: Adjusts scaffolding, hints, item difficulty
2. **Session-level**: Adjusts lesson flow, activity selection
3. **Long-term**: Adjusts curriculum pacing, skill focus areas

### 7.2 Real-Time Adaptation

```typescript
interface RealTimeAdaptation {
  // Triggered after each response
  onResponse(result: AttemptResult): AdaptationAction;
}

class RealTimeAdapter implements RealTimeAdaptation {
  private consecutiveCorrect: number = 0;
  private consecutiveIncorrect: number = 0;
  private averageResponseTime: number;

  onResponse(result: AttemptResult): AdaptationAction {
    if (result.correct) {
      this.consecutiveCorrect++;
      this.consecutiveIncorrect = 0;

      // Mastery detected - increase challenge
      if (this.consecutiveCorrect >= 3 &&
          result.responseTime < this.averageResponseTime * 0.8) {
        return {
          action: 'increase_difficulty',
          changes: ['remove_hints', 'add_distractors', 'reduce_time']
        };
      }
    } else {
      this.consecutiveCorrect = 0;
      this.consecutiveIncorrect++;

      // Struggling detected - provide support
      if (this.consecutiveIncorrect >= 2) {
        return {
          action: 'decrease_difficulty',
          changes: ['add_scaffolding', 'provide_hint', 'simplify_options']
        };
      }

      // Analyze error type for targeted support
      return this.analyzeError(result);
    }

    return { action: 'continue', changes: [] };
  }

  private analyzeError(result: AttemptResult): AdaptationAction {
    switch (result.errorType) {
      case 'visual_confusion':
        return {
          action: 'targeted_support',
          changes: ['highlight_differences', 'zoom_letters', 'trace_shape']
        };
      case 'phoneme_confusion':
        return {
          action: 'targeted_support',
          changes: ['replay_sounds', 'mouth_position_demo', 'minimal_pairs']
        };
      case 'blend_error':
        return {
          action: 'targeted_support',
          changes: ['segment_word', 'slow_blend_demo', 'finger_mapping']
        };
      default:
        return {
          action: 'general_support',
          changes: ['encouragement', 'model_correct', 'retry']
        };
    }
  }
}
```

### 7.3 Session-Level Adaptation

```typescript
interface SessionAdapter {
  // Called periodically during session (every 3-5 activities)
  evaluateAndAdapt(session: LearningSession): SessionAdjustment;
}

class SessionLevelAdapter implements SessionAdapter {
  evaluateAndAdapt(session: LearningSession): SessionAdjustment {
    const recentResults = session.activities.slice(-5);
    const performance = this.calculatePerformanceMetrics(recentResults);
    const engagement = this.calculateEngagementMetrics(session);

    const adjustment: SessionAdjustment = {
      nextActivityType: null,
      difficultyShift: 0,
      breakRecommended: false,
      skillFocusChange: null
    };

    // Performance-based adjustments
    if (performance.accuracy < 0.6) {
      adjustment.difficultyShift = -1;
      adjustment.nextActivityType = 'review_game';
      adjustment.skillFocusChange = this.identifyGapSkill(recentResults);
    } else if (performance.accuracy > 0.9 && performance.speed === 'fast') {
      adjustment.difficultyShift = +1;
      adjustment.nextActivityType = 'challenge_activity';
    }

    // Engagement-based adjustments
    if (engagement.hesitationRate > 0.4 || engagement.activeTimeRatio < 0.7) {
      adjustment.nextActivityType = 'game_break';
      adjustment.breakRecommended = session.totalTime > 600; // 10 min
    }

    // Fatigue detection
    if (this.detectFatigue(session)) {
      adjustment.breakRecommended = true;
      adjustment.nextActivityType = 'reward_celebration';
    }

    return adjustment;
  }

  private detectFatigue(session: LearningSession): boolean {
    const recentActivities = session.activities.slice(-3);

    // Increasing response times
    const responseTimeTrend = this.calculateTrend(
      recentActivities.map(a => a.averageResponseTime)
    );

    // Decreasing accuracy
    const accuracyTrend = this.calculateTrend(
      recentActivities.map(a => a.finalScore)
    );

    // More hesitation events
    const hesitationTrend = this.calculateTrend(
      recentActivities.map(a => a.hesitationEvents)
    );

    return responseTimeTrend > 0.2 &&
           accuracyTrend < -0.1 &&
           hesitationTrend > 0.15;
  }
}
```

### 7.4 Long-Term Adaptation

```typescript
interface LongTermAdapter {
  // Called at end of each session
  updateLearnerModel(childId: string, session: LearningSession): void;

  // Called when generating new lesson
  getOptimalLessonConfig(childId: string): LessonConfig;
}

class LongTermAdaptationEngine implements LongTermAdapter {
  updateLearnerModel(childId: string, session: LearningSession): void {
    const profile = this.getProfile(childId);

    // Update skill mastery levels
    for (const activity of session.activities) {
      this.updateSkillMastery(profile, activity);
    }

    // Update learning style preferences
    this.updateLearningStyle(profile, session);

    // Identify patterns
    this.analyzeErrorPatterns(profile, session);

    // Update pace preference
    this.updatePacePreference(profile, session);

    // Calculate optimal session time
    this.updateOptimalSessionLength(profile, session);

    // Save updated profile
    this.saveProfile(profile);
  }

  getOptimalLessonConfig(childId: string): LessonConfig {
    const profile = this.getProfile(childId);
    const readiness = this.assessReadiness(profile);

    return {
      // Skill selection: 70% current level, 20% review, 10% preview
      skills: {
        primary: this.selectPrimarySkills(profile, readiness),
        review: this.selectReviewSkills(profile),
        preview: this.selectPreviewSkills(profile, readiness)
      },

      // Difficulty calibration
      startingDifficulty: this.calculateOptimalDifficulty(profile),

      // Activity type preferences
      activityTypes: this.selectActivityTypes(profile),

      // Timing
      targetDuration: profile.preferredSessionLength,
      breakFrequency: this.calculateBreakFrequency(profile),

      // Content theming
      theme: this.selectTheme(profile.interests),

      // Engagement elements
      rewardDensity: this.calculateRewardDensity(profile),
      gamificationLevel: this.calculateGamificationLevel(profile)
    };
  }

  private selectPrimarySkills(
    profile: ChildProfile,
    readiness: ReadinessAssessment
  ): Skill[] {
    const skills: Skill[] = [];

    // Find skills at the learning edge (developing → proficient)
    const developingSkills = this.getSkillsAtMastery(profile, 'developing');

    // Prioritize by:
    // 1. Prerequisites met
    // 2. Recent struggle (needs practice)
    // 3. Time since last practice (spaced repetition)

    for (const skill of developingSkills) {
      if (this.prerequisitesMet(profile, skill)) {
        const priority = this.calculatePriority(profile, skill);
        skills.push({ ...skill, priority });
      }
    }

    return skills
      .sort((a, b) => b.priority - a.priority)
      .slice(0, 3);
  }
}
```

### 7.5 Difficulty Levels & Parameters

```typescript
interface DifficultyParameters {
  level: 1 | 2 | 3 | 4 | 5;

  // Cognitive load
  itemCount: number;           // Items per activity
  optionCount: number;         // Multiple choice options
  distractorSimilarity: 'low' | 'medium' | 'high';

  // Scaffolding
  hintsAvailable: boolean;
  hintDelay: number;           // ms before hint offered
  modelingProvided: boolean;
  feedbackDetail: 'minimal' | 'standard' | 'detailed';

  // Timing
  timeLimit: number | null;    // null = unlimited
  paceGuidance: boolean;

  // Success threshold
  requiredAccuracy: number;    // To pass activity
  masteryThreshold: number;    // To mark skill mastered
}

const difficultyLevels: Record<number, DifficultyParameters> = {
  1: { // Very Easy - Maximum Support
    level: 1,
    itemCount: 3,
    optionCount: 2,
    distractorSimilarity: 'low',
    hintsAvailable: true,
    hintDelay: 3000,
    modelingProvided: true,
    feedbackDetail: 'detailed',
    timeLimit: null,
    paceGuidance: true,
    requiredAccuracy: 0.5,
    masteryThreshold: 0.7
  },
  3: { // Medium - Standard
    level: 3,
    itemCount: 6,
    optionCount: 4,
    distractorSimilarity: 'medium',
    hintsAvailable: true,
    hintDelay: 8000,
    modelingProvided: false,
    feedbackDetail: 'standard',
    timeLimit: null,
    paceGuidance: false,
    requiredAccuracy: 0.7,
    masteryThreshold: 0.85
  },
  5: { // Challenge - Minimal Support
    level: 5,
    itemCount: 10,
    optionCount: 6,
    distractorSimilarity: 'high',
    hintsAvailable: false,
    hintDelay: 0,
    modelingProvided: false,
    feedbackDetail: 'minimal',
    timeLimit: 30000,
    paceGuidance: false,
    requiredAccuracy: 0.8,
    masteryThreshold: 0.95
  }
};
```

---

## 8. Integration Points

### 8.1 Voice Service Integration

The existing ElevenLabs integration is critical for:

```typescript
interface VoiceIntegration {
  // Letter/sound pronunciation
  playLetterSound(letter: string, options?: VoiceOptions): Promise<void>;

  // Word pronunciation with optional segmentation
  playWord(word: string, segmented?: boolean): Promise<void>;

  // Sentence/passage reading
  playText(text: string, options?: ReadingOptions): Promise<void>;

  // Feedback and encouragement
  playFeedback(type: FeedbackType): Promise<void>;

  // Instructions
  playInstruction(instructionId: string): Promise<void>;
}

interface ReadingOptions {
  speed: 'slow' | 'normal' | 'fast';
  highlightSync: boolean;    // Sync with text highlighting
  pauseBetweenWords: number; // ms
}
```

### 8.2 Content Library Structure

```typescript
interface ContentLibrary {
  // Phonics content
  letters: LetterContent[];
  phonemes: PhonemeContent[];
  words: WordContent[];
  wordFamilies: WordFamily[];

  // Reading content
  decodableTexts: DecodableText[];
  stories: Story[];

  // Media assets
  images: ImageAsset[];
  animations: AnimationAsset[];
  sounds: SoundAsset[];

  // Activity templates
  activityTemplates: ActivityTemplate[];
}

interface WordContent {
  word: string;
  phonemes: string[];         // ['c', 'a', 't']
  syllables: string[];        // ['cat']
  decodability: {
    level: number;
    patterns: string[];       // ['CVC', 'short_a']
  };
  frequency: number;          // Usage frequency rank
  isSightWord: boolean;
  sightWordLevel?: string;    // 'dolch_prek', 'fry_100', etc.
  images: string[];           // Asset IDs
  sentences: string[];        // Example sentences
  categories: string[];       // ['animals', 'pets']
}

interface DecodableText {
  id: string;
  title: string;
  level: number;
  wordCount: number;

  // Readability metrics
  uniqueWords: number;
  decodableWordPercent: number;
  sightWordPercent: number;

  // Content
  text: string;
  sentences: Sentence[];

  // Required skills
  phonicsPatterns: string[];
  sightWordsUsed: string[];

  // Metadata
  theme: InterestCategory;
  comprehensionQuestions: ComprehensionQuestion[];
  vocabulary: VocabularyWord[];
}
```

### 8.3 Parent Dashboard Data

```typescript
interface ParentDashboardData {
  child: {
    name: string;
    currentLevel: string;
    overallProgress: number;   // 0-100%
  };

  // Recent activity
  recentSessions: SessionSummary[];
  weeklyMinutes: number;
  streakDays: number;

  // Skill progress
  skillProgress: {
    phonemicAwareness: ProgressSummary;
    letterKnowledge: ProgressSummary;
    phonics: ProgressSummary;
    sightWords: ProgressSummary;
    fluency: ProgressSummary;
    comprehension: ProgressSummary;
  };

  // Insights
  strengths: string[];
  areasForGrowth: string[];
  recommendations: Recommendation[];

  // Achievements
  recentAchievements: Achievement[];
  nextMilestones: Milestone[];
}

interface Recommendation {
  type: 'activity' | 'practice' | 'celebration';
  title: string;
  description: string;
  offlineActivity?: OfflineActivity;
}

interface OfflineActivity {
  name: string;
  description: string;
  materials: string[];
  targetSkill: string;
  duration: string;
}
```

---

## 9. Implementation Roadmap

### Phase 1: Foundation (Weeks 1-4)

**Goal**: Core data models and basic lesson structure

- [ ] Implement child profile data model
- [ ] Create skill levels tracking system
- [ ] Build lesson structure templates
- [ ] Design activity component framework
- [ ] Set up content library schema
- [ ] Create basic lesson generator (non-adaptive)

### Phase 2: Content Library (Weeks 5-8)

**Goal**: Populate educational content

- [ ] Letter content (26 letters, sounds, keywords, images)
- [ ] Phoneme content library
- [ ] Word library (500+ words, categorized)
- [ ] Sight words (Dolch/Fry pre-K through 1st)
- [ ] 20 decodable texts (Levels 1-3)
- [ ] Activity templates for each activity type

### Phase 3: Activity Engine (Weeks 9-12)

**Goal**: Interactive learning activities

- [ ] Letter recognition activities
- [ ] Letter-sound matching
- [ ] Word building activities
- [ ] Word reading activities
- [ ] Sight word practice
- [ ] Basic reading activities
- [ ] Voice integration for all activities

### Phase 4: Adaptive System (Weeks 13-16)

**Goal**: Personalization and adaptation

- [ ] Real-time difficulty adjustment
- [ ] Session-level adaptation
- [ ] Long-term learner modeling
- [ ] Spaced repetition system
- [ ] Error pattern analysis
- [ ] Engagement optimization

### Phase 5: Assessment & Progress (Weeks 17-20)

**Goal**: Measurement and reporting

- [ ] Placement assessment
- [ ] Progress assessments (per level)
- [ ] Mastery tracking dashboard
- [ ] Parent dashboard
- [ ] Progress reports
- [ ] Achievement system

### Phase 6: Polish & Scale (Weeks 21-24)

**Goal**: Production readiness

- [ ] Performance optimization
- [ ] Expand content library (more texts, themes)
- [ ] A/B testing framework
- [ ] Analytics integration
- [ ] Accessibility audit
- [ ] User testing and iteration

---

## Appendix A: Research Sources

### Educational Research

- National Reading Panel (2000): Teaching Children to Read
- International Dyslexia Association: Structured Literacy
- Reading Rockets: Phonological Awareness Guidelines
- NWEA (2025): National Reading Panel Update

### Phonics Scope & Sequence References

- Keys to Literacy: Systematic Phonics Scope and Sequence
- Measured Mom: Phonics Teaching Order
- Natalie Lynn Kindergarten: Kindergarten Phonics Scope

### Sight Word Lists

- Dolch Word List (220 service words + 95 nouns)
- Fry Instant Word List (1000 words)

### Adaptive Learning Research

- Bill & Melinda Gates Foundation: Adaptive Learning Studies
- ScienceDirect: PAL Technology Meta-Analysis

---

## Appendix B: Glossary

| Term | Definition |
|------|------------|
| CVC | Consonant-Vowel-Consonant word pattern (cat, sit) |
| CVCe | Consonant-Vowel-Consonant-silent E pattern (cake, bike) |
| Digraph | Two letters making one sound (sh, ch, th) |
| Blend | Two or more consonants where each sound is heard (bl, st) |
| Phoneme | Smallest unit of sound in language |
| Grapheme | Written representation of a phoneme |
| Onset | Initial consonant(s) before the vowel in a syllable |
| Rime | Vowel and consonants following it in a syllable |
| Decodable text | Text composed primarily of words following taught patterns |
| Sight word | High-frequency word to be recognized automatically |

---

*Document prepared for L2RR2L Dynamic Lesson Generation System*
*Research completed January 2026*
