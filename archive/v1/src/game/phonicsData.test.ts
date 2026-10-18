import { describe, it, expect } from 'vitest'
import {
  getAvailableSounds,
  getWordsBySound,
  difficultyLevels,
  getRandomWordFromLevel,
  getWrongChoices,
  getShuffledChoices,
  getTotalWordCount,
  getLevelWordCount,
} from './phonicsData'

describe('phonicsData', () => {
  describe('getAvailableSounds', () => {
    it('returns all available letter sounds', () => {
      const sounds = getAvailableSounds()
      expect(sounds).toContain('c')
      expect(sounds).toContain('d')
      expect(sounds).toContain('f')
      expect(sounds).toContain('s')
      expect(sounds.length).toBeGreaterThanOrEqual(10)
    })
  })

  describe('getWordsBySound', () => {
    it('returns words for a valid sound', () => {
      const words = getWordsBySound('c')
      expect(words.length).toBeGreaterThan(0)
      expect(words.every((w) => w.beginningSound === 'c')).toBe(true)
      expect(words.some((w) => w.word === 'cat')).toBe(true)
    })

    it('handles uppercase input', () => {
      const words = getWordsBySound('C')
      expect(words.length).toBeGreaterThan(0)
      expect(words.every((w) => w.beginningSound === 'c')).toBe(true)
    })

    it('returns empty array for invalid sound', () => {
      const words = getWordsBySound('x')
      expect(words).toEqual([])
    })
  })

  describe('difficultyLevels', () => {
    it('has at least 3 difficulty levels', () => {
      expect(difficultyLevels.length).toBeGreaterThanOrEqual(3)
    })

    it('each level has required properties', () => {
      difficultyLevels.forEach((level) => {
        expect(level.name).toBeDefined()
        expect(level.description).toBeDefined()
        expect(level.choiceCount).toBeGreaterThanOrEqual(3)
        expect(level.choiceCount).toBeLessThanOrEqual(4)
        expect(level.words.length).toBeGreaterThan(0)
      })
    })

    it('easy level has 3 choices', () => {
      const easyLevel = difficultyLevels.find((l) => l.name === 'Easy')
      expect(easyLevel?.choiceCount).toBe(3)
    })

    it('hard level has 4 choices', () => {
      const hardLevel = difficultyLevels.find((l) => l.name === 'Hard')
      expect(hardLevel?.choiceCount).toBe(4)
    })

    it('all words have valid structure', () => {
      difficultyLevels.forEach((level) => {
        level.words.forEach((word) => {
          expect(word.word).toBeDefined()
          expect(word.image).toBeDefined()
          expect(word.beginningSound).toBeDefined()
          expect(word.word.toLowerCase().startsWith(word.beginningSound)).toBe(
            true
          )
        })
      })
    })
  })

  describe('getRandomWordFromLevel', () => {
    it('returns a word from the specified level', () => {
      const word = getRandomWordFromLevel(0)
      const level = difficultyLevels[0]
      expect(level.words).toContainEqual(word)
    })

    it('defaults to first level for invalid index', () => {
      const word = getRandomWordFromLevel(999)
      const level = difficultyLevels[0]
      expect(level.words).toContainEqual(word)
    })
  })

  describe('getWrongChoices', () => {
    it('returns the requested number of wrong choices', () => {
      const wrong = getWrongChoices('c', 2)
      expect(wrong.length).toBe(2)
    })

    it('does not include the correct sound', () => {
      const wrong = getWrongChoices('c', 5)
      expect(wrong).not.toContain('c')
    })

    it('returns valid sounds', () => {
      const availableSounds = getAvailableSounds()
      const wrong = getWrongChoices('c', 3)
      wrong.forEach((sound) => {
        expect(availableSounds).toContain(sound)
      })
    })
  })

  describe('getShuffledChoices', () => {
    it('returns the correct total number of choices', () => {
      const choices = getShuffledChoices('c', 3)
      expect(choices.length).toBe(3)
    })

    it('includes the correct answer', () => {
      const choices = getShuffledChoices('c', 3)
      expect(choices).toContain('c')
    })

    it('contains only valid sounds', () => {
      const availableSounds = getAvailableSounds()
      const choices = getShuffledChoices('d', 4)
      choices.forEach((choice) => {
        expect(availableSounds).toContain(choice)
      })
    })

    it('has no duplicates', () => {
      const choices = getShuffledChoices('f', 4)
      const uniqueChoices = new Set(choices)
      expect(uniqueChoices.size).toBe(choices.length)
    })
  })

  describe('getTotalWordCount', () => {
    it('returns total count across all levels', () => {
      const total = getTotalWordCount()
      const manualTotal = difficultyLevels.reduce(
        (sum, level) => sum + level.words.length,
        0
      )
      expect(total).toBe(manualTotal)
      expect(total).toBeGreaterThan(0)
    })
  })

  describe('getLevelWordCount', () => {
    it('returns word count for valid level', () => {
      const count = getLevelWordCount(0)
      expect(count).toBe(difficultyLevels[0].words.length)
    })

    it('returns 0 for invalid level', () => {
      const count = getLevelWordCount(999)
      expect(count).toBe(0)
    })
  })
})
