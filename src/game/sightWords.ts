// Sight words for memory game, organized by difficulty level
// Based on Dolch sight word lists

export interface SightWord {
  word: string
  level: 'pre-primer' | 'primer' | 'grade1'
}

// Pre-Primer sight words (40 words)
export const prePrimerWords: SightWord[] = [
  { word: 'a', level: 'pre-primer' },
  { word: 'and', level: 'pre-primer' },
  { word: 'away', level: 'pre-primer' },
  { word: 'big', level: 'pre-primer' },
  { word: 'blue', level: 'pre-primer' },
  { word: 'can', level: 'pre-primer' },
  { word: 'come', level: 'pre-primer' },
  { word: 'down', level: 'pre-primer' },
  { word: 'find', level: 'pre-primer' },
  { word: 'for', level: 'pre-primer' },
  { word: 'funny', level: 'pre-primer' },
  { word: 'go', level: 'pre-primer' },
  { word: 'help', level: 'pre-primer' },
  { word: 'here', level: 'pre-primer' },
  { word: 'I', level: 'pre-primer' },
  { word: 'in', level: 'pre-primer' },
  { word: 'is', level: 'pre-primer' },
  { word: 'it', level: 'pre-primer' },
  { word: 'jump', level: 'pre-primer' },
  { word: 'little', level: 'pre-primer' },
  { word: 'look', level: 'pre-primer' },
  { word: 'make', level: 'pre-primer' },
  { word: 'me', level: 'pre-primer' },
  { word: 'my', level: 'pre-primer' },
  { word: 'not', level: 'pre-primer' },
  { word: 'one', level: 'pre-primer' },
  { word: 'play', level: 'pre-primer' },
  { word: 'red', level: 'pre-primer' },
  { word: 'run', level: 'pre-primer' },
  { word: 'said', level: 'pre-primer' },
  { word: 'see', level: 'pre-primer' },
  { word: 'the', level: 'pre-primer' },
  { word: 'three', level: 'pre-primer' },
  { word: 'to', level: 'pre-primer' },
  { word: 'two', level: 'pre-primer' },
  { word: 'up', level: 'pre-primer' },
  { word: 'we', level: 'pre-primer' },
  { word: 'where', level: 'pre-primer' },
  { word: 'yellow', level: 'pre-primer' },
  { word: 'you', level: 'pre-primer' },
]

// Primer sight words (52 words)
export const primerWords: SightWord[] = [
  { word: 'all', level: 'primer' },
  { word: 'am', level: 'primer' },
  { word: 'are', level: 'primer' },
  { word: 'at', level: 'primer' },
  { word: 'ate', level: 'primer' },
  { word: 'be', level: 'primer' },
  { word: 'black', level: 'primer' },
  { word: 'brown', level: 'primer' },
  { word: 'but', level: 'primer' },
  { word: 'came', level: 'primer' },
  { word: 'did', level: 'primer' },
  { word: 'do', level: 'primer' },
  { word: 'eat', level: 'primer' },
  { word: 'four', level: 'primer' },
  { word: 'get', level: 'primer' },
  { word: 'good', level: 'primer' },
  { word: 'have', level: 'primer' },
  { word: 'he', level: 'primer' },
  { word: 'into', level: 'primer' },
  { word: 'like', level: 'primer' },
  { word: 'must', level: 'primer' },
  { word: 'new', level: 'primer' },
  { word: 'no', level: 'primer' },
  { word: 'now', level: 'primer' },
  { word: 'on', level: 'primer' },
  { word: 'our', level: 'primer' },
  { word: 'out', level: 'primer' },
  { word: 'please', level: 'primer' },
  { word: 'pretty', level: 'primer' },
  { word: 'ran', level: 'primer' },
  { word: 'ride', level: 'primer' },
  { word: 'saw', level: 'primer' },
  { word: 'say', level: 'primer' },
  { word: 'she', level: 'primer' },
  { word: 'so', level: 'primer' },
  { word: 'soon', level: 'primer' },
  { word: 'that', level: 'primer' },
  { word: 'there', level: 'primer' },
  { word: 'they', level: 'primer' },
  { word: 'this', level: 'primer' },
  { word: 'too', level: 'primer' },
  { word: 'under', level: 'primer' },
  { word: 'want', level: 'primer' },
  { word: 'was', level: 'primer' },
  { word: 'well', level: 'primer' },
  { word: 'went', level: 'primer' },
  { word: 'what', level: 'primer' },
  { word: 'white', level: 'primer' },
  { word: 'who', level: 'primer' },
  { word: 'will', level: 'primer' },
  { word: 'with', level: 'primer' },
  { word: 'yes', level: 'primer' },
]

// Grade 1 sight words (41 words)
export const grade1Words: SightWord[] = [
  { word: 'after', level: 'grade1' },
  { word: 'again', level: 'grade1' },
  { word: 'an', level: 'grade1' },
  { word: 'any', level: 'grade1' },
  { word: 'ask', level: 'grade1' },
  { word: 'as', level: 'grade1' },
  { word: 'by', level: 'grade1' },
  { word: 'could', level: 'grade1' },
  { word: 'every', level: 'grade1' },
  { word: 'fly', level: 'grade1' },
  { word: 'from', level: 'grade1' },
  { word: 'give', level: 'grade1' },
  { word: 'going', level: 'grade1' },
  { word: 'had', level: 'grade1' },
  { word: 'has', level: 'grade1' },
  { word: 'her', level: 'grade1' },
  { word: 'him', level: 'grade1' },
  { word: 'his', level: 'grade1' },
  { word: 'how', level: 'grade1' },
  { word: 'just', level: 'grade1' },
  { word: 'know', level: 'grade1' },
  { word: 'let', level: 'grade1' },
  { word: 'live', level: 'grade1' },
  { word: 'may', level: 'grade1' },
  { word: 'of', level: 'grade1' },
  { word: 'old', level: 'grade1' },
  { word: 'once', level: 'grade1' },
  { word: 'open', level: 'grade1' },
  { word: 'over', level: 'grade1' },
  { word: 'put', level: 'grade1' },
  { word: 'round', level: 'grade1' },
  { word: 'some', level: 'grade1' },
  { word: 'stop', level: 'grade1' },
  { word: 'take', level: 'grade1' },
  { word: 'thank', level: 'grade1' },
  { word: 'them', level: 'grade1' },
  { word: 'then', level: 'grade1' },
  { word: 'think', level: 'grade1' },
  { word: 'walk', level: 'grade1' },
  { word: 'were', level: 'grade1' },
  { word: 'when', level: 'grade1' },
]

// Grid configurations for different difficulty levels
export type GridConfig = {
  rows: number
  cols: number
  pairs: number
}

export const gridConfigs: Record<string, GridConfig> = {
  easy: { rows: 3, cols: 4, pairs: 6 },     // 4x3 = 12 cards = 6 pairs
  medium: { rows: 4, cols: 4, pairs: 8 },   // 4x4 = 16 cards = 8 pairs
  hard: { rows: 4, cols: 6, pairs: 12 },    // 6x4 = 24 cards = 12 pairs
}

// Get words for a specific level
export function getWordsForLevel(level: SightWord['level']): SightWord[] {
  switch (level) {
    case 'pre-primer':
      return prePrimerWords
    case 'primer':
      return primerWords
    case 'grade1':
      return grade1Words
    default:
      return prePrimerWords
  }
}

// Shuffle array using Fisher-Yates algorithm
export function shuffleArray<T>(array: T[]): T[] {
  const shuffled = [...array]
  for (let i = shuffled.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1))
    ;[shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]]
  }
  return shuffled
}

// Get random words for memory game
export function getMemoryGameWords(level: SightWord['level'], pairCount: number): SightWord[] {
  const words = getWordsForLevel(level)
  const shuffled = shuffleArray(words)
  return shuffled.slice(0, pairCount)
}
