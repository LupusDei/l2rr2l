import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { renderHook, act, waitFor } from '@testing-library/react'
import { useRhymeGame, getCelebrationMessage } from './useRhymeGame'
import { rhymeDifficultyLevels, getWordsByFamily } from '../game/rhymeData'
import * as sounds from '../game/sounds'

// Mock useVoice hook
vi.mock('./useVoice', () => ({
  useVoice: () => ({
    speak: vi.fn(),
    settings: { encouragementEnabled: true },
  }),
}))

// Mock sounds
vi.mock('../game/sounds', () => ({
  playCorrectSound: vi.fn(),
  playWordCompleteSound: vi.fn(),
}))

describe('useRhymeGame', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    vi.useFakeTimers()
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  describe('initial state', () => {
    it('should start with null current question', () => {
      const { result } = renderHook(() => useRhymeGame())
      expect(result.current.state.currentQuestion).toBeNull()
    })

    it('should start with zero score', () => {
      const { result } = renderHook(() => useRhymeGame())
      expect(result.current.state.score).toBe(0)
    })

    it('should start with zero streak', () => {
      const { result } = renderHook(() => useRhymeGame())
      expect(result.current.state.streak).toBe(0)
    })

    it('should start at level 0', () => {
      const { result } = renderHook(() => useRhymeGame())
      expect(result.current.state.currentLevelIndex).toBe(0)
    })
  })

  describe('startGame', () => {
    it('should set a current question', () => {
      const { result } = renderHook(() => useRhymeGame())

      act(() => {
        result.current.startGame()
      })

      expect(result.current.state.currentQuestion).not.toBeNull()
    })

    it('should set choices', () => {
      const { result } = renderHook(() => useRhymeGame())

      act(() => {
        result.current.startGame()
      })

      expect(result.current.state.choices.length).toBeGreaterThan(0)
    })

    it('should reset score to zero', () => {
      const { result } = renderHook(() => useRhymeGame())

      act(() => {
        result.current.startGame()
      })

      expect(result.current.state.score).toBe(0)
    })

    it('should include correct answer in choices', () => {
      const { result } = renderHook(() => useRhymeGame())

      act(() => {
        result.current.startGame()
      })

      const correctAnswer = result.current.state.currentQuestion?.correctAnswer
      const choiceWords = result.current.state.choices.map((c) => c.word)
      expect(choiceWords).toContain(correctAnswer?.word)
    })
  })

  describe('selectAnswer', () => {
    it('should increment score on correct answer', () => {
      const { result } = renderHook(() => useRhymeGame())

      act(() => {
        result.current.startGame()
      })

      const correctAnswer = result.current.state.currentQuestion!.correctAnswer

      act(() => {
        result.current.selectAnswer(correctAnswer)
      })

      expect(result.current.state.score).toBe(10)
    })

    it('should increment streak on correct answer', () => {
      const { result } = renderHook(() => useRhymeGame())

      act(() => {
        result.current.startGame()
      })

      const correctAnswer = result.current.state.currentQuestion!.correctAnswer

      act(() => {
        result.current.selectAnswer(correctAnswer)
      })

      expect(result.current.state.streak).toBe(1)
    })

    it('should reset streak on wrong answer', () => {
      const { result } = renderHook(() => useRhymeGame())

      act(() => {
        result.current.startGame()
      })

      // First get a correct answer to build streak
      const correctAnswer = result.current.state.currentQuestion!.correctAnswer
      act(() => {
        result.current.selectAnswer(correctAnswer)
      })

      // Advance timer to get next question
      act(() => {
        vi.advanceTimersByTime(2500)
      })

      // Now answer wrong with a distractor
      const wrongAnswer = result.current.state.currentQuestion!.distractors[0]
      act(() => {
        result.current.selectAnswer(wrongAnswer)
      })

      expect(result.current.state.streak).toBe(0)
    })

    it('should play correct sound on correct answer', () => {
      const { result } = renderHook(() => useRhymeGame())

      act(() => {
        result.current.startGame()
      })

      const correctAnswer = result.current.state.currentQuestion!.correctAnswer

      act(() => {
        result.current.selectAnswer(correctAnswer)
      })

      expect(sounds.playCorrectSound).toHaveBeenCalled()
    })

    it('should set lastAnswerCorrect to true on correct answer', () => {
      const { result } = renderHook(() => useRhymeGame())

      act(() => {
        result.current.startGame()
      })

      const correctAnswer = result.current.state.currentQuestion!.correctAnswer

      act(() => {
        result.current.selectAnswer(correctAnswer)
      })

      expect(result.current.state.lastAnswerCorrect).toBe(true)
    })

    it('should set lastAnswerCorrect to false on wrong answer', () => {
      const { result } = renderHook(() => useRhymeGame())

      act(() => {
        result.current.startGame()
      })

      const wrongAnswer = result.current.state.currentQuestion!.distractors[0]

      act(() => {
        result.current.selectAnswer(wrongAnswer)
      })

      expect(result.current.state.lastAnswerCorrect).toBe(false)
    })

    it('should increment correctAnswers on correct answer', () => {
      const { result } = renderHook(() => useRhymeGame())

      act(() => {
        result.current.startGame()
      })

      const correctAnswer = result.current.state.currentQuestion!.correctAnswer

      act(() => {
        result.current.selectAnswer(correctAnswer)
      })

      expect(result.current.state.correctAnswers).toBe(1)
    })

    it('should increment incorrectAnswers on wrong answer', () => {
      const { result } = renderHook(() => useRhymeGame())

      act(() => {
        result.current.startGame()
      })

      const wrongAnswer = result.current.state.currentQuestion!.distractors[0]

      act(() => {
        result.current.selectAnswer(wrongAnswer)
      })

      expect(result.current.state.incorrectAnswers).toBe(1)
    })

    it('should show celebration on correct answer', () => {
      const { result } = renderHook(() => useRhymeGame())

      act(() => {
        result.current.startGame()
      })

      const correctAnswer = result.current.state.currentQuestion!.correctAnswer

      act(() => {
        result.current.selectAnswer(correctAnswer)
      })

      expect(result.current.state.showCelebration).toBe(true)
    })
  })

  describe('streak bonus', () => {
    it('should add streak bonus to score', () => {
      const { result } = renderHook(() => useRhymeGame())

      act(() => {
        result.current.startGame()
      })

      // First correct: 10 points (no bonus)
      let correctAnswer = result.current.state.currentQuestion!.correctAnswer
      act(() => {
        result.current.selectAnswer(correctAnswer)
      })
      expect(result.current.state.score).toBe(10)

      // Advance to next question
      act(() => {
        vi.advanceTimersByTime(2500)
      })

      // Second correct: 10 + 2 = 12 points (streak bonus)
      correctAnswer = result.current.state.currentQuestion!.correctAnswer
      act(() => {
        result.current.selectAnswer(correctAnswer)
      })
      expect(result.current.state.score).toBe(22) // 10 + 12

      // Advance to next question
      act(() => {
        vi.advanceTimersByTime(2500)
      })

      // Third correct: 10 + 4 = 14 points
      correctAnswer = result.current.state.currentQuestion!.correctAnswer
      act(() => {
        result.current.selectAnswer(correctAnswer)
      })
      expect(result.current.state.score).toBe(36) // 22 + 14
    })
  })

  describe('getProgress', () => {
    it('should return progress information', () => {
      const { result } = renderHook(() => useRhymeGame())

      act(() => {
        result.current.startGame()
      })

      const progress = result.current.getProgress()

      expect(progress.current).toBe(1)
      expect(progress.total).toBeGreaterThan(0)
      expect(progress.percentage).toBeGreaterThan(0)
    })
  })

  describe('getCurrentLevel', () => {
    it('should return current level info', () => {
      const { result } = renderHook(() => useRhymeGame())

      act(() => {
        result.current.startGame()
      })

      const level = result.current.getCurrentLevel()

      expect(level).not.toBeNull()
      expect(level?.name).toBe('Easy')
    })
  })

  describe('resetGame', () => {
    it('should reset all state', () => {
      const { result } = renderHook(() => useRhymeGame())

      act(() => {
        result.current.startGame()
      })

      // Make some progress
      const correctAnswer = result.current.state.currentQuestion!.correctAnswer
      act(() => {
        result.current.selectAnswer(correctAnswer)
      })

      // Reset
      act(() => {
        result.current.resetGame()
      })

      expect(result.current.state.currentQuestion).toBeNull()
      expect(result.current.state.score).toBe(0)
      expect(result.current.state.streak).toBe(0)
      expect(result.current.state.correctAnswers).toBe(0)
    })
  })

  describe('repeatWord', () => {
    it('should not throw when no question', () => {
      const { result } = renderHook(() => useRhymeGame())

      expect(() => {
        act(() => {
          result.current.repeatWord()
        })
      }).not.toThrow()
    })
  })
})

describe('getCelebrationMessage', () => {
  it('should return regular message for low streak', () => {
    const msg = getCelebrationMessage(1)
    expect(msg.isStreak).toBe(false)
  })

  it('should return streak message for streak of 3', () => {
    const msg = getCelebrationMessage(3)
    expect(msg.isStreak).toBe(true)
    expect(msg.text).toBe('On Fire!')
  })

  it('should return streak message for streak of 5', () => {
    const msg = getCelebrationMessage(5)
    expect(msg.isStreak).toBe(true)
    expect(msg.text).toBe('Unstoppable!')
  })

  it('should return streak message for streak of 10', () => {
    const msg = getCelebrationMessage(10)
    expect(msg.isStreak).toBe(true)
    expect(msg.text).toBe('Rhyme Master!')
  })
})
