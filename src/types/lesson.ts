/**
 * Lesson Data Model for Learn to Read, Read to Learn
 *
 * This module defines the TypeScript interfaces for lessons, activities,
 * and progress tracking in the L2RR2L learning system.
 */

// ============================================================================
// Constants (using const objects for erasableSyntaxOnly compatibility)
// ============================================================================

/** Subject categories for lessons */
export const LessonSubject = {
  PHONICS: 'phonics',
  SPELLING: 'spelling',
  SIGHT_WORDS: 'sight-words',
  READING: 'reading',
  WORD_FAMILIES: 'word-families',
  VOCABULARY: 'vocabulary',
  COMPREHENSION: 'comprehension',
} as const

export type LessonSubject = typeof LessonSubject[keyof typeof LessonSubject]

/** Difficulty levels for lessons */
export const DifficultyLevel = {
  BEGINNER: 'beginner',
  INTERMEDIATE: 'intermediate',
  ADVANCED: 'advanced',
} as const

export type DifficultyLevel = typeof DifficultyLevel[keyof typeof DifficultyLevel]

/** Types of activities within a lesson */
export const ActivityType = {
  /** Read text aloud or silently */
  READING: 'reading',
  /** Spell words by arranging letters */
  SPELLING: 'spelling',
  /** Practice letter sounds and blends */
  PHONICS: 'phonics',
  /** Recognize and memorize sight words */
  SIGHT_WORDS: 'sight-words',
  /** Answer questions about content */
  QUIZ: 'quiz',
  /** Match related items (words to pictures, rhymes, etc.) */
  MATCHING: 'matching',
  /** Fill in missing letters or words */
  FILL_IN_BLANK: 'fill-in-blank',
  /** Listen and repeat words/phrases */
  LISTEN_REPEAT: 'listen-repeat',
  /** Build words from word families */
  WORD_BUILDING: 'word-building',
} as const

export type ActivityType = typeof ActivityType[keyof typeof ActivityType]

/** Status of a lesson for a student */
export const LessonStatus = {
  NOT_STARTED: 'not-started',
  IN_PROGRESS: 'in-progress',
  COMPLETED: 'completed',
} as const

export type LessonStatus = typeof LessonStatus[keyof typeof LessonStatus]

// ============================================================================
// Activity Interfaces
// ============================================================================

/** Base interface for all activity types */
export interface BaseActivity {
  id: string
  type: ActivityType
  /** Instructions displayed to the student */
  instructions: string
  /** Text to be spoken by TTS (optional, defaults to instructions) */
  spokenInstructions?: string
  /** Order within the lesson (0-indexed) */
  order: number
  /** Points awarded for completing this activity */
  points?: number
}

/** Reading activity - display text for reading */
export interface ReadingActivity extends BaseActivity {
  type: 'reading'
  /** Text content to read */
  content: string
  /** Optional image to accompany the text */
  imageUrl?: string
  /** Whether to use TTS to read the text aloud */
  readAloud?: boolean
}

/** Spelling activity - spell a word from scrambled letters */
export interface SpellingActivity extends BaseActivity {
  type: 'spelling'
  /** Word to spell */
  word: string
  /** Hint image or emoji */
  hint?: string
  /** Optional audio pronunciation */
  audioUrl?: string
}

/** Phonics activity - practice sounds */
export interface PhonicsActivity extends BaseActivity {
  type: 'phonics'
  /** The sound/phoneme being practiced (e.g., "sh", "th", "a") */
  sound: string
  /** Example words containing this sound */
  exampleWords: string[]
  /** Position of sound in words: beginning, middle, end */
  soundPosition?: 'beginning' | 'middle' | 'end' | 'any'
}

/** Sight words activity - recognize common words */
export interface SightWordsActivity extends BaseActivity {
  type: 'sight-words'
  /** Words to practice */
  words: string[]
  /** Whether to show words in sentences */
  showInContext?: boolean
}

/** Quiz activity - answer questions */
export interface QuizActivity extends BaseActivity {
  type: 'quiz'
  /** The question to answer */
  question: string
  /** Available answer options */
  options: string[]
  /** Index of correct answer in options array */
  correctIndex: number
  /** Explanation shown after answering */
  explanation?: string
}

/** Matching activity - match pairs */
export interface MatchingActivity extends BaseActivity {
  type: 'matching'
  /** Pairs to match [item1, item2] */
  pairs: [string, string][]
  /** Type of matching (word-picture, word-word, etc.) */
  matchType: 'word-picture' | 'word-word' | 'word-definition' | 'rhyme'
}

/** Fill in the blank activity */
export interface FillInBlankActivity extends BaseActivity {
  type: 'fill-in-blank'
  /** Sentence with ___ for blank */
  sentence: string
  /** The correct answer */
  answer: string
  /** Optional word bank */
  wordBank?: string[]
}

/** Listen and repeat activity */
export interface ListenRepeatActivity extends BaseActivity {
  type: 'listen-repeat'
  /** Word or phrase to repeat */
  phrase: string
  /** Whether to check pronunciation */
  checkPronunciation?: boolean
}

/** Word building activity */
export interface WordBuildingActivity extends BaseActivity {
  type: 'word-building'
  /** Word family pattern (e.g., "-at", "-an") */
  pattern: string
  /** Beginning sounds to combine with pattern */
  onsets: string[]
  /** Resulting words */
  words: string[]
}

/** Union type for all activity types */
export type LessonActivity =
  | ReadingActivity
  | SpellingActivity
  | PhonicsActivity
  | SightWordsActivity
  | QuizActivity
  | MatchingActivity
  | FillInBlankActivity
  | ListenRepeatActivity
  | WordBuildingActivity

// ============================================================================
// Lesson Interface
// ============================================================================

/** Main lesson interface */
export interface Lesson {
  /** Unique identifier */
  id: string
  /** Display title */
  title: string
  /** Brief description */
  description: string
  /** Subject category */
  subject: LessonSubject
  /** Difficulty level */
  difficulty: DifficultyLevel
  /** Learning objectives */
  objectives: string[]
  /** Ordered list of activities */
  activities: LessonActivity[]
  /** Estimated duration in minutes */
  durationMinutes: number
  /** Prerequisite lesson IDs */
  prerequisites?: string[]
  /** Tags for filtering/search */
  tags?: string[]
  /** Thumbnail image URL */
  thumbnailUrl?: string
  /** Target age range */
  ageRange?: {
    min: number
    max: number
  }
  /** Creation timestamp */
  createdAt: string
  /** Last update timestamp */
  updatedAt: string
}

// ============================================================================
// Progress Tracking
// ============================================================================

/** Progress on a single activity */
export interface ActivityProgress {
  activityId: string
  completed: boolean
  score?: number
  attempts: number
  timeSpentSeconds: number
  completedAt?: string
}

/** Progress on a lesson */
export interface LessonProgress {
  lessonId: string
  childId: string
  status: LessonStatus
  /** Current activity index (for resuming) */
  currentActivityIndex: number
  /** Progress on individual activities */
  activityProgress: ActivityProgress[]
  /** Overall score (percentage) */
  overallScore?: number
  /** Total time spent on lesson */
  totalTimeSeconds: number
  /** When lesson was started */
  startedAt: string
  /** When lesson was completed */
  completedAt?: string
}

// ============================================================================
// API Types
// ============================================================================

/** Request to create/update a lesson */
export interface LessonCreateRequest {
  title: string
  description: string
  subject: LessonSubject
  difficulty: DifficultyLevel
  objectives: string[]
  activities: Omit<LessonActivity, 'id'>[]
  durationMinutes: number
  prerequisites?: string[]
  tags?: string[]
  thumbnailUrl?: string
  ageRange?: { min: number; max: number }
}

/** Query parameters for listing lessons */
export interface LessonListQuery {
  subject?: LessonSubject
  difficulty?: DifficultyLevel
  tags?: string[]
  search?: string
  limit?: number
  offset?: number
}

/** Response for lesson list */
export interface LessonListResponse {
  lessons: Lesson[]
  total: number
  limit: number
  offset: number
}

// ============================================================================
// Helper Types
// ============================================================================

/** Lesson with progress information for a specific child */
export interface LessonWithProgress extends Lesson {
  progress?: LessonProgress
}

/** Summary statistics for a child's learning */
export interface LearningStats {
  childId: string
  totalLessonsStarted: number
  totalLessonsCompleted: number
  averageScore: number
  totalTimeMinutes: number
  subjectProgress: Record<LessonSubject, {
    lessonsCompleted: number
    averageScore: number
  }>
  recentActivity: {
    lessonId: string
    lessonTitle: string
    status: LessonStatus
    lastAccessedAt: string
  }[]
}
