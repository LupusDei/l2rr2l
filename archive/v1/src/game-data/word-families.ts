import wordFamiliesData from '../../docs/content/word-families.json'
import type {
  WordFamily,
  WordFamiliesData,
  WordFamilyWord,
  WordFamilyCategory,
} from './word-families-types'

export type {
  WordFamily,
  WordFamiliesData,
  WordFamilyWord,
  WordFamilyCategory,
  DifficultyLevel,
} from './word-families-types'
export {
  getWordFamiliesByDifficulty,
  getWordFamiliesByCategory,
  getWordFamilyByRime,
  getAllRimes,
  getValidWords,
} from './word-families-types'

export const wordFamilies: WordFamiliesData = wordFamiliesData as WordFamiliesData

export function getAllWordFamilies(): WordFamily[] {
  return wordFamilies.families
}

export function getWordFamilyById(id: string): WordFamily | undefined {
  return wordFamilies.families.find((f) => f.id === id)
}

export function getRandomWordFamilies(
  count: number,
  options?: {
    difficulty?: 1 | 2 | 3
    category?: WordFamilyCategory
  }
): WordFamily[] {
  let pool = [...wordFamilies.families]

  if (options?.difficulty !== undefined) {
    pool = pool.filter((f) => f.difficulty === options.difficulty)
  }

  if (options?.category !== undefined) {
    pool = pool.filter((f) => f.category === options.category)
  }

  const shuffled = pool.sort(() => Math.random() - 0.5)
  return shuffled.slice(0, count)
}

export function getAvailableRimes(): string[] {
  return wordFamilies.families.map((f) => f.rime)
}

export function getRandomWordFromFamily(family: WordFamily): WordFamilyWord {
  const validWords = family.words.filter((w) => w.isReal)
  return validWords[Math.floor(Math.random() * validWords.length)]
}

export function checkWord(rime: string, onset: string): boolean {
  const family = wordFamilies.families.find((f) => f.rime === rime)
  if (!family) return false
  return family.validOnsets.includes(onset)
}

export function getWordByOnset(
  family: WordFamily,
  onset: string
): WordFamilyWord | undefined {
  return family.words.find((w) => w.onset === onset)
}

/**
 * Get word families suitable for a game session.
 * Returns families with enough valid words for gameplay.
 */
export function getWordFamiliesForGame(
  count: number,
  difficulty?: 1 | 2 | 3,
  minWordsPerFamily: number = 5
): WordFamily[] {
  let pool = wordFamilies.families.filter(
    (f) => f.words.filter((w) => w.isReal).length >= minWordsPerFamily
  )

  if (difficulty !== undefined) {
    pool = pool.filter((f) => f.difficulty === difficulty)
  }

  const shuffled = pool.sort(() => Math.random() - 0.5)
  return shuffled.slice(0, count)
}

/**
 * Get available onset letters for the game (letters kids can drag to build words).
 * Returns common consonants used across word families.
 */
export function getGameOnsets(): string[] {
  // Common single consonants that appear in word families
  return [
    'b',
    'c',
    'd',
    'f',
    'g',
    'h',
    'j',
    'k',
    'l',
    'm',
    'n',
    'p',
    'r',
    's',
    't',
    'v',
    'w',
    'y',
    'z',
  ]
}
