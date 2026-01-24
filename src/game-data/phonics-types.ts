export interface PhonicsWord {
  id: string
  word: string
  beginningSound: string
  phonemes: string[]
  difficulty: 1 | 2 | 3
  image: string
  emoji: string
  audio: string
  category: PhonicsCategory
}

export type PhonicsCategory =
  | 'animals'
  | 'home'
  | 'nature'
  | 'clothing'
  | 'vehicles'
  | 'objects'
  | 'toys'
  | 'food'
  | 'numbers'

export interface DifficultyLevel {
  name: string
  description: string
  targetAge: string
}

export interface PhonicsWordsData {
  version: string
  description: string
  words: PhonicsWord[]
  beginningSounds: string[]
  difficultyLevels: Record<string, DifficultyLevel>
  categories: PhonicsCategory[]
  assetNotes: {
    images: string
    audio: string
  }
}

export function getWordsByBeginningSound(
  words: PhonicsWord[],
  sound: string
): PhonicsWord[] {
  return words.filter((w) => w.beginningSound === sound)
}

export function getWordsByDifficulty(
  words: PhonicsWord[],
  difficulty: 1 | 2 | 3
): PhonicsWord[] {
  return words.filter((w) => w.difficulty === difficulty)
}

export function getWordsByCategory(
  words: PhonicsWord[],
  category: PhonicsCategory
): PhonicsWord[] {
  return words.filter((w) => w.category === category)
}

export function getUniqueBeginningSounds(words: PhonicsWord[]): string[] {
  const sounds = new Set(words.map((w) => w.beginningSound))
  return Array.from(sounds).sort()
}
