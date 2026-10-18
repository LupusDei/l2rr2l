import { useState, useCallback, useRef } from 'react'
import {
  type PhonicsWord,
  difficultyLevels,
  getShuffledChoices,
} from '../game/phonicsData'
import { playCorrectSound, playWordCompleteSound } from '../game/sounds'
import { useVoice } from './useVoice'

// Game state
export interface PhonicsGameState {
  currentWord: PhonicsWord | null
  currentLevelIndex: number
  levelWordIndex: number
  choices: string[]
  score: number
  streak: number
  correctAnswers: number
  incorrectAnswers: number
  isLevelComplete: boolean
  isGameComplete: boolean
  showCelebration: boolean
  lastAnswerCorrect: boolean | null
  selectedAnswer: string | null
}

// Celebration messages
const celebrationMessages = [
  { text: 'Great Job!', emoji: '🎉' },
  { text: 'Amazing!', emoji: '🌟' },
  { text: 'Awesome!', emoji: '✨' },
  { text: 'Super!', emoji: '🚀' },
  { text: 'Fantastic!', emoji: '💫' },
  { text: 'Wonderful!', emoji: '🎊' },
]

// Streak messages
const streakMessages = [
  { streak: 3, text: 'On Fire!', emoji: '🔥' },
  { streak: 5, text: 'Unstoppable!', emoji: '⚡' },
  { streak: 7, text: 'Legendary!', emoji: '👑' },
  { streak: 10, text: 'Champion!', emoji: '🏆' },
]

// Voice encouragement phrases for correct answers
const correctPhrases = [
  (word: string) => `Great job! ${word} starts with ${word[0]}!`,
  (word: string) => `You got it! ${word[0]} for ${word}!`,
  () => `That's right!`,
  () => `Perfect!`,
  () => `Excellent!`,
]

// Voice phrases for level completion
const levelCompletePhrases = [
  (levelName: string) => `Amazing! You finished the ${levelName} level!`,
  () => `Level complete! You're a phonics star!`,
  () => `Wonderful! On to the next level!`,
]

// Voice phrases for wrong answers (encouraging)
const wrongPhrases = [
  (word: string) => `Try again! What sound does ${word} start with?`,
  () => `Almost! Give it another try!`,
  () => `Keep trying! You can do it!`,
]

function getRandomPhrase<T>(phrases: T[]): T {
  return phrases[Math.floor(Math.random() * phrases.length)]
}

export function getCelebrationMessage(streak: number): {
  text: string
  emoji: string
  isStreak: boolean
} {
  // Check for streak celebrations first
  const streakMsg = [...streakMessages].reverse().find((s) => streak >= s.streak)
  if (streakMsg) {
    return { text: streakMsg.text, emoji: streakMsg.emoji, isStreak: true }
  }
  // Random regular celebration
  const msg = celebrationMessages[Math.floor(Math.random() * celebrationMessages.length)]
  return { ...msg, isStreak: false }
}

export interface UsePhonicsGameReturn {
  state: PhonicsGameState
  startGame: () => void
  selectAnswer: (letter: string) => void
  nextWord: () => void
  repeatWord: () => void
  resetGame: () => void
  getCurrentLevel: () => typeof difficultyLevels[number] | null
  getProgress: () => { current: number; total: number; percentage: number }
}

export function usePhonicsGame(): UsePhonicsGameReturn {
  const { speak, settings } = useVoice()
  const hasAnnouncedRef = useRef(false)

  const [state, setState] = useState<PhonicsGameState>({
    currentWord: null,
    currentLevelIndex: 0,
    levelWordIndex: 0,
    choices: [],
    score: 0,
    streak: 0,
    correctAnswers: 0,
    incorrectAnswers: 0,
    isLevelComplete: false,
    isGameComplete: false,
    showCelebration: false,
    lastAnswerCorrect: null,
    selectedAnswer: null,
  })

  // Get shuffled words for a level (call once per level)
  const getShuffledLevelWords = useCallback((levelIndex: number) => {
    const level = difficultyLevels[levelIndex]
    if (!level) return []
    return [...level.words].sort(() => Math.random() - 0.5)
  }, [])

  // Store shuffled words for current level
  const levelWordsRef = useRef<PhonicsWord[]>([])

  // Start the game
  const startGame = useCallback(() => {
    hasAnnouncedRef.current = false
    levelWordsRef.current = getShuffledLevelWords(0)
    const firstWord = levelWordsRef.current[0]
    const level = difficultyLevels[0]

    setState({
      currentWord: firstWord,
      currentLevelIndex: 0,
      levelWordIndex: 0,
      choices: getShuffledChoices(firstWord.beginningSound, level.choiceCount),
      score: 0,
      streak: 0,
      correctAnswers: 0,
      incorrectAnswers: 0,
      isLevelComplete: false,
      isGameComplete: false,
      showCelebration: false,
      lastAnswerCorrect: null,
      selectedAnswer: null,
    })

    // Announce the first word after a short delay
    setTimeout(() => {
      if (!hasAnnouncedRef.current) {
        hasAnnouncedRef.current = true
        speak(`What sound does ${firstWord.word} start with?`)
      }
    }, 500)
  }, [getShuffledLevelWords, speak])

  // Handle answer selection
  const selectAnswer = useCallback(
    (letter: string) => {
      if (!state.currentWord || state.showCelebration) return

      const isCorrect =
        letter.toLowerCase() === state.currentWord.beginningSound.toLowerCase()

      setState((prev) => ({
        ...prev,
        selectedAnswer: letter,
        lastAnswerCorrect: isCorrect,
      }))

      if (isCorrect) {
        // Correct answer!
        playCorrectSound()

        const newStreak = state.streak + 1
        const newCorrect = state.correctAnswers + 1

        // Calculate score: base points + streak bonus
        const basePoints = 10
        const streakBonus = Math.min(newStreak - 1, 5) * 2 // Up to 10 bonus points
        const pointsEarned = basePoints + streakBonus

        // Check if level is complete
        const level = difficultyLevels[state.currentLevelIndex]
        const isLastWordInLevel =
          state.levelWordIndex >= levelWordsRef.current.length - 1
        const isLastLevel =
          state.currentLevelIndex >= difficultyLevels.length - 1
        const gameComplete = isLastWordInLevel && isLastLevel

        // Voice encouragement (if enabled)
        if (settings.encouragementEnabled) {
          const phrase = getRandomPhrase(correctPhrases)
          setTimeout(() => {
            speak(phrase(state.currentWord!.word))
          }, 300)
        }

        if (isLastWordInLevel) {
          // Level or game complete!
          playWordCompleteSound()

          setState((prev) => ({
            ...prev,
            score: prev.score + pointsEarned,
            streak: newStreak,
            correctAnswers: newCorrect,
            isLevelComplete: true,
            isGameComplete: gameComplete,
            showCelebration: true,
          }))

          // Level complete voice
          setTimeout(() => {
            const phrase = getRandomPhrase(levelCompletePhrases)
            speak(phrase(level.name))
          }, 800)
        } else {
          // More words in this level
          setState((prev) => ({
            ...prev,
            score: prev.score + pointsEarned,
            streak: newStreak,
            correctAnswers: newCorrect,
            showCelebration: true,
          }))

          // Auto-advance after celebration
          setTimeout(() => {
            const nextIndex = state.levelWordIndex + 1
            const nextWord = levelWordsRef.current[nextIndex]
            const choices = getShuffledChoices(
              nextWord.beginningSound,
              level.choiceCount
            )

            setState((prev) => ({
              ...prev,
              currentWord: nextWord,
              levelWordIndex: nextIndex,
              choices,
              showCelebration: false,
              lastAnswerCorrect: null,
              selectedAnswer: null,
            }))

            // Announce next word
            speak(`What sound does ${nextWord.word} start with?`)
          }, 2000)
        }
      } else {
        // Wrong answer
        setState((prev) => ({
          ...prev,
          streak: 0,
          incorrectAnswers: prev.incorrectAnswers + 1,
        }))

        // Voice encouragement for wrong answer
        if (settings.encouragementEnabled) {
          const phrase = getRandomPhrase(wrongPhrases)
          setTimeout(() => {
            speak(phrase(state.currentWord!.word))
          }, 300)
        }

        // Clear the wrong selection after a moment so they can try again
        setTimeout(() => {
          setState((prev) => ({
            ...prev,
            lastAnswerCorrect: null,
            selectedAnswer: null,
          }))
        }, 1000)
      }
    },
    [state, settings.encouragementEnabled, speak]
  )

  // Move to next word (used after level complete)
  const nextWord = useCallback(() => {
    if (state.isGameComplete) {
      // Game over - could restart or show final screen
      return
    }

    if (state.isLevelComplete) {
      // Move to next level
      const nextLevelIndex = state.currentLevelIndex + 1
      levelWordsRef.current = getShuffledLevelWords(nextLevelIndex)
      const nextWord = levelWordsRef.current[0]
      const level = difficultyLevels[nextLevelIndex]

      setState((prev) => ({
        ...prev,
        currentWord: nextWord,
        currentLevelIndex: nextLevelIndex,
        levelWordIndex: 0,
        choices: getShuffledChoices(nextWord.beginningSound, level.choiceCount),
        isLevelComplete: false,
        showCelebration: false,
        lastAnswerCorrect: null,
        selectedAnswer: null,
      }))

      speak(`What sound does ${nextWord.word} start with?`)
    }
  }, [state.isGameComplete, state.isLevelComplete, state.currentLevelIndex, getShuffledLevelWords, speak])

  // Repeat the current word
  const repeatWord = useCallback(() => {
    if (state.currentWord) {
      speak(`What sound does ${state.currentWord.word} start with?`)
    }
  }, [state.currentWord, speak])

  // Reset the game
  const resetGame = useCallback(() => {
    hasAnnouncedRef.current = false
    levelWordsRef.current = []
    setState({
      currentWord: null,
      currentLevelIndex: 0,
      levelWordIndex: 0,
      choices: [],
      score: 0,
      streak: 0,
      correctAnswers: 0,
      incorrectAnswers: 0,
      isLevelComplete: false,
      isGameComplete: false,
      showCelebration: false,
      lastAnswerCorrect: null,
      selectedAnswer: null,
    })
  }, [])

  // Get current level info
  const getCurrentLevel = useCallback(() => {
    return difficultyLevels[state.currentLevelIndex] || null
  }, [state.currentLevelIndex])

  // Get progress through current level
  const getProgress = useCallback(() => {
    const total = levelWordsRef.current.length || 1
    const current = state.levelWordIndex + 1
    const percentage = Math.round((current / total) * 100)
    return { current, total, percentage }
  }, [state.levelWordIndex])

  return {
    state,
    startGame,
    selectAnswer,
    nextWord,
    repeatWord,
    resetGame,
    getCurrentLevel,
    getProgress,
  }
}
