import { describe, it, expect } from 'vitest'
import {
  prePrimerWords,
  primerWords,
  grade1Words,
  sightWordLevels,
  getWordsByLevel,
  getAllSightWords,
  getSightWordsByLevel,
  generateMemoryPairs,
  generateCardsForGrid,
  getRandomWords,
  isMatchingPair
} from './sight-words'

describe('Sight Words Data', () => {
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

    it('has no duplicate words within pre-primer', () => {
      const unique = new Set(prePrimerWords)
      expect(unique.size).toBe(prePrimerWords.length)
    })

    it('has no duplicate words within primer', () => {
      const unique = new Set(primerWords)
      expect(unique.size).toBe(primerWords.length)
    })

    it('has no duplicate words within grade 1', () => {
      const unique = new Set(grade1Words)
      expect(unique.size).toBe(grade1Words.length)
    })
  })

  describe('sightWordLevels', () => {
    it('has metadata for all three levels', () => {
      expect(sightWordLevels['pre-primer']).toBeDefined()
      expect(sightWordLevels['primer']).toBeDefined()
      expect(sightWordLevels['grade1']).toBeDefined()
    })

    it('has correct word counts in metadata', () => {
      expect(sightWordLevels['pre-primer'].wordCount).toBe(40)
      expect(sightWordLevels['primer'].wordCount).toBe(52)
      expect(sightWordLevels['grade1'].wordCount).toBe(41)
    })
  })

  describe('getWordsByLevel', () => {
    it('returns pre-primer words', () => {
      expect(getWordsByLevel('pre-primer')).toBe(prePrimerWords)
    })

    it('returns primer words', () => {
      expect(getWordsByLevel('primer')).toBe(primerWords)
    })

    it('returns grade 1 words', () => {
      expect(getWordsByLevel('grade1')).toBe(grade1Words)
    })
  })

  describe('getAllSightWords', () => {
    it('returns all 133 sight words as objects', () => {
      const all = getAllSightWords()
      expect(all).toHaveLength(133)
    })

    it('includes correct level assignment', () => {
      const all = getAllSightWords()
      const prePrimer = all.filter(w => w.level === 'pre-primer')
      const primer = all.filter(w => w.level === 'primer')
      const grade1 = all.filter(w => w.level === 'grade1')

      expect(prePrimer).toHaveLength(40)
      expect(primer).toHaveLength(52)
      expect(grade1).toHaveLength(41)
    })

    it('assigns unique IDs', () => {
      const all = getAllSightWords()
      const ids = new Set(all.map(w => w.id))
      expect(ids.size).toBe(all.length)
    })
  })

  describe('getSightWordsByLevel', () => {
    it('filters to specific level', () => {
      const primer = getSightWordsByLevel('primer')
      expect(primer).toHaveLength(52)
      expect(primer.every(w => w.level === 'primer')).toBe(true)
    })
  })

  describe('generateMemoryPairs', () => {
    it('generates correct number of cards (2 per pair)', () => {
      const cards = generateMemoryPairs('pre-primer', 6)
      expect(cards).toHaveLength(12)
    })

    it('creates matching pairs with same pairId', () => {
      const cards = generateMemoryPairs('pre-primer', 4)
      const pairIds = new Set(cards.map(c => c.pairId))
      expect(pairIds.size).toBe(4)

      // Each pairId should have exactly 2 cards
      pairIds.forEach(pairId => {
        const matching = cards.filter(c => c.pairId === pairId)
        expect(matching).toHaveLength(2)
        expect(matching[0].word).toBe(matching[1].word)
      })
    })

    it('assigns unique card IDs', () => {
      const cards = generateMemoryPairs('primer', 8)
      const ids = new Set(cards.map(c => c.id))
      expect(ids.size).toBe(cards.length)
    })

    it('limits pairs to available words', () => {
      // pre-primer only has 40 words, asking for 50 pairs
      const cards = generateMemoryPairs('pre-primer', 50)
      expect(cards).toHaveLength(80) // 40 pairs * 2
    })
  })

  describe('generateCardsForGrid', () => {
    it('generates cards for 4x3 grid (12 cards = 6 pairs)', () => {
      const cards = generateCardsForGrid('pre-primer', 4, 3)
      expect(cards).toHaveLength(12)
    })

    it('generates cards for 4x4 grid (16 cards = 8 pairs)', () => {
      const cards = generateCardsForGrid('primer', 4, 4)
      expect(cards).toHaveLength(16)
    })

    it('generates cards for 6x4 grid (24 cards = 12 pairs)', () => {
      const cards = generateCardsForGrid('grade1', 6, 4)
      expect(cards).toHaveLength(24)
    })
  })

  describe('getRandomWords', () => {
    it('returns requested number of words', () => {
      const words = getRandomWords('pre-primer', 5)
      expect(words).toHaveLength(5)
    })

    it('returns unique words', () => {
      const words = getRandomWords('primer', 10)
      const unique = new Set(words)
      expect(unique.size).toBe(10)
    })

    it('limits to available words', () => {
      const words = getRandomWords('grade1', 100)
      expect(words).toHaveLength(41)
    })
  })

  describe('isMatchingPair', () => {
    it('returns true for matching pair', () => {
      const card1 = { id: 'pair-1-a', word: 'the', pairId: 'pair-1', level: 'pre-primer' as const }
      const card2 = { id: 'pair-1-b', word: 'the', pairId: 'pair-1', level: 'pre-primer' as const }
      expect(isMatchingPair(card1, card2)).toBe(true)
    })

    it('returns false for same card', () => {
      const card = { id: 'pair-1-a', word: 'the', pairId: 'pair-1', level: 'pre-primer' as const }
      expect(isMatchingPair(card, card)).toBe(false)
    })

    it('returns false for different pairs', () => {
      const card1 = { id: 'pair-1-a', word: 'the', pairId: 'pair-1', level: 'pre-primer' as const }
      const card2 = { id: 'pair-2-a', word: 'and', pairId: 'pair-2', level: 'pre-primer' as const }
      expect(isMatchingPair(card1, card2)).toBe(false)
    })
  })
})
