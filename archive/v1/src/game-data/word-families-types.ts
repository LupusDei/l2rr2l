/**
 * Word family data types for the word builder game.
 * Word families are groups of words that share the same ending (rime).
 */

export interface WordFamilyWord {
  word: string
  onset: string // Beginning letter(s)
  isReal: boolean // Whether this is a real word
  emoji?: string
}

export interface WordFamily {
  id: string
  rime: string // The word ending (e.g., "at", "an")
  difficulty: 1 | 2 | 3
  validOnsets: string[] // Letters that make real words with this rime
  words: WordFamilyWord[]
  category: WordFamilyCategory
}

export type WordFamilyCategory =
  | 'short-a'
  | 'short-e'
  | 'short-i'
  | 'short-o'
  | 'short-u'

export interface DifficultyLevel {
  name: string
  description: string
  targetAge: string
}

export interface WordFamiliesData {
  version: string
  description: string
  families: WordFamily[]
  difficultyLevels: Record<string, DifficultyLevel>
  categories: WordFamilyCategory[]
}

export function getWordFamiliesByDifficulty(
  families: WordFamily[],
  difficulty: 1 | 2 | 3
): WordFamily[] {
  return families.filter((f) => f.difficulty === difficulty)
}

export function getWordFamiliesByCategory(
  families: WordFamily[],
  category: WordFamilyCategory
): WordFamily[] {
  return families.filter((f) => f.category === category)
}

export function getWordFamilyByRime(
  families: WordFamily[],
  rime: string
): WordFamily | undefined {
  return families.find((f) => f.rime === rime)
}

export function getAllRimes(families: WordFamily[]): string[] {
  return families.map((f) => f.rime)
}

export function getValidWords(family: WordFamily): WordFamilyWord[] {
  return family.words.filter((w) => w.isReal)
}
