export interface RhymeWord {
  id: string
  word: string
  wordFamily: string
  difficulty: 1 | 2 | 3
  image: string
  emoji: string
  audio: string
}

export interface RhymeDistractor {
  id: string
  word: string
  confusedWith: string[]
  difficulty: 1 | 2 | 3
  emoji: string
}

export interface DifficultyLevel {
  name: string
  description: string
  targetAge: string
}

export interface RhymeWordsData {
  version: string
  description: string
  words: RhymeWord[]
  wordFamilies: string[]
  distractors: RhymeDistractor[]
  difficultyLevels: Record<string, DifficultyLevel>
  assetNotes: {
    images: string
    audio: string
  }
}

export function getWordsByFamily(
  words: RhymeWord[],
  family: string
): RhymeWord[] {
  return words.filter((w) => w.wordFamily === family)
}

export function getWordsByDifficulty(
  words: RhymeWord[],
  difficulty: 1 | 2 | 3
): RhymeWord[] {
  return words.filter((w) => w.difficulty <= difficulty)
}

export function getUniqueWordFamilies(words: RhymeWord[]): string[] {
  const families = new Set(words.map((w) => w.wordFamily))
  return Array.from(families).sort()
}

export function doWordsRhyme(word1: RhymeWord, word2: RhymeWord): boolean {
  return word1.wordFamily === word2.wordFamily && word1.id !== word2.id
}

export function getDistractorsForFamily(
  distractors: RhymeDistractor[],
  family: string,
  difficulty?: 1 | 2 | 3
): RhymeDistractor[] {
  let pool = distractors.filter((d) => d.confusedWith.includes(family))
  if (difficulty !== undefined) {
    pool = pool.filter((d) => d.difficulty <= difficulty)
  }
  return pool
}
