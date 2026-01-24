import { describe, it, expect } from 'vitest'
import {
  prePrimerWords,
  primerWords,
  grade1Words,
  gridConfigs,
  getWordsForLevel,
  shuffleArray,
  getMemoryGameWords,
} from './sightWords'

describe('sightWords', () => {
  describe('word lists', () => {
    it('has 40 pre-primer words', () => {
      expect(prePrimerWords).toHaveLength(40)
    })

    it('has 52 primer words', () => {
      expect(primerWords).toHaveLength(52)
    })

    it('has 41 grade 1 words', () => {
      expect(grade1Words).toHaveLength(41)
    })

    it('pre-primer words all have correct level', () => {
      prePrimerWords.forEach(word => {
        expect(word.level).toBe('pre-primer')
      })
    })

    it('primer words all have correct level', () => {
      primerWords.forEach(word => {
        expect(word.level).toBe('primer')
      })
    })

    it('grade1 words all have correct level', () => {
      grade1Words.forEach(word => {
        expect(word.level).toBe('grade1')
      })
    })

    it('includes common sight words', () => {
      const prePrimerWordStrings = prePrimerWords.map(w => w.word)
      expect(prePrimerWordStrings).toContain('the')
      expect(prePrimerWordStrings).toContain('a')
      expect(prePrimerWordStrings).toContain('is')
    })
  })

  describe('gridConfigs', () => {
    it('has easy configuration (4x3 = 12 cards = 6 pairs)', () => {
      expect(gridConfigs.easy).toEqual({ rows: 3, cols: 4, pairs: 6 })
    })

    it('has medium configuration (4x4 = 16 cards = 8 pairs)', () => {
      expect(gridConfigs.medium).toEqual({ rows: 4, cols: 4, pairs: 8 })
    })

    it('has hard configuration (6x4 = 24 cards = 12 pairs)', () => {
      expect(gridConfigs.hard).toEqual({ rows: 4, cols: 6, pairs: 12 })
    })
  })

  describe('getWordsForLevel', () => {
    it('returns pre-primer words for pre-primer level', () => {
      const words = getWordsForLevel('pre-primer')
      expect(words).toBe(prePrimerWords)
    })

    it('returns primer words for primer level', () => {
      const words = getWordsForLevel('primer')
      expect(words).toBe(primerWords)
    })

    it('returns grade1 words for grade1 level', () => {
      const words = getWordsForLevel('grade1')
      expect(words).toBe(grade1Words)
    })

    it('returns pre-primer words as default', () => {
      const words = getWordsForLevel('invalid' as any)
      expect(words).toBe(prePrimerWords)
    })
  })

  describe('shuffleArray', () => {
    it('returns an array with the same length', () => {
      const original = [1, 2, 3, 4, 5]
      const shuffled = shuffleArray(original)
      expect(shuffled).toHaveLength(original.length)
    })

    it('returns an array with the same elements', () => {
      const original = [1, 2, 3, 4, 5]
      const shuffled = shuffleArray(original)
      expect(shuffled.sort()).toEqual(original.sort())
    })

    it('does not modify the original array', () => {
      const original = [1, 2, 3, 4, 5]
      const originalCopy = [...original]
      shuffleArray(original)
      expect(original).toEqual(originalCopy)
    })

    it('produces different orderings (statistically)', () => {
      const original = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
      const results = new Set<string>()

      // Run shuffle 10 times - should get different results
      for (let i = 0; i < 10; i++) {
        results.add(shuffleArray(original).join(','))
      }

      // Should have more than 1 unique result (very high probability)
      expect(results.size).toBeGreaterThan(1)
    })
  })

  describe('getMemoryGameWords', () => {
    it('returns the requested number of words', () => {
      const words = getMemoryGameWords('pre-primer', 6)
      expect(words).toHaveLength(6)
    })

    it('returns words from the correct level', () => {
      const words = getMemoryGameWords('primer', 5)
      words.forEach(word => {
        expect(word.level).toBe('primer')
      })
    })

    it('returns unique words', () => {
      const words = getMemoryGameWords('grade1', 10)
      const wordStrings = words.map(w => w.word)
      const uniqueWords = new Set(wordStrings)
      expect(uniqueWords.size).toBe(wordStrings.length)
    })

    it('can handle requesting max available words', () => {
      const words = getMemoryGameWords('pre-primer', 40)
      expect(words).toHaveLength(40)
    })
  })
})
