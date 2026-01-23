import gameWordsData from '../../docs/content/game-words.json'
import type { GameWord, GameWordsData } from './types'

export type { GameWord, GameWordsData, WordCategory, DifficultyLevel } from './types'
export { getWordsByDifficulty, getWordsByCategory, getWordsByVowelSound } from './types'

export const gameWords: GameWordsData = gameWordsData as GameWordsData

export function getAllWords(): GameWord[] {
  return gameWords.words
}

export function getStarterWords(): GameWord[] {
  return gameWords.words.filter(w => w.difficulty === 1)
}

export function getBeginnerWords(): GameWord[] {
  return gameWords.words.filter(w => w.difficulty === 2)
}

export function getDevelopingWords(): GameWord[] {
  return gameWords.words.filter(w => w.difficulty === 3)
}

export function getWordById(id: string): GameWord | undefined {
  return gameWords.words.find(w => w.id === id)
}

export function getRandomWords(count: number, difficulty?: 1 | 2 | 3): GameWord[] {
  let pool = [...gameWords.words]
  if (difficulty !== undefined) {
    pool = pool.filter(w => w.difficulty === difficulty)
  }
  const shuffled = pool.sort(() => Math.random() - 0.5)
  return shuffled.slice(0, count)
}
