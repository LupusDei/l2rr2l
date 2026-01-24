/**
 * Dolch Sight Words organized by difficulty level for memory game
 *
 * The Dolch word list contains 220 high-frequency words that children
 * should learn to recognize by sight. These are organized into levels
 * based on the original Dolch classification.
 */

export type SightWordLevel = 'pre-primer' | 'primer' | 'grade1'

export interface SightWord {
  id: string
  word: string
  level: SightWordLevel
}

export interface SightWordLevel_Meta {
  id: SightWordLevel
  name: string
  description: string
  wordCount: number
  targetAge: string
}

export interface MemoryCard {
  id: string
  word: string
  pairId: string
  level: SightWordLevel
}

/**
 * Dolch Pre-Primer Words (40 words)
 * Target: Pre-Kindergarten, ages 3-4
 */
export const prePrimerWords: readonly string[] = [
  'a', 'and', 'away', 'big', 'blue', 'can', 'come', 'down',
  'find', 'for', 'funny', 'go', 'help', 'here', 'I', 'in',
  'is', 'it', 'jump', 'little', 'look', 'make', 'me', 'my',
  'not', 'one', 'play', 'red', 'run', 'said', 'see', 'the',
  'three', 'to', 'two', 'up', 'we', 'where', 'yellow', 'you'
] as const

/**
 * Dolch Primer Words (52 words)
 * Target: Kindergarten, ages 4-5
 */
export const primerWords: readonly string[] = [
  'all', 'am', 'are', 'at', 'ate', 'be', 'black', 'brown',
  'but', 'came', 'did', 'do', 'eat', 'four', 'get', 'good',
  'have', 'he', 'into', 'like', 'must', 'new', 'no', 'now',
  'on', 'our', 'out', 'please', 'pretty', 'ran', 'ride', 'saw',
  'say', 'she', 'so', 'soon', 'that', 'there', 'they', 'this',
  'too', 'under', 'want', 'was', 'well', 'went', 'what', 'white',
  'who', 'will', 'with', 'yes'
] as const

/**
 * Dolch Grade 1 Words (41 words)
 * Target: First Grade, ages 5-6
 */
export const grade1Words: readonly string[] = [
  'after', 'again', 'an', 'any', 'as', 'ask', 'by', 'could',
  'every', 'fly', 'from', 'give', 'giving', 'had', 'has', 'her',
  'him', 'his', 'how', 'just', 'know', 'let', 'live', 'may',
  'of', 'old', 'once', 'open', 'over', 'put', 'round', 'some',
  'stop', 'take', 'thank', 'them', 'then', 'think', 'walk', 'were',
  'when'
] as const

/**
 * Level metadata for display and configuration
 */
export const sightWordLevels: Record<SightWordLevel, SightWordLevel_Meta> = {
  'pre-primer': {
    id: 'pre-primer',
    name: 'Pre-Primer',
    description: 'Basic high-frequency words for beginning readers',
    wordCount: 40,
    targetAge: '3-4 years (Pre-K)'
  },
  'primer': {
    id: 'primer',
    name: 'Primer',
    description: 'Essential sight words for kindergarten readers',
    wordCount: 52,
    targetAge: '4-5 years (Kindergarten)'
  },
  'grade1': {
    id: 'grade1',
    name: 'Grade 1',
    description: 'First grade sight words for developing readers',
    wordCount: 41,
    targetAge: '5-6 years (First Grade)'
  }
}

/**
 * Get all words for a specific level
 */
export function getWordsByLevel(level: SightWordLevel): readonly string[] {
  switch (level) {
    case 'pre-primer':
      return prePrimerWords
    case 'primer':
      return primerWords
    case 'grade1':
      return grade1Words
  }
}

/**
 * Get all sight words as SightWord objects
 */
export function getAllSightWords(): SightWord[] {
  const words: SightWord[] = []

  prePrimerWords.forEach((word, i) => {
    words.push({ id: `pp-${i}`, word, level: 'pre-primer' })
  })

  primerWords.forEach((word, i) => {
    words.push({ id: `pr-${i}`, word, level: 'primer' })
  })

  grade1Words.forEach((word, i) => {
    words.push({ id: `g1-${i}`, word, level: 'grade1' })
  })

  return words
}

/**
 * Get sight words for a level as SightWord objects
 */
export function getSightWordsByLevel(level: SightWordLevel): SightWord[] {
  return getAllSightWords().filter(w => w.level === level)
}

/**
 * Generate memory card pairs from sight words
 * Each word appears twice (as a pair) for matching
 *
 * @param level - The difficulty level
 * @param count - Number of pairs to generate (each pair = 2 cards)
 * @returns Array of memory cards (2 * count cards)
 */
export function generateMemoryPairs(level: SightWordLevel, count: number): MemoryCard[] {
  const words = [...getWordsByLevel(level)]

  // Shuffle and take requested count
  const shuffled = words.sort(() => Math.random() - 0.5)
  const selected = shuffled.slice(0, Math.min(count, words.length))

  // Create pairs (each word gets two cards with matching pairId)
  const cards: MemoryCard[] = []
  selected.forEach((word, index) => {
    const pairId = `pair-${index}`
    cards.push({
      id: `${pairId}-a`,
      word,
      pairId,
      level
    })
    cards.push({
      id: `${pairId}-b`,
      word,
      pairId,
      level
    })
  })

  // Shuffle the cards
  return cards.sort(() => Math.random() - 0.5)
}

/**
 * Generate memory cards for specific grid sizes
 */
export function generateCardsForGrid(
  level: SightWordLevel,
  rows: number,
  cols: number
): MemoryCard[] {
  const totalCards = rows * cols
  const pairCount = Math.floor(totalCards / 2)
  return generateMemoryPairs(level, pairCount)
}

/**
 * Get a random subset of words from a level
 */
export function getRandomWords(level: SightWordLevel, count: number): string[] {
  const words = [...getWordsByLevel(level)]
  const shuffled = words.sort(() => Math.random() - 0.5)
  return shuffled.slice(0, Math.min(count, words.length))
}

/**
 * Check if two cards are a matching pair
 */
export function isMatchingPair(card1: MemoryCard, card2: MemoryCard): boolean {
  return card1.pairId === card2.pairId && card1.id !== card2.id
}
