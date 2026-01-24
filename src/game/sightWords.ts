// Sight words for memory game
// Based on Dolch sight words list (pre-primer to first grade)

export interface SightWord {
  word: string
  level: 'pre-primer' | 'primer' | 'first'
}

// Pre-primer level (easiest)
export const prePrimerWords: SightWord[] = [
  { word: 'a', level: 'pre-primer' },
  { word: 'and', level: 'pre-primer' },
  { word: 'big', level: 'pre-primer' },
  { word: 'can', level: 'pre-primer' },
  { word: 'come', level: 'pre-primer' },
  { word: 'for', level: 'pre-primer' },
  { word: 'go', level: 'pre-primer' },
  { word: 'help', level: 'pre-primer' },
  { word: 'I', level: 'pre-primer' },
  { word: 'in', level: 'pre-primer' },
  { word: 'is', level: 'pre-primer' },
  { word: 'it', level: 'pre-primer' },
  { word: 'jump', level: 'pre-primer' },
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
  { word: 'to', level: 'pre-primer' },
  { word: 'up', level: 'pre-primer' },
  { word: 'we', level: 'pre-primer' },
  { word: 'you', level: 'pre-primer' },
]

// Primer level
export const primerWords: SightWord[] = [
  { word: 'all', level: 'primer' },
  { word: 'am', level: 'primer' },
  { word: 'are', level: 'primer' },
  { word: 'at', level: 'primer' },
  { word: 'ate', level: 'primer' },
  { word: 'be', level: 'primer' },
  { word: 'but', level: 'primer' },
  { word: 'did', level: 'primer' },
  { word: 'do', level: 'primer' },
  { word: 'eat', level: 'primer' },
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
  { word: 'ran', level: 'primer' },
  { word: 'ride', level: 'primer' },
  { word: 'saw', level: 'primer' },
  { word: 'say', level: 'primer' },
  { word: 'she', level: 'primer' },
  { word: 'so', level: 'primer' },
  { word: 'soon', level: 'primer' },
  { word: 'that', level: 'primer' },
  { word: 'this', level: 'primer' },
  { word: 'was', level: 'primer' },
  { word: 'well', level: 'primer' },
  { word: 'went', level: 'primer' },
  { word: 'what', level: 'primer' },
  { word: 'who', level: 'primer' },
  { word: 'will', level: 'primer' },
  { word: 'with', level: 'primer' },
  { word: 'yes', level: 'primer' },
]

// First grade level
export const firstGradeWords: SightWord[] = [
  { word: 'after', level: 'first' },
  { word: 'again', level: 'first' },
  { word: 'an', level: 'first' },
  { word: 'any', level: 'first' },
  { word: 'ask', level: 'first' },
  { word: 'by', level: 'first' },
  { word: 'could', level: 'first' },
  { word: 'every', level: 'first' },
  { word: 'fly', level: 'first' },
  { word: 'from', level: 'first' },
  { word: 'give', level: 'first' },
  { word: 'going', level: 'first' },
  { word: 'had', level: 'first' },
  { word: 'has', level: 'first' },
  { word: 'her', level: 'first' },
  { word: 'him', level: 'first' },
  { word: 'his', level: 'first' },
  { word: 'how', level: 'first' },
  { word: 'just', level: 'first' },
  { word: 'know', level: 'first' },
  { word: 'let', level: 'first' },
  { word: 'live', level: 'first' },
  { word: 'may', level: 'first' },
  { word: 'of', level: 'first' },
  { word: 'old', level: 'first' },
  { word: 'once', level: 'first' },
  { word: 'open', level: 'first' },
  { word: 'over', level: 'first' },
  { word: 'put', level: 'first' },
  { word: 'round', level: 'first' },
  { word: 'some', level: 'first' },
  { word: 'stop', level: 'first' },
  { word: 'take', level: 'first' },
  { word: 'thank', level: 'first' },
  { word: 'them', level: 'first' },
  { word: 'then', level: 'first' },
  { word: 'think', level: 'first' },
  { word: 'walk', level: 'first' },
  { word: 'were', level: 'first' },
  { word: 'when', level: 'first' },
]

// All sight words combined
export const allSightWords: SightWord[] = [
  ...prePrimerWords,
  ...primerWords,
  ...firstGradeWords,
]

// Get words by level
export function getWordsByLevel(level: SightWord['level']): SightWord[] {
  return allSightWords.filter(w => w.level === level)
}

// Get random words for a game (returns pairs for matching)
export function getRandomWordsForGame(count: number, level?: SightWord['level']): string[] {
  const wordPool = level ? getWordsByLevel(level) : allSightWords

  // Shuffle and pick count/2 unique words (each word appears twice for matching)
  const shuffled = [...wordPool].sort(() => Math.random() - 0.5)
  const selected = shuffled.slice(0, count / 2).map(w => w.word)

  // Duplicate for pairs and shuffle again
  const pairs = [...selected, ...selected]
  return pairs.sort(() => Math.random() - 0.5)
}

// Shuffle an array (Fisher-Yates)
export function shuffleArray<T>(array: T[]): T[] {
  const result = [...array]
  for (let i = result.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1))
    ;[result[i], result[j]] = [result[j], result[i]]
  }
  return result
}
