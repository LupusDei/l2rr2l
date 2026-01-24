// Rhyme game data - words organized by rhyme families
// Used for the rhyming word matching game

export interface RhymeWord {
  word: string
  image: string // emoji placeholder
  family: string // rhyme family (e.g., 'at', 'an', 'op')
}

export interface RhymeQuestion {
  targetWord: RhymeWord
  correctAnswer: RhymeWord
  distractors: RhymeWord[] // non-rhyming words
}

export interface RhymeDifficultyLevel {
  name: string
  description: string
  families: string[] // which rhyme families to include
  distractorCount: number // how many wrong choices (2-3)
}

// Words grouped by rhyme family
const wordsByFamily: Record<string, RhymeWord[]> = {
  at: [
    { word: 'cat', image: '🐱', family: 'at' },
    { word: 'bat', image: '🦇', family: 'at' },
    { word: 'hat', image: '🎩', family: 'at' },
    { word: 'rat', image: '🐀', family: 'at' },
    { word: 'mat', image: '🧹', family: 'at' },
    { word: 'sat', image: '🪑', family: 'at' },
  ],
  an: [
    { word: 'can', image: '🥫', family: 'an' },
    { word: 'fan', image: '🪭', family: 'an' },
    { word: 'man', image: '👨', family: 'an' },
    { word: 'pan', image: '🍳', family: 'an' },
    { word: 'van', image: '🚐', family: 'an' },
    { word: 'ran', image: '🏃', family: 'an' },
  ],
  op: [
    { word: 'top', image: '🔝', family: 'op' },
    { word: 'hop', image: '🐰', family: 'op' },
    { word: 'pop', image: '🎈', family: 'op' },
    { word: 'mop', image: '🧹', family: 'op' },
    { word: 'stop', image: '🛑', family: 'op' },
    { word: 'drop', image: '💧', family: 'op' },
  ],
  ig: [
    { word: 'pig', image: '🐷', family: 'ig' },
    { word: 'big', image: '🐘', family: 'ig' },
    { word: 'wig', image: '💇', family: 'ig' },
    { word: 'dig', image: '⛏️', family: 'ig' },
    { word: 'fig', image: '🫐', family: 'ig' },
    { word: 'jig', image: '💃', family: 'ig' },
  ],
  ot: [
    { word: 'hot', image: '🔥', family: 'ot' },
    { word: 'pot', image: '🍲', family: 'ot' },
    { word: 'dot', image: '⚫', family: 'ot' },
    { word: 'got', image: '🎁', family: 'ot' },
    { word: 'lot', image: '📦', family: 'ot' },
    { word: 'cot', image: '🛏️', family: 'ot' },
  ],
  un: [
    { word: 'sun', image: '☀️', family: 'un' },
    { word: 'fun', image: '🎉', family: 'un' },
    { word: 'run', image: '🏃', family: 'un' },
    { word: 'bun', image: '🍞', family: 'un' },
    { word: 'gun', image: '🔫', family: 'un' },
    { word: 'pun', image: '😄', family: 'un' },
  ],
  ed: [
    { word: 'bed', image: '🛏️', family: 'ed' },
    { word: 'red', image: '🔴', family: 'ed' },
    { word: 'fed', image: '🍽️', family: 'ed' },
    { word: 'led', image: '💡', family: 'ed' },
    { word: 'wed', image: '💒', family: 'ed' },
    { word: 'shed', image: '🏚️', family: 'ed' },
  ],
  ug: [
    { word: 'bug', image: '🐛', family: 'ug' },
    { word: 'hug', image: '🤗', family: 'ug' },
    { word: 'mug', image: '☕', family: 'ug' },
    { word: 'rug', image: '🟫', family: 'ug' },
    { word: 'jug', image: '🫗', family: 'ug' },
    { word: 'tug', image: '🚢', family: 'ug' },
  ],
}

// Difficulty levels with progressive challenge
export const rhymeDifficultyLevels: RhymeDifficultyLevel[] = [
  {
    name: 'Easy',
    description: 'Common word families with 2 distractors',
    families: ['at', 'an'],
    distractorCount: 2,
  },
  {
    name: 'Medium',
    description: 'More word families with 2 distractors',
    families: ['at', 'an', 'op', 'ig'],
    distractorCount: 2,
  },
  {
    name: 'Hard',
    description: 'All word families with 3 distractors',
    families: ['at', 'an', 'op', 'ig', 'ot', 'un', 'ed', 'ug'],
    distractorCount: 3,
  },
]

// Get all available rhyme families
export function getAvailableFamilies(): string[] {
  return Object.keys(wordsByFamily)
}

// Get all words for a specific family
export function getWordsByFamily(family: string): RhymeWord[] {
  return wordsByFamily[family.toLowerCase()] || []
}

// Get a random word from a family
export function getRandomWordFromFamily(family: string): RhymeWord | undefined {
  const words = getWordsByFamily(family)
  if (words.length === 0) return undefined
  return words[Math.floor(Math.random() * words.length)]
}

// Get words from a different family (for distractors)
export function getDistractorWords(
  excludeFamily: string,
  count: number,
  availableFamilies?: string[]
): RhymeWord[] {
  const families = availableFamilies || getAvailableFamilies()
  const otherFamilies = families.filter((f) => f !== excludeFamily)

  const distractors: RhymeWord[] = []
  const usedWords = new Set<string>()

  // Shuffle families to get variety
  const shuffledFamilies = [...otherFamilies].sort(() => Math.random() - 0.5)

  for (const family of shuffledFamilies) {
    if (distractors.length >= count) break
    const words = getWordsByFamily(family)
    const shuffledWords = [...words].sort(() => Math.random() - 0.5)
    for (const word of shuffledWords) {
      if (!usedWords.has(word.word) && distractors.length < count) {
        distractors.push(word)
        usedWords.add(word.word)
        break // One word per family for variety
      }
    }
  }

  return distractors
}

// Generate a rhyme question
export function generateRhymeQuestion(
  family: string,
  distractorCount: number,
  availableFamilies?: string[]
): RhymeQuestion | null {
  const familyWords = getWordsByFamily(family)
  if (familyWords.length < 2) return null

  // Shuffle and pick target and correct answer
  const shuffled = [...familyWords].sort(() => Math.random() - 0.5)
  const targetWord = shuffled[0]
  const correctAnswer = shuffled[1]

  // Get distractors from other families
  const distractors = getDistractorWords(family, distractorCount, availableFamilies)

  return {
    targetWord,
    correctAnswer,
    distractors,
  }
}

// Get all choices shuffled (correct answer + distractors)
export function getShuffledChoices(question: RhymeQuestion): RhymeWord[] {
  const allChoices = [question.correctAnswer, ...question.distractors]
  return allChoices.sort(() => Math.random() - 0.5)
}

// Get questions for a level
export function getQuestionsForLevel(
  levelIndex: number,
  questionsPerLevel: number = 8
): RhymeQuestion[] {
  const level = rhymeDifficultyLevels[levelIndex]
  if (!level) return []

  const questions: RhymeQuestion[] = []
  const familyQueue = [...level.families]

  // Generate questions cycling through families
  let familyIndex = 0
  while (questions.length < questionsPerLevel) {
    const family = familyQueue[familyIndex % familyQueue.length]
    const question = generateRhymeQuestion(
      family,
      level.distractorCount,
      level.families
    )
    if (question) {
      questions.push(question)
    }
    familyIndex++
    // Safety check to avoid infinite loop
    if (familyIndex > questionsPerLevel * 2) break
  }

  // Shuffle the questions
  return questions.sort(() => Math.random() - 0.5)
}

// Get total question count across all levels
export function getTotalQuestionCount(questionsPerLevel: number = 8): number {
  return rhymeDifficultyLevels.length * questionsPerLevel
}

// Check if two words rhyme
export function doWordsRhyme(word1: RhymeWord, word2: RhymeWord): boolean {
  return word1.family === word2.family
}
