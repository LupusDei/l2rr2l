import { useState, useCallback, useRef } from 'react'
import {
  type RhymeWord,
  type RhymeQuestion,
  rhymeDifficultyLevels,
  getQuestionsForLevel,
  getShuffledChoices,
  doWordsRhyme,
} from '../game/rhymeData'
import { playCorrectSound, playWordCompleteSound } from '../game/sounds'
import { useVoice } from './useVoice'

// Game state
export interface RhymeGameState {
  currentQuestion: RhymeQuestion | null
  currentLevelIndex: number
  questionIndex: number
  choices: RhymeWord[]
  score: number
  streak: number
  correctAnswers: number
  incorrectAnswers: number
  isLevelComplete: boolean
  isGameComplete: boolean
  showCelebration: boolean
  lastAnswerCorrect: boolean | null
  selectedAnswer: RhymeWord | null
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
  { streak: 10, text: 'Rhyme Master!', emoji: '🏆' },
]

// Voice encouragement phrases for correct answers
const correctPhrases = [
  (target: string, answer: string) =>
    `Great job! ${target} and ${answer} rhyme!`,
  (target: string, answer: string) =>
    `You got it! ${target} and ${answer} both end the same!`,
  () => `That's right!`,
  () => `Perfect rhyme!`,
  () => `Excellent!`,
]

// Voice phrases for level completion
const levelCompletePhrases = [
  (levelName: string) => `Amazing! You finished the ${levelName} level!`,
  () => `Level complete! You're a rhyming star!`,
  () => `Wonderful! On to the next level!`,
]

// Voice phrases for wrong answers (encouraging)
const wrongPhrases = [
  (target: string) => `Try again! What rhymes with ${target}?`,
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
  const msg =
    celebrationMessages[Math.floor(Math.random() * celebrationMessages.length)]
  return { ...msg, isStreak: false }
}

export interface UseRhymeGameReturn {
  state: RhymeGameState
  startGame: () => void
  selectAnswer: (word: RhymeWord) => void
  nextQuestion: () => void
  repeatWord: () => void
  resetGame: () => void
  getCurrentLevel: () => (typeof rhymeDifficultyLevels)[number] | null
  getProgress: () => { current: number; total: number; percentage: number }
}

const QUESTIONS_PER_LEVEL = 8

export function useRhymeGame(): UseRhymeGameReturn {
  const { speak, settings } = useVoice()
  const hasAnnouncedRef = useRef(false)

  const [state, setState] = useState<RhymeGameState>({
    currentQuestion: null,
    currentLevelIndex: 0,
    questionIndex: 0,
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

  // Store questions for current level
  const levelQuestionsRef = useRef<RhymeQuestion[]>([])

  // Start the game
  const startGame = useCallback(() => {
    hasAnnouncedRef.current = false
    levelQuestionsRef.current = getQuestionsForLevel(0, QUESTIONS_PER_LEVEL)
    const firstQuestion = levelQuestionsRef.current[0]

    if (!firstQuestion) return

    setState({
      currentQuestion: firstQuestion,
      currentLevelIndex: 0,
      questionIndex: 0,
      choices: getShuffledChoices(firstQuestion),
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
        speak(`What rhymes with ${firstQuestion.targetWord.word}?`)
      }
    }, 500)
  }, [speak])

  // Handle answer selection
  const selectAnswer = useCallback(
    (word: RhymeWord) => {
      if (!state.currentQuestion || state.showCelebration) return

      const isCorrect = doWordsRhyme(word, state.currentQuestion.targetWord)

      setState((prev) => ({
        ...prev,
        selectedAnswer: word,
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
        const level = rhymeDifficultyLevels[state.currentLevelIndex]
        const isLastQuestionInLevel =
          state.questionIndex >= levelQuestionsRef.current.length - 1
        const isLastLevel =
          state.currentLevelIndex >= rhymeDifficultyLevels.length - 1
        const gameComplete = isLastQuestionInLevel && isLastLevel

        // Voice encouragement (if enabled)
        if (settings.encouragementEnabled) {
          const phrase = getRandomPhrase(correctPhrases)
          setTimeout(() => {
            speak(
              phrase(
                state.currentQuestion!.targetWord.word,
                state.currentQuestion!.correctAnswer.word
              )
            )
          }, 300)
        }

        if (isLastQuestionInLevel) {
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
          // More questions in this level
          setState((prev) => ({
            ...prev,
            score: prev.score + pointsEarned,
            streak: newStreak,
            correctAnswers: newCorrect,
            showCelebration: true,
          }))

          // Auto-advance after celebration
          setTimeout(() => {
            const nextIndex = state.questionIndex + 1
            const nextQuestion = levelQuestionsRef.current[nextIndex]

            if (!nextQuestion) return

            setState((prev) => ({
              ...prev,
              currentQuestion: nextQuestion,
              questionIndex: nextIndex,
              choices: getShuffledChoices(nextQuestion),
              showCelebration: false,
              lastAnswerCorrect: null,
              selectedAnswer: null,
            }))

            // Announce next word
            speak(`What rhymes with ${nextQuestion.targetWord.word}?`)
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
            speak(phrase(state.currentQuestion!.targetWord.word))
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

  // Move to next question (used after level complete)
  const nextQuestion = useCallback(() => {
    if (state.isGameComplete) {
      // Game over - could restart or show final screen
      return
    }

    if (state.isLevelComplete) {
      // Move to next level
      const nextLevelIndex = state.currentLevelIndex + 1
      levelQuestionsRef.current = getQuestionsForLevel(
        nextLevelIndex,
        QUESTIONS_PER_LEVEL
      )
      const nextQ = levelQuestionsRef.current[0]

      if (!nextQ) return

      setState((prev) => ({
        ...prev,
        currentQuestion: nextQ,
        currentLevelIndex: nextLevelIndex,
        questionIndex: 0,
        choices: getShuffledChoices(nextQ),
        isLevelComplete: false,
        showCelebration: false,
        lastAnswerCorrect: null,
        selectedAnswer: null,
      }))

      speak(`What rhymes with ${nextQ.targetWord.word}?`)
    }
  }, [
    state.isGameComplete,
    state.isLevelComplete,
    state.currentLevelIndex,
    speak,
  ])

  // Repeat the current word
  const repeatWord = useCallback(() => {
    if (state.currentQuestion) {
      speak(`What rhymes with ${state.currentQuestion.targetWord.word}?`)
    }
  }, [state.currentQuestion, speak])

  // Reset the game
  const resetGame = useCallback(() => {
    hasAnnouncedRef.current = false
    levelQuestionsRef.current = []
    setState({
      currentQuestion: null,
      currentLevelIndex: 0,
      questionIndex: 0,
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
    return rhymeDifficultyLevels[state.currentLevelIndex] || null
  }, [state.currentLevelIndex])

  // Get progress through current level
  const getProgress = useCallback(() => {
    const total = levelQuestionsRef.current.length || 1
    const current = state.questionIndex + 1
    const percentage = Math.round((current / total) * 100)
    return { current, total, percentage }
  }, [state.questionIndex])

  return {
    state,
    startGame,
    selectAnswer,
    nextQuestion,
    repeatWord,
    resetGame,
    getCurrentLevel,
    getProgress,
  }
}
