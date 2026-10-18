// Word Builder Game Logic
// Handles game state, validation, progression, and achievements

import type {
  WordFamily,
  WordFamilyWord,
} from './wordFamilies'
import {
  difficultyLevels,
  getFamiliesByLevel,
  getFamilyByEnding,
  isValidWord,
  getWordData,
  getAvailableLetters,
  getDistractorLetters,
} from './wordFamilies'

// Re-export for convenience
export {
  isValidWord,
  getWordData,
  getAvailableLetters,
  getDistractorLetters,
}
export type { WordFamily, WordFamilyWord }

// Game state types
export interface BuiltWord {
  word: string
  letter: string
  ending: string
  image: string
  timestamp: number
  stars: number // 1-3 stars based on speed/accuracy
}

export interface FamilyProgress {
  ending: string
  totalWords: number
  builtWords: string[]
  completed: boolean
}

export interface Achievement {
  id: string
  name: string
  description: string
  emoji: string
  unlocked: boolean
  unlockedAt?: number
}

export interface GameState {
  currentLevel: 1 | 2 | 3
  currentFamily: WordFamily | null
  builtWords: BuiltWord[]
  familyProgress: Map<string, FamilyProgress>
  totalStars: number
  achievements: Achievement[]
  streak: number // consecutive correct words
  sessionStartTime: number
}

// Achievement definitions
const achievementDefinitions: Omit<Achievement, 'unlocked' | 'unlockedAt'>[] = [
  {
    id: 'first-word',
    name: 'First Word!',
    description: 'Build your first word',
    emoji: '🌟',
  },
  {
    id: 'word-family-complete',
    name: 'Family Reunion',
    description: 'Complete all words in a word family',
    emoji: '👨‍👩‍👧‍👦',
  },
  {
    id: 'five-words',
    name: 'Word Builder',
    description: 'Build 5 words in one session',
    emoji: '🏗️',
  },
  {
    id: 'ten-words',
    name: 'Word Factory',
    description: 'Build 10 words in one session',
    emoji: '🏭',
  },
  {
    id: 'twenty-words',
    name: 'Word Master',
    description: 'Build 20 words in one session',
    emoji: '👑',
  },
  {
    id: 'three-streak',
    name: 'On a Roll',
    description: 'Build 3 words in a row',
    emoji: '🔥',
  },
  {
    id: 'five-streak',
    name: 'Hot Streak',
    description: 'Build 5 words in a row',
    emoji: '⚡',
  },
  {
    id: 'level-1-complete',
    name: 'Easy Expert',
    description: 'Complete all Level 1 word families',
    emoji: '🥉',
  },
  {
    id: 'level-2-complete',
    name: 'Medium Master',
    description: 'Complete all Level 2 word families',
    emoji: '🥈',
  },
  {
    id: 'level-3-complete',
    name: 'Hard Hero',
    description: 'Complete all Level 3 word families',
    emoji: '🥇',
  },
  {
    id: 'ten-stars',
    name: 'Star Collector',
    description: 'Earn 10 stars',
    emoji: '✨',
  },
  {
    id: 'fifty-stars',
    name: 'Superstar',
    description: 'Earn 50 stars',
    emoji: '🌠',
  },
]

// Create initial game state
export function createInitialState(): GameState {
  return {
    currentLevel: 1,
    currentFamily: null,
    builtWords: [],
    familyProgress: new Map(),
    totalStars: 0,
    achievements: achievementDefinitions.map((a) => ({ ...a, unlocked: false })),
    streak: 0,
    sessionStartTime: Date.now(),
  }
}

// Initialize progress for all families in a level
export function initializeLevelProgress(
  state: GameState,
  level: 1 | 2 | 3
): GameState {
  const families = getFamiliesByLevel(level)
  const newProgress = new Map(state.familyProgress)

  for (const family of families) {
    if (!newProgress.has(family.ending)) {
      newProgress.set(family.ending, {
        ending: family.ending,
        totalWords: family.words.length,
        builtWords: [],
        completed: false,
      })
    }
  }

  return { ...state, familyProgress: newProgress }
}

// Select a word family to work on
export function selectFamily(
  state: GameState,
  ending: string
): GameState {
  const family = getFamilyByEnding(ending)
  if (!family) return state
  return { ...state, currentFamily: family }
}

// Select a random incomplete family from the current level
export function selectRandomFamily(state: GameState): GameState {
  const families = getFamiliesByLevel(state.currentLevel)
  const incompleteFamilies = families.filter((f) => {
    const progress = state.familyProgress.get(f.ending)
    return !progress || !progress.completed
  })

  if (incompleteFamilies.length === 0) {
    // All families complete at this level, pick any
    const family = families[Math.floor(Math.random() * families.length)]
    return { ...state, currentFamily: family }
  }

  const family =
    incompleteFamilies[Math.floor(Math.random() * incompleteFamilies.length)]
  return { ...state, currentFamily: family }
}

// Validate and process a word attempt
export interface AttemptResult {
  success: boolean
  word?: string
  wordData?: WordFamilyWord
  stars?: number
  isDuplicate?: boolean
  newAchievements?: Achievement[]
  familyCompleted?: boolean
  levelCompleted?: boolean
}

export function attemptWord(
  state: GameState,
  letter: string,
  ending: string
): { state: GameState; result: AttemptResult } {
  // Validate the word
  if (!isValidWord(letter, ending)) {
    return {
      state: { ...state, streak: 0 },
      result: { success: false },
    }
  }

  const wordData = getWordData(letter, ending)
  if (!wordData) {
    return {
      state: { ...state, streak: 0 },
      result: { success: false },
    }
  }

  // Check for duplicate
  const progress = state.familyProgress.get(ending)
  if (progress && progress.builtWords.includes(wordData.word)) {
    return {
      state,
      result: { success: false, isDuplicate: true, word: wordData.word },
    }
  }

  // Calculate stars (1-3 based on streak)
  const newStreak = state.streak + 1
  const stars = newStreak >= 5 ? 3 : newStreak >= 3 ? 2 : 1

  // Build the word entry
  const builtWord: BuiltWord = {
    word: wordData.word,
    letter: wordData.letter,
    ending,
    image: wordData.image,
    timestamp: Date.now(),
    stars,
  }

  // Update progress for this family
  const newProgress = new Map(state.familyProgress)
  const familyProgress = newProgress.get(ending) || {
    ending,
    totalWords: getFamilyByEnding(ending)?.words.length || 0,
    builtWords: [],
    completed: false,
  }

  const updatedFamilyProgress: FamilyProgress = {
    ...familyProgress,
    builtWords: [...familyProgress.builtWords, wordData.word],
    completed:
      familyProgress.builtWords.length + 1 >= familyProgress.totalWords,
  }
  newProgress.set(ending, updatedFamilyProgress)

  // Check if level is completed
  const levelFamilies = getFamiliesByLevel(state.currentLevel)
  const levelCompleted = levelFamilies.every((f) => {
    const prog = newProgress.get(f.ending)
    return prog && prog.completed
  })

  // Update state
  let newState: GameState = {
    ...state,
    builtWords: [...state.builtWords, builtWord],
    familyProgress: newProgress,
    totalStars: state.totalStars + stars,
    streak: newStreak,
  }

  // Check for new achievements
  const newAchievements = checkAchievements(newState)
  if (newAchievements.length > 0) {
    newState = {
      ...newState,
      achievements: newState.achievements.map((a) => {
        const unlocked = newAchievements.find((na) => na.id === a.id)
        if (unlocked) {
          return { ...a, unlocked: true, unlockedAt: Date.now() }
        }
        return a
      }),
    }
  }

  return {
    state: newState,
    result: {
      success: true,
      word: wordData.word,
      wordData,
      stars,
      newAchievements,
      familyCompleted: updatedFamilyProgress.completed,
      levelCompleted,
    },
  }
}

// Check which achievements should be unlocked
function checkAchievements(state: GameState): Achievement[] {
  const newAchievements: Achievement[] = []
  const wordCount = state.builtWords.length

  for (const achievement of state.achievements) {
    if (achievement.unlocked) continue

    let shouldUnlock = false

    switch (achievement.id) {
      case 'first-word':
        shouldUnlock = wordCount >= 1
        break
      case 'five-words':
        shouldUnlock = wordCount >= 5
        break
      case 'ten-words':
        shouldUnlock = wordCount >= 10
        break
      case 'twenty-words':
        shouldUnlock = wordCount >= 20
        break
      case 'three-streak':
        shouldUnlock = state.streak >= 3
        break
      case 'five-streak':
        shouldUnlock = state.streak >= 5
        break
      case 'ten-stars':
        shouldUnlock = state.totalStars >= 10
        break
      case 'fifty-stars':
        shouldUnlock = state.totalStars >= 50
        break
      case 'word-family-complete':
        shouldUnlock = Array.from(state.familyProgress.values()).some(
          (p) => p.completed
        )
        break
      case 'level-1-complete':
        shouldUnlock = isLevelComplete(state, 1)
        break
      case 'level-2-complete':
        shouldUnlock = isLevelComplete(state, 2)
        break
      case 'level-3-complete':
        shouldUnlock = isLevelComplete(state, 3)
        break
    }

    if (shouldUnlock) {
      newAchievements.push(achievement)
    }
  }

  return newAchievements
}

// Check if all families in a level are complete
function isLevelComplete(state: GameState, level: 1 | 2 | 3): boolean {
  const families = getFamiliesByLevel(level)
  return families.every((f) => {
    const progress = state.familyProgress.get(f.ending)
    return progress && progress.completed
  })
}

// Advance to next level
export function advanceLevel(state: GameState): GameState {
  const nextLevel = Math.min(state.currentLevel + 1, 3) as 1 | 2 | 3
  let newState: GameState = { ...state, currentLevel: nextLevel, currentFamily: null }
  newState = initializeLevelProgress(newState, nextLevel)
  return selectRandomFamily(newState)
}

// Get letter choices for the current family (mix of valid and distractors)
export function getLetterChoices(
  state: GameState,
  totalChoices: number = 6
): string[] {
  if (!state.currentFamily) return []

  const validLetters = state.currentFamily.validLetters
  const progress = state.familyProgress.get(state.currentFamily.ending)

  // Filter out letters for words already built
  const availableValidLetters = validLetters.filter((letter) => {
    const word = state.currentFamily!.words.find((w) => w.letter === letter)
    return word && (!progress || !progress.builtWords.includes(word.word))
  })

  // If no valid letters left, use all valid letters
  const lettersToUse =
    availableValidLetters.length > 0 ? availableValidLetters : validLetters

  // Shuffle valid letters and limit to at most totalChoices - 1 to leave room for distractors
  const shuffledValid = [...lettersToUse].sort(() => Math.random() - 0.5)
  const maxValidToUse = Math.min(shuffledValid.length, totalChoices - 1)
  const selectedValid = shuffledValid.slice(0, maxValidToUse)

  // Calculate how many distractors to add to reach totalChoices
  const distractorCount = totalChoices - selectedValid.length
  const distractors = getDistractorLetters(
    state.currentFamily.ending,
    distractorCount
  )

  // Combine and shuffle
  const allChoices = [...selectedValid, ...distractors]
  return allChoices.sort(() => Math.random() - 0.5)
}

// Get progress summary for display
export interface ProgressSummary {
  level: number
  levelName: string
  familiesCompleted: number
  totalFamilies: number
  wordsBuilt: number
  totalWords: number
  totalStars: number
  achievementsUnlocked: number
  totalAchievements: number
}

export function getProgressSummary(state: GameState): ProgressSummary {
  const levelData = difficultyLevels.find((l) => l.level === state.currentLevel)
  const levelFamilies = getFamiliesByLevel(state.currentLevel)

  const familiesCompleted = levelFamilies.filter((f) => {
    const progress = state.familyProgress.get(f.ending)
    return progress && progress.completed
  }).length

  const totalWords = levelFamilies.reduce((sum, f) => sum + f.words.length, 0)
  const wordsBuilt = levelFamilies.reduce((sum, f) => {
    const progress = state.familyProgress.get(f.ending)
    return sum + (progress ? progress.builtWords.length : 0)
  }, 0)

  return {
    level: state.currentLevel,
    levelName: levelData?.name || 'Unknown',
    familiesCompleted,
    totalFamilies: levelFamilies.length,
    wordsBuilt,
    totalWords,
    totalStars: state.totalStars,
    achievementsUnlocked: state.achievements.filter((a) => a.unlocked).length,
    totalAchievements: state.achievements.length,
  }
}

// Get celebration messages based on result
export function getCelebrationMessage(result: AttemptResult): {
  text: string
  emoji: string
} {
  if (!result.success) {
    return { text: 'Try again!', emoji: '💪' }
  }

  if (result.levelCompleted) {
    return { text: 'Level Complete!', emoji: '🏆' }
  }

  if (result.familyCompleted) {
    return { text: 'Family Complete!', emoji: '👨‍👩‍👧‍👦' }
  }

  if (result.stars === 3) {
    return { text: 'Amazing!', emoji: '🌟' }
  }

  if (result.stars === 2) {
    return { text: 'Great Job!', emoji: '⭐' }
  }

  const messages = [
    { text: 'Nice!', emoji: '🎉' },
    { text: 'Good!', emoji: '✨' },
    { text: 'Yay!', emoji: '🎊' },
    { text: 'Super!', emoji: '💫' },
  ]

  return messages[Math.floor(Math.random() * messages.length)]
}

// Voice phrases for word pronunciation
export function getWordPronunciationPhrase(word: string): string {
  const phrases = [
    `You built ${word}!`,
    `${word}! Great job!`,
    `That's ${word}!`,
    `${word}! Excellent!`,
  ]
  return phrases[Math.floor(Math.random() * phrases.length)]
}
