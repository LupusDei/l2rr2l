/**
 * ReadAloud Game Word Data Types
 *
 * Types and utilities for the read-aloud game where children
 * read words aloud and have their pronunciation confirmed.
 */

/**
 * Difficulty tiers for read-aloud words
 * - Tier 1: Simple CVC words (cat, dog, run)
 * - Tier 2: Sight words and common words
 * - Tier 3: Multi-syllable and phonics patterns
 */
export type ReadAloudTier = 1 | 2 | 3

/**
 * Word categories for organizing content
 */
export type ReadAloudCategory =
  | 'cvc'           // Consonant-vowel-consonant (cat, dog, pig)
  | 'sight'         // High-frequency sight words (the, and, is)
  | 'phonics'       // Phonics patterns (ship, chop, think)
  | 'word-family'   // Word family patterns (-at, -op, -in)
  | 'multi-syllable' // Multi-syllable words (rabbit, happy)

/**
 * A word available for the read-aloud game
 */
export interface ReadAloudWord {
  id: string
  word: string
  tier: ReadAloudTier
  category: ReadAloudCategory
  /** Phonemes for pronunciation hints */
  phonemes: string[]
  /** Optional pronunciation hint displayed to child */
  pronunciationHint?: string
  /** Syllable count for display */
  syllables: number
  /** Common mispronunciations to accept as "close enough" */
  acceptedVariations?: string[]
}

/**
 * Tier metadata for display and configuration
 */
export interface ReadAloudTierMeta {
  tier: ReadAloudTier
  name: string
  description: string
  targetAge: string
  wordCount: number
}

/**
 * User progress on a specific word
 */
export interface WordProgress {
  wordId: string
  attempts: number
  successes: number
  lastAttempted: Date
  mastered: boolean
}

/**
 * Difficulty progression state for a user session
 */
export interface DifficultyProgression {
  currentTier: ReadAloudTier
  wordsAttemptedInTier: number
  correctInRow: number
  incorrectInRow: number
}

/**
 * Thresholds for difficulty progression
 */
export const PROGRESSION_THRESHOLDS = {
  /** Correct answers in a row to advance tier */
  advanceThreshold: 5,
  /** Incorrect answers in a row to decrease tier */
  decreaseThreshold: 3,
  /** Minimum attempts at a tier before allowing advancement */
  minAttemptsBeforeAdvance: 8,
  /** Success rate required to consider a word mastered */
  masteryRate: 0.8,
  /** Minimum attempts before considering mastery */
  masteryMinAttempts: 3,
} as const

/**
 * Get words by tier
 */
export function getWordsByTier(
  words: ReadAloudWord[],
  tier: ReadAloudTier
): ReadAloudWord[] {
  return words.filter((w) => w.tier === tier)
}

/**
 * Get words by category
 */
export function getWordsByCategory(
  words: ReadAloudWord[],
  category: ReadAloudCategory
): ReadAloudWord[] {
  return words.filter((w) => w.category === category)
}

/**
 * Check if progression should advance to next tier
 */
export function shouldAdvanceTier(progression: DifficultyProgression): boolean {
  return (
    progression.currentTier < 3 &&
    progression.correctInRow >= PROGRESSION_THRESHOLDS.advanceThreshold &&
    progression.wordsAttemptedInTier >= PROGRESSION_THRESHOLDS.minAttemptsBeforeAdvance
  )
}

/**
 * Check if progression should decrease tier
 */
export function shouldDecreaseTier(progression: DifficultyProgression): boolean {
  return (
    progression.currentTier > 1 &&
    progression.incorrectInRow >= PROGRESSION_THRESHOLDS.decreaseThreshold
  )
}

/**
 * Update progression after an attempt
 */
export function updateProgression(
  progression: DifficultyProgression,
  correct: boolean
): DifficultyProgression {
  const updated: DifficultyProgression = {
    ...progression,
    wordsAttemptedInTier: progression.wordsAttemptedInTier + 1,
    correctInRow: correct ? progression.correctInRow + 1 : 0,
    incorrectInRow: correct ? 0 : progression.incorrectInRow + 1,
  }

  // Check for tier advancement
  if (shouldAdvanceTier(updated)) {
    return {
      currentTier: (updated.currentTier + 1) as ReadAloudTier,
      wordsAttemptedInTier: 0,
      correctInRow: 0,
      incorrectInRow: 0,
    }
  }

  // Check for tier decrease
  if (shouldDecreaseTier(updated)) {
    return {
      currentTier: (updated.currentTier - 1) as ReadAloudTier,
      wordsAttemptedInTier: 0,
      correctInRow: 0,
      incorrectInRow: 0,
    }
  }

  return updated
}

/**
 * Check if a word is mastered based on progress
 */
export function isWordMastered(progress: WordProgress): boolean {
  if (progress.attempts < PROGRESSION_THRESHOLDS.masteryMinAttempts) {
    return false
  }
  const rate = progress.successes / progress.attempts
  return rate >= PROGRESSION_THRESHOLDS.masteryRate
}

/**
 * Create initial progression state
 */
export function createInitialProgression(): DifficultyProgression {
  return {
    currentTier: 1,
    wordsAttemptedInTier: 0,
    correctInRow: 0,
    incorrectInRow: 0,
  }
}
