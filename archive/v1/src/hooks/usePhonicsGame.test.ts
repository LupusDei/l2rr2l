import { describe, it, expect, vi, beforeEach } from 'vitest'
import { renderHook, act } from '@testing-library/react'
import { usePhonicsGame, getCelebrationMessage } from './usePhonicsGame'
import { difficultyLevels } from '../game/phonicsData'

// Mock the useVoice hook
vi.mock('./useVoice', () => ({
  useVoice: () => ({
    speak: vi.fn(),
    isSpeaking: false,
    settings: {
      encouragementEnabled: true,
    },
  }),
}))

// Mock the sounds
vi.mock('../game/sounds', () => ({
  playCorrectSound: vi.fn(),
  playWordCompleteSound: vi.fn(),
}))

describe('usePhonicsGame', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  describe('initial state', () => {
    it('starts with null current word', () => {
      const { result } = renderHook(() => usePhonicsGame())
      expect(result.current.state.currentWord).toBeNull()
    })

    it('starts with zero score', () => {
      const { result } = renderHook(() => usePhonicsGame())
      expect(result.current.state.score).toBe(0)
    })

    it('starts at level 0', () => {
      const { result } = renderHook(() => usePhonicsGame())
      expect(result.current.state.currentLevelIndex).toBe(0)
    })
  })

  describe('startGame', () => {
    it('sets the current word', () => {
      const { result } = renderHook(() => usePhonicsGame())
      act(() => {
        result.current.startGame()
      })
      expect(result.current.state.currentWord).not.toBeNull()
    })

    it('sets up choices', () => {
      const { result } = renderHook(() => usePhonicsGame())
      act(() => {
        result.current.startGame()
      })
      expect(result.current.state.choices.length).toBe(
        difficultyLevels[0].choiceCount
      )
    })

    it('includes the correct answer in choices', () => {
      const { result } = renderHook(() => usePhonicsGame())
      act(() => {
        result.current.startGame()
      })
      const correctSound = result.current.state.currentWord!.beginningSound
      expect(result.current.state.choices).toContain(correctSound)
    })

    it('resets score to 0', () => {
      const { result } = renderHook(() => usePhonicsGame())
      act(() => {
        result.current.startGame()
      })
      expect(result.current.state.score).toBe(0)
    })
  })

  describe('selectAnswer - correct', () => {
    it('increases score on correct answer', async () => {
      const { result } = renderHook(() => usePhonicsGame())
      act(() => {
        result.current.startGame()
      })

      const correctSound = result.current.state.currentWord!.beginningSound
      const initialScore = result.current.state.score

      act(() => {
        result.current.selectAnswer(correctSound)
      })

      expect(result.current.state.score).toBeGreaterThan(initialScore)
    })

    it('increases streak on correct answer', () => {
      const { result } = renderHook(() => usePhonicsGame())
      act(() => {
        result.current.startGame()
      })

      const correctSound = result.current.state.currentWord!.beginningSound
      const initialStreak = result.current.state.streak

      act(() => {
        result.current.selectAnswer(correctSound)
      })

      expect(result.current.state.streak).toBe(initialStreak + 1)
    })

    it('sets lastAnswerCorrect to true', () => {
      const { result } = renderHook(() => usePhonicsGame())
      act(() => {
        result.current.startGame()
      })

      const correctSound = result.current.state.currentWord!.beginningSound

      act(() => {
        result.current.selectAnswer(correctSound)
      })

      expect(result.current.state.lastAnswerCorrect).toBe(true)
    })

    it('shows celebration on correct answer', () => {
      const { result } = renderHook(() => usePhonicsGame())
      act(() => {
        result.current.startGame()
      })

      const correctSound = result.current.state.currentWord!.beginningSound

      act(() => {
        result.current.selectAnswer(correctSound)
      })

      expect(result.current.state.showCelebration).toBe(true)
    })
  })

  describe('selectAnswer - incorrect', () => {
    it('resets streak on wrong answer', () => {
      const { result } = renderHook(() => usePhonicsGame())
      act(() => {
        result.current.startGame()
      })

      // Answer wrong on the first question
      const wrongSound = result.current.state.choices.find(
        (c) => c !== result.current.state.currentWord!.beginningSound
      )
      if (wrongSound) {
        act(() => {
          result.current.selectAnswer(wrongSound)
        })
        expect(result.current.state.streak).toBe(0)
      }
    })

    it('increments incorrect count on wrong answer', () => {
      const { result } = renderHook(() => usePhonicsGame())
      act(() => {
        result.current.startGame()
      })

      const wrongSound = result.current.state.choices.find(
        (c) => c !== result.current.state.currentWord!.beginningSound
      )
      const initialIncorrect = result.current.state.incorrectAnswers

      if (wrongSound) {
        act(() => {
          result.current.selectAnswer(wrongSound)
        })
        expect(result.current.state.incorrectAnswers).toBe(initialIncorrect + 1)
      }
    })
  })

  describe('resetGame', () => {
    it('resets all state to initial values', () => {
      const { result } = renderHook(() => usePhonicsGame())
      act(() => {
        result.current.startGame()
      })

      // Make some progress
      const correctSound = result.current.state.currentWord!.beginningSound
      act(() => {
        result.current.selectAnswer(correctSound)
      })

      // Reset
      act(() => {
        result.current.resetGame()
      })

      expect(result.current.state.currentWord).toBeNull()
      expect(result.current.state.score).toBe(0)
      expect(result.current.state.streak).toBe(0)
      expect(result.current.state.correctAnswers).toBe(0)
      expect(result.current.state.incorrectAnswers).toBe(0)
    })
  })

  describe('getCurrentLevel', () => {
    it('returns the current difficulty level', () => {
      const { result } = renderHook(() => usePhonicsGame())
      act(() => {
        result.current.startGame()
      })

      const level = result.current.getCurrentLevel()
      expect(level).toEqual(difficultyLevels[0])
    })
  })

  describe('getProgress', () => {
    it('returns progress information', () => {
      const { result } = renderHook(() => usePhonicsGame())
      act(() => {
        result.current.startGame()
      })

      const progress = result.current.getProgress()
      expect(progress.current).toBe(1)
      expect(progress.total).toBeGreaterThan(0)
      expect(progress.percentage).toBeGreaterThanOrEqual(0)
      expect(progress.percentage).toBeLessThanOrEqual(100)
    })
  })
})

describe('getCelebrationMessage', () => {
  it('returns regular celebration for low streak', () => {
    const message = getCelebrationMessage(1)
    expect(message.isStreak).toBe(false)
    expect(message.text).toBeDefined()
    expect(message.emoji).toBeDefined()
  })

  it('returns streak celebration for streak of 3+', () => {
    const message = getCelebrationMessage(3)
    expect(message.isStreak).toBe(true)
    expect(message.text).toBe('On Fire!')
  })

  it('returns higher streak celebration for streak of 5+', () => {
    const message = getCelebrationMessage(5)
    expect(message.isStreak).toBe(true)
    expect(message.text).toBe('Unstoppable!')
  })

  it('returns champion celebration for streak of 10+', () => {
    const message = getCelebrationMessage(10)
    expect(message.isStreak).toBe(true)
    expect(message.text).toBe('Champion!')
  })
})
