import rhymeWordsData from '../../docs/content/rhyme-words.json'
import type { RhymeWord, RhymeDistractor, RhymeWordsData } from './rhyme-types'

export type {
  RhymeWord,
  RhymeDistractor,
  RhymeWordsData,
  DifficultyLevel,
} from './rhyme-types'
export {
  getWordsByFamily,
  getWordsByDifficulty,
  getUniqueWordFamilies,
  doWordsRhyme,
  getDistractorsForFamily,
} from './rhyme-types'

export const rhymeWords: RhymeWordsData = rhymeWordsData as RhymeWordsData

export function getAllRhymeWords(): RhymeWord[] {
  return rhymeWords.words
}

export function getRhymeWordById(id: string): RhymeWord | undefined {
  return rhymeWords.words.find((w) => w.id === id)
}

export function getWordFamilies(): string[] {
  return rhymeWords.wordFamilies
}

export function getDistractors(): RhymeDistractor[] {
  return rhymeWords.distractors
}

export function getRandomRhymeWords(
  count: number,
  options?: {
    difficulty?: 1 | 2 | 3
    wordFamily?: string
  }
): RhymeWord[] {
  let pool = [...rhymeWords.words]

  if (options?.difficulty !== undefined) {
    pool = pool.filter((w) => w.difficulty <= options.difficulty!)
  }

  if (options?.wordFamily !== undefined) {
    pool = pool.filter((w) => w.wordFamily === options.wordFamily)
  }

  const shuffled = pool.sort(() => Math.random() - 0.5)
  return shuffled.slice(0, count)
}

export function getRhymingPair(
  difficulty?: 1 | 2 | 3
): [RhymeWord, RhymeWord] | null {
  const families = [...rhymeWords.wordFamilies].sort(() => Math.random() - 0.5)

  for (const family of families) {
    let wordsInFamily = rhymeWords.words.filter((w) => w.wordFamily === family)

    if (difficulty !== undefined) {
      wordsInFamily = wordsInFamily.filter((w) => w.difficulty <= difficulty)
    }

    if (wordsInFamily.length >= 2) {
      const shuffled = wordsInFamily.sort(() => Math.random() - 0.5)
      return [shuffled[0], shuffled[1]]
    }
  }

  return null
}

export interface RhymeQuestion {
  targetWord: RhymeWord
  correctAnswer: RhymeWord
  distractors: (RhymeWord | RhymeDistractor)[]
  allOptions: (RhymeWord | RhymeDistractor)[]
}

export function generateRhymeQuestion(
  difficulty: 1 | 2 | 3 = 1,
  distractorCount: number = 2
): RhymeQuestion | null {
  const pair = getRhymingPair(difficulty)
  if (!pair) return null

  const [targetWord, correctAnswer] = pair

  // Get distractors - mix of non-rhyming words and confusing distractors
  const availableDistractors: (RhymeWord | RhymeDistractor)[] = []

  // Add words from other families as distractors
  const otherFamilyWords = rhymeWords.words.filter(
    (w) =>
      w.wordFamily !== targetWord.wordFamily && w.difficulty <= difficulty
  )
  availableDistractors.push(...otherFamilyWords)

  // Add confusing distractors for this word family
  const confusingDistractors = rhymeWords.distractors.filter(
    (d) =>
      d.confusedWith.includes(targetWord.wordFamily) &&
      d.difficulty <= difficulty
  )
  availableDistractors.push(...confusingDistractors)

  // Shuffle and pick the required number
  const shuffledDistractors = availableDistractors.sort(
    () => Math.random() - 0.5
  )
  const selectedDistractors = shuffledDistractors.slice(0, distractorCount)

  // Combine all options and shuffle
  const allOptions = [correctAnswer, ...selectedDistractors].sort(
    () => Math.random() - 0.5
  )

  return {
    targetWord,
    correctAnswer,
    distractors: selectedDistractors,
    allOptions,
  }
}

export function getWordFamilyStats(): {
  family: string
  count: number
  difficulties: number[]
}[] {
  return rhymeWords.wordFamilies.map((family) => {
    const wordsInFamily = rhymeWords.words.filter(
      (w) => w.wordFamily === family
    )
    const difficulties = [...new Set(wordsInFamily.map((w) => w.difficulty))]
    return {
      family,
      count: wordsInFamily.length,
      difficulties: difficulties.sort(),
    }
  })
}
