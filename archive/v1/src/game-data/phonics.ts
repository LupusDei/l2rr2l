import phonicsWordsData from '../../docs/content/phonics-words.json'
import type { PhonicsWord, PhonicsWordsData } from './phonics-types'

export type {
  PhonicsWord,
  PhonicsWordsData,
  PhonicsCategory,
  DifficultyLevel,
} from './phonics-types'
export {
  getWordsByBeginningSound,
  getWordsByDifficulty,
  getWordsByCategory,
  getUniqueBeginningSounds,
} from './phonics-types'

export const phonicsWords: PhonicsWordsData = phonicsWordsData as PhonicsWordsData

export function getAllPhonicsWords(): PhonicsWord[] {
  return phonicsWords.words
}

export function getPhonicsWordById(id: string): PhonicsWord | undefined {
  return phonicsWords.words.find((w) => w.id === id)
}

export function getRandomPhonicsWords(
  count: number,
  options?: {
    difficulty?: 1 | 2 | 3
    beginningSound?: string
  }
): PhonicsWord[] {
  let pool = [...phonicsWords.words]

  if (options?.difficulty !== undefined) {
    pool = pool.filter((w) => w.difficulty === options.difficulty)
  }

  if (options?.beginningSound !== undefined) {
    pool = pool.filter((w) => w.beginningSound === options.beginningSound)
  }

  const shuffled = pool.sort(() => Math.random() - 0.5)
  return shuffled.slice(0, count)
}

export function getBeginningSounds(): string[] {
  return phonicsWords.beginningSounds
}

export function getWordPairsForSoundMatching(
  soundsCount: number,
  wordsPerSound: number,
  difficulty?: 1 | 2 | 3
): Map<string, PhonicsWord[]> {
  const sounds = [...phonicsWords.beginningSounds].sort(() => Math.random() - 0.5)
  const selectedSounds = sounds.slice(0, soundsCount)

  const result = new Map<string, PhonicsWord[]>()

  for (const sound of selectedSounds) {
    let wordsForSound = phonicsWords.words.filter((w) => w.beginningSound === sound)

    if (difficulty !== undefined) {
      wordsForSound = wordsForSound.filter((w) => w.difficulty <= difficulty)
    }

    const shuffled = wordsForSound.sort(() => Math.random() - 0.5)
    result.set(sound, shuffled.slice(0, wordsPerSound))
  }

  return result
}
