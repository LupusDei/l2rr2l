/**
 * ReadAloud Game Word Data
 *
 * Progressive word lists for the read-aloud speech recognition game.
 * Words are organized by difficulty tier and category.
 */

import {
  prePrimerWords,
  primerWords,
} from './sight-words'
import type {
  ReadAloudWord,
  ReadAloudTier,
  ReadAloudCategory,
  ReadAloudTierMeta,
  DifficultyProgression,
} from './read-aloud-types'
export type {
  ReadAloudWord,
  ReadAloudTier,
  ReadAloudCategory,
  ReadAloudTierMeta,
  WordProgress,
  DifficultyProgression,
} from './read-aloud-types'
export {
  getWordsByTier,
  getWordsByCategory,
  shouldAdvanceTier,
  shouldDecreaseTier,
  updateProgression,
  isWordMastered,
  createInitialProgression,
  PROGRESSION_THRESHOLDS,
} from './read-aloud-types'

/**
 * Tier 1: Simple CVC words - easiest to read and pronounce
 */
const tier1Words: ReadAloudWord[] = [
  // CVC words - animals
  { id: 'ra-cat', word: 'cat', tier: 1, category: 'cvc', phonemes: ['k', 'æ', 't'], syllables: 1 },
  { id: 'ra-dog', word: 'dog', tier: 1, category: 'cvc', phonemes: ['d', 'ɔ', 'g'], syllables: 1 },
  { id: 'ra-pig', word: 'pig', tier: 1, category: 'cvc', phonemes: ['p', 'ɪ', 'g'], syllables: 1 },
  { id: 'ra-bug', word: 'bug', tier: 1, category: 'cvc', phonemes: ['b', 'ʌ', 'g'], syllables: 1 },
  { id: 'ra-hen', word: 'hen', tier: 1, category: 'cvc', phonemes: ['h', 'ɛ', 'n'], syllables: 1 },
  { id: 'ra-fox', word: 'fox', tier: 1, category: 'cvc', phonemes: ['f', 'ɔ', 'ks'], syllables: 1 },
  // CVC words - actions
  { id: 'ra-run', word: 'run', tier: 1, category: 'cvc', phonemes: ['r', 'ʌ', 'n'], syllables: 1 },
  { id: 'ra-hop', word: 'hop', tier: 1, category: 'cvc', phonemes: ['h', 'ɔ', 'p'], syllables: 1 },
  { id: 'ra-sit', word: 'sit', tier: 1, category: 'cvc', phonemes: ['s', 'ɪ', 't'], syllables: 1 },
  { id: 'ra-nap', word: 'nap', tier: 1, category: 'cvc', phonemes: ['n', 'æ', 'p'], syllables: 1 },
  { id: 'ra-cut', word: 'cut', tier: 1, category: 'cvc', phonemes: ['k', 'ʌ', 't'], syllables: 1 },
  { id: 'ra-hug', word: 'hug', tier: 1, category: 'cvc', phonemes: ['h', 'ʌ', 'g'], syllables: 1 },
  // CVC words - objects
  { id: 'ra-cup', word: 'cup', tier: 1, category: 'cvc', phonemes: ['k', 'ʌ', 'p'], syllables: 1 },
  { id: 'ra-hat', word: 'hat', tier: 1, category: 'cvc', phonemes: ['h', 'æ', 't'], syllables: 1 },
  { id: 'ra-bed', word: 'bed', tier: 1, category: 'cvc', phonemes: ['b', 'ɛ', 'd'], syllables: 1 },
  { id: 'ra-sun', word: 'sun', tier: 1, category: 'cvc', phonemes: ['s', 'ʌ', 'n'], syllables: 1 },
  { id: 'ra-map', word: 'map', tier: 1, category: 'cvc', phonemes: ['m', 'æ', 'p'], syllables: 1 },
  { id: 'ra-rug', word: 'rug', tier: 1, category: 'cvc', phonemes: ['r', 'ʌ', 'g'], syllables: 1 },
  // CVC words - more
  { id: 'ra-box', word: 'box', tier: 1, category: 'cvc', phonemes: ['b', 'ɔ', 'ks'], syllables: 1 },
  { id: 'ra-pot', word: 'pot', tier: 1, category: 'cvc', phonemes: ['p', 'ɔ', 't'], syllables: 1 },
  { id: 'ra-wet', word: 'wet', tier: 1, category: 'cvc', phonemes: ['w', 'ɛ', 't'], syllables: 1 },
  { id: 'ra-big', word: 'big', tier: 1, category: 'cvc', phonemes: ['b', 'ɪ', 'g'], syllables: 1 },
  { id: 'ra-top', word: 'top', tier: 1, category: 'cvc', phonemes: ['t', 'ɔ', 'p'], syllables: 1 },
  { id: 'ra-red', word: 'red', tier: 1, category: 'cvc', phonemes: ['r', 'ɛ', 'd'], syllables: 1 },
]

/**
 * Tier 2: Sight words and common words
 */
const tier2Words: ReadAloudWord[] = [
  // Core sight words from pre-primer
  ...prePrimerWords.slice(0, 20).map((word, i): ReadAloudWord => ({
    id: `ra-sight-${i}`,
    word,
    tier: 2,
    category: 'sight',
    phonemes: [], // Sight words are recognized whole
    syllables: 1,
  })),
  // Word family words
  { id: 'ra-bat', word: 'bat', tier: 2, category: 'word-family', phonemes: ['b', 'æ', 't'], syllables: 1 },
  { id: 'ra-mat', word: 'mat', tier: 2, category: 'word-family', phonemes: ['m', 'æ', 't'], syllables: 1 },
  { id: 'ra-rat', word: 'rat', tier: 2, category: 'word-family', phonemes: ['r', 'æ', 't'], syllables: 1 },
  { id: 'ra-sat', word: 'sat', tier: 2, category: 'word-family', phonemes: ['s', 'æ', 't'], syllables: 1 },
  { id: 'ra-pan', word: 'pan', tier: 2, category: 'word-family', phonemes: ['p', 'æ', 'n'], syllables: 1 },
  { id: 'ra-man', word: 'man', tier: 2, category: 'word-family', phonemes: ['m', 'æ', 'n'], syllables: 1 },
  { id: 'ra-can', word: 'can', tier: 2, category: 'word-family', phonemes: ['k', 'æ', 'n'], syllables: 1 },
  { id: 'ra-fan', word: 'fan', tier: 2, category: 'word-family', phonemes: ['f', 'æ', 'n'], syllables: 1 },
  { id: 'ra-pin', word: 'pin', tier: 2, category: 'word-family', phonemes: ['p', 'ɪ', 'n'], syllables: 1 },
  { id: 'ra-win', word: 'win', tier: 2, category: 'word-family', phonemes: ['w', 'ɪ', 'n'], syllables: 1 },
  { id: 'ra-bin', word: 'bin', tier: 2, category: 'word-family', phonemes: ['b', 'ɪ', 'n'], syllables: 1 },
  { id: 'ra-fin', word: 'fin', tier: 2, category: 'word-family', phonemes: ['f', 'ɪ', 'n'], syllables: 1 },
]

/**
 * Tier 3: More complex words - phonics patterns and multi-syllable
 */
const tier3Words: ReadAloudWord[] = [
  // Phonics patterns - digraphs
  { id: 'ra-ship', word: 'ship', tier: 3, category: 'phonics', phonemes: ['ʃ', 'ɪ', 'p'], syllables: 1, pronunciationHint: 'sh-ip' },
  { id: 'ra-shop', word: 'shop', tier: 3, category: 'phonics', phonemes: ['ʃ', 'ɔ', 'p'], syllables: 1, pronunciationHint: 'sh-op' },
  { id: 'ra-chip', word: 'chip', tier: 3, category: 'phonics', phonemes: ['tʃ', 'ɪ', 'p'], syllables: 1, pronunciationHint: 'ch-ip' },
  { id: 'ra-chop', word: 'chop', tier: 3, category: 'phonics', phonemes: ['tʃ', 'ɔ', 'p'], syllables: 1, pronunciationHint: 'ch-op' },
  { id: 'ra-thin', word: 'thin', tier: 3, category: 'phonics', phonemes: ['θ', 'ɪ', 'n'], syllables: 1, pronunciationHint: 'th-in' },
  { id: 'ra-this', word: 'this', tier: 3, category: 'phonics', phonemes: ['ð', 'ɪ', 's'], syllables: 1, pronunciationHint: 'th-is' },
  { id: 'ra-when', word: 'when', tier: 3, category: 'phonics', phonemes: ['w', 'ɛ', 'n'], syllables: 1, pronunciationHint: 'wh-en' },
  { id: 'ra-what', word: 'what', tier: 3, category: 'phonics', phonemes: ['w', 'ʌ', 't'], syllables: 1, pronunciationHint: 'wh-at' },
  // Phonics patterns - blends
  { id: 'ra-stop', word: 'stop', tier: 3, category: 'phonics', phonemes: ['s', 't', 'ɔ', 'p'], syllables: 1, pronunciationHint: 'st-op' },
  { id: 'ra-step', word: 'step', tier: 3, category: 'phonics', phonemes: ['s', 't', 'ɛ', 'p'], syllables: 1, pronunciationHint: 'st-ep' },
  { id: 'ra-skip', word: 'skip', tier: 3, category: 'phonics', phonemes: ['s', 'k', 'ɪ', 'p'], syllables: 1, pronunciationHint: 'sk-ip' },
  { id: 'ra-swim', word: 'swim', tier: 3, category: 'phonics', phonemes: ['s', 'w', 'ɪ', 'm'], syllables: 1, pronunciationHint: 'sw-im' },
  { id: 'ra-snap', word: 'snap', tier: 3, category: 'phonics', phonemes: ['s', 'n', 'æ', 'p'], syllables: 1, pronunciationHint: 'sn-ap' },
  { id: 'ra-spot', word: 'spot', tier: 3, category: 'phonics', phonemes: ['s', 'p', 'ɔ', 't'], syllables: 1, pronunciationHint: 'sp-ot' },
  // Multi-syllable words
  { id: 'ra-rabbit', word: 'rabbit', tier: 3, category: 'multi-syllable', phonemes: ['r', 'æ', 'b', 'ɪ', 't'], syllables: 2, pronunciationHint: 'rab-bit' },
  { id: 'ra-kitten', word: 'kitten', tier: 3, category: 'multi-syllable', phonemes: ['k', 'ɪ', 't', 'ə', 'n'], syllables: 2, pronunciationHint: 'kit-ten' },
  { id: 'ra-puppet', word: 'puppet', tier: 3, category: 'multi-syllable', phonemes: ['p', 'ʌ', 'p', 'ə', 't'], syllables: 2, pronunciationHint: 'pup-pet' },
  { id: 'ra-muffin', word: 'muffin', tier: 3, category: 'multi-syllable', phonemes: ['m', 'ʌ', 'f', 'ɪ', 'n'], syllables: 2, pronunciationHint: 'muf-fin' },
  { id: 'ra-happy', word: 'happy', tier: 3, category: 'multi-syllable', phonemes: ['h', 'æ', 'p', 'i'], syllables: 2, pronunciationHint: 'hap-py' },
  { id: 'ra-funny', word: 'funny', tier: 3, category: 'multi-syllable', phonemes: ['f', 'ʌ', 'n', 'i'], syllables: 2, pronunciationHint: 'fun-ny' },
  // More primer sight words
  ...primerWords.slice(0, 10).map((word, i): ReadAloudWord => ({
    id: `ra-primer-${i}`,
    word,
    tier: 3,
    category: 'sight',
    phonemes: [],
    syllables: 1,
  })),
]

/**
 * All read-aloud words combined
 */
export const readAloudWords: ReadAloudWord[] = [
  ...tier1Words,
  ...tier2Words,
  ...tier3Words,
]

/**
 * Tier metadata for display
 */
export const readAloudTiers: Record<ReadAloudTier, ReadAloudTierMeta> = {
  1: {
    tier: 1,
    name: 'Starter',
    description: 'Simple 3-letter words that are easy to sound out',
    targetAge: '3-4 years',
    wordCount: tier1Words.length,
  },
  2: {
    tier: 2,
    name: 'Explorer',
    description: 'Common sight words and word families',
    targetAge: '4-5 years',
    wordCount: tier2Words.length,
  },
  3: {
    tier: 3,
    name: 'Champion',
    description: 'Phonics patterns and longer words',
    targetAge: '5-6 years',
    wordCount: tier3Words.length,
  },
}

/**
 * Get all words for a specific tier
 */
export function getReadAloudWordsByTier(tier: ReadAloudTier): ReadAloudWord[] {
  return readAloudWords.filter((w) => w.tier === tier)
}

/**
 * Get random words for a game session
 */
export function getRandomReadAloudWords(
  count: number,
  options?: {
    tier?: ReadAloudTier
    category?: ReadAloudCategory
    excludeIds?: string[]
  }
): ReadAloudWord[] {
  let pool = [...readAloudWords]

  if (options?.tier !== undefined) {
    pool = pool.filter((w) => w.tier === options.tier)
  }

  if (options?.category !== undefined) {
    pool = pool.filter((w) => w.category === options.category)
  }

  if (options?.excludeIds?.length) {
    pool = pool.filter((w) => !options.excludeIds!.includes(w.id))
  }

  const shuffled = pool.sort(() => Math.random() - 0.5)
  return shuffled.slice(0, Math.min(count, pool.length))
}

/**
 * Get the next word for a session based on progression
 */
export function getNextWord(
  progression: DifficultyProgression,
  excludeIds: string[] = []
): ReadAloudWord | null {
  const tierWords = getReadAloudWordsByTier(progression.currentTier)
  const available = tierWords.filter((w) => !excludeIds.includes(w.id))

  if (available.length === 0) {
    return null
  }

  return available[Math.floor(Math.random() * available.length)]
}

/**
 * Get a word by ID
 */
export function getReadAloudWordById(id: string): ReadAloudWord | undefined {
  return readAloudWords.find((w) => w.id === id)
}

/**
 * Check if spoken word matches target (with variation tolerance)
 */
export function isWordMatch(
  target: ReadAloudWord,
  spoken: string
): boolean {
  const normalizedTarget = target.word.toLowerCase().trim()
  const normalizedSpoken = spoken.toLowerCase().trim()

  // Exact match
  if (normalizedTarget === normalizedSpoken) {
    return true
  }

  // Check accepted variations
  if (target.acceptedVariations?.some((v) => v.toLowerCase() === normalizedSpoken)) {
    return true
  }

  return false
}

/**
 * Get categories available at a tier
 */
export function getCategoriesForTier(tier: ReadAloudTier): ReadAloudCategory[] {
  const categories = new Set(
    readAloudWords.filter((w) => w.tier === tier).map((w) => w.category)
  )
  return Array.from(categories)
}
