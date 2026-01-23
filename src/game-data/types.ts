export interface GameWord {
  id: string
  word: string
  phonemes: string[]
  vowelSound: 'short-a' | 'short-e' | 'short-i' | 'short-o' | 'short-u'
  difficulty: 1 | 2 | 3
  image: string
  audio: string
  sentence: string
  category: WordCategory
}

export type WordCategory = 'animals' | 'home' | 'nature' | 'clothing' | 'vehicles' | 'objects'

export interface DifficultyLevel {
  name: string
  description: string
  targetAge: string
}

export interface GameWordsData {
  version: string
  description: string
  words: GameWord[]
  difficultyLevels: Record<string, DifficultyLevel>
  categories: WordCategory[]
  assetNotes: {
    images: string
    audio: string
  }
}

export function getWordsByDifficulty(words: GameWord[], difficulty: 1 | 2 | 3): GameWord[] {
  return words.filter(w => w.difficulty === difficulty)
}

export function getWordsByCategory(words: GameWord[], category: WordCategory): GameWord[] {
  return words.filter(w => w.category === category)
}

export function getWordsByVowelSound(words: GameWord[], vowelSound: GameWord['vowelSound']): GameWord[] {
  return words.filter(w => w.vowelSound === vowelSound)
}
