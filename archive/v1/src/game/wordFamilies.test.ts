import { describe, it, expect } from 'vitest'
import {
  difficultyLevels,
  getAllFamilies,
  getFamiliesByLevel,
  getFamilyByEnding,
  isValidWord,
  getWordData,
  getAvailableLetters,
  getDistractorLetters,
  getFamilyWordCount,
  getLevelWordCount,
} from './wordFamilies'

describe('wordFamilies', () => {
  describe('difficultyLevels', () => {
    it('has 3 difficulty levels', () => {
      expect(difficultyLevels.length).toBe(3)
    })

    it('has levels numbered 1, 2, 3', () => {
      expect(difficultyLevels.map((l) => l.level)).toEqual([1, 2, 3])
    })

    it('has names for each level', () => {
      expect(difficultyLevels[0].name).toBe('Easy')
      expect(difficultyLevels[1].name).toBe('Medium')
      expect(difficultyLevels[2].name).toBe('Hard')
    })

    it('has families at each level', () => {
      for (const level of difficultyLevels) {
        expect(level.families.length).toBeGreaterThan(0)
      }
    })
  })

  describe('getAllFamilies', () => {
    it('returns all word families', () => {
      const families = getAllFamilies()
      expect(families.length).toBeGreaterThan(0)

      // Should include families from all levels
      const endings = families.map((f) => f.ending)
      expect(endings).toContain('-at')
      expect(endings).toContain('-et')
      expect(endings).toContain('-ug')
    })
  })

  describe('getFamiliesByLevel', () => {
    it('returns families for level 1', () => {
      const families = getFamiliesByLevel(1)
      expect(families.length).toBeGreaterThan(0)

      // Level 1 should have -at family
      expect(families.some((f) => f.ending === '-at')).toBe(true)
    })

    it('returns families for level 2', () => {
      const families = getFamiliesByLevel(2)
      expect(families.length).toBeGreaterThan(0)

      // Level 2 should have -et family
      expect(families.some((f) => f.ending === '-et')).toBe(true)
    })

    it('returns families for level 3', () => {
      const families = getFamiliesByLevel(3)
      expect(families.length).toBeGreaterThan(0)

      // Level 3 should have -ug family
      expect(families.some((f) => f.ending === '-ug')).toBe(true)
    })
  })

  describe('getFamilyByEnding', () => {
    it('returns the correct family for -at', () => {
      const family = getFamilyByEnding('-at')
      expect(family).toBeDefined()
      expect(family?.ending).toBe('-at')
      expect(family?.validLetters).toContain('c')
      expect(family?.words.some((w) => w.word === 'cat')).toBe(true)
    })

    it('returns undefined for invalid ending', () => {
      const family = getFamilyByEnding('-xyz')
      expect(family).toBeUndefined()
    })
  })

  describe('isValidWord', () => {
    it('validates cat (c + -at)', () => {
      expect(isValidWord('c', '-at')).toBe(true)
    })

    it('validates bat (b + -at)', () => {
      expect(isValidWord('b', '-at')).toBe(true)
    })

    it('validates can (c + -an)', () => {
      expect(isValidWord('c', '-an')).toBe(true)
    })

    it('validates bug (b + -ug)', () => {
      expect(isValidWord('b', '-ug')).toBe(true)
    })

    it('rejects invalid combinations', () => {
      expect(isValidWord('x', '-at')).toBe(false)
      expect(isValidWord('q', '-an')).toBe(false)
    })

    it('is case-insensitive', () => {
      expect(isValidWord('C', '-at')).toBe(true)
      expect(isValidWord('B', '-AT')).toBe(false) // ending must be exact
    })

    it('returns false for non-existent family', () => {
      expect(isValidWord('c', '-xyz')).toBe(false)
    })
  })

  describe('getWordData', () => {
    it('returns data for cat', () => {
      const data = getWordData('c', '-at')
      expect(data).toBeDefined()
      expect(data?.word).toBe('cat')
      expect(data?.letter).toBe('c')
      expect(data?.image).toBeDefined()
    })

    it('returns data for bug', () => {
      const data = getWordData('b', '-ug')
      expect(data).toBeDefined()
      expect(data?.word).toBe('bug')
    })

    it('returns undefined for invalid word', () => {
      expect(getWordData('x', '-at')).toBeUndefined()
    })
  })

  describe('getAvailableLetters', () => {
    it('returns valid letters for -at family', () => {
      const letters = getAvailableLetters('-at')
      expect(letters).toContain('c')
      expect(letters).toContain('b')
      expect(letters).toContain('h')
      expect(letters).toContain('m')
      expect(letters.length).toBe(8) // b, c, f, h, m, p, r, s
    })

    it('returns empty array for invalid family', () => {
      const letters = getAvailableLetters('-xyz')
      expect(letters).toEqual([])
    })
  })

  describe('getDistractorLetters', () => {
    it('returns letters not in the family', () => {
      const distractors = getDistractorLetters('-at', 5)
      const validLetters = getAvailableLetters('-at')

      expect(distractors.length).toBe(5)
      for (const d of distractors) {
        expect(validLetters).not.toContain(d)
      }
    })

    it('returns different letters each time (randomized)', () => {
      const results = new Set<string>()
      for (let i = 0; i < 10; i++) {
        const distractors = getDistractorLetters('-at', 3)
        results.add(distractors.sort().join(''))
      }
      // Should have some variety (unlikely to get same 3 letters 10 times)
      expect(results.size).toBeGreaterThan(1)
    })
  })

  describe('getFamilyWordCount', () => {
    it('returns correct count for -at family', () => {
      const count = getFamilyWordCount('-at')
      expect(count).toBe(8) // bat, cat, fat, hat, mat, pat, rat, sat
    })

    it('returns 0 for invalid family', () => {
      const count = getFamilyWordCount('-xyz')
      expect(count).toBe(0)
    })
  })

  describe('getLevelWordCount', () => {
    it('returns total words for level 1', () => {
      const count = getLevelWordCount(1)
      expect(count).toBeGreaterThan(20) // Multiple families with 5-8 words each
    })

    it('returns total words for level 2', () => {
      const count = getLevelWordCount(2)
      expect(count).toBeGreaterThan(20)
    })

    it('returns total words for level 3', () => {
      const count = getLevelWordCount(3)
      expect(count).toBeGreaterThan(20)
    })
  })

  describe('word family data integrity', () => {
    it('all families have emoji', () => {
      const families = getAllFamilies()
      for (const family of families) {
        expect(family.emoji).toBeDefined()
        expect(family.emoji.length).toBeGreaterThan(0)
      }
    })

    it('all families have valid letters', () => {
      const families = getAllFamilies()
      for (const family of families) {
        expect(family.validLetters.length).toBeGreaterThan(0)
      }
    })

    it('all families have words matching valid letters', () => {
      const families = getAllFamilies()
      for (const family of families) {
        for (const word of family.words) {
          expect(family.validLetters).toContain(word.letter)
          expect(word.word).toBe(word.letter + family.ending.slice(1))
        }
      }
    })

    it('all words have images', () => {
      const families = getAllFamilies()
      for (const family of families) {
        for (const word of family.words) {
          expect(word.image).toBeDefined()
          expect(word.image.length).toBeGreaterThan(0)
        }
      }
    })
  })
})
