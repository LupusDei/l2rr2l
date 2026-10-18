import { describe, it, expect } from 'vitest'
import {
  wordFamilies,
  getAllWordFamilies,
  getWordFamilyById,
  getRandomWordFamilies,
  getWordFamiliesByDifficulty,
  getWordFamiliesByCategory,
  getWordFamilyByRime,
  checkWord,
  getWordByOnset,
  getWordFamiliesForGame,
  getGameOnsets,
  getValidWords,
} from './word-families'

describe('word-families', () => {
  describe('wordFamilies data', () => {
    it('should have version and description', () => {
      expect(wordFamilies.version).toBe('1.0.0')
      expect(wordFamilies.description).toBeDefined()
    })

    it('should have at least 10 word families', () => {
      expect(wordFamilies.families.length).toBeGreaterThanOrEqual(10)
    })

    it('should have all difficulty levels defined', () => {
      expect(wordFamilies.difficultyLevels['1']).toBeDefined()
      expect(wordFamilies.difficultyLevels['2']).toBeDefined()
      expect(wordFamilies.difficultyLevels['3']).toBeDefined()
    })

    it('should have all categories defined', () => {
      expect(wordFamilies.categories).toContain('short-a')
      expect(wordFamilies.categories).toContain('short-e')
      expect(wordFamilies.categories).toContain('short-i')
      expect(wordFamilies.categories).toContain('short-o')
      expect(wordFamilies.categories).toContain('short-u')
    })
  })

  describe('word family structure', () => {
    it('should have valid structure for each family', () => {
      for (const family of wordFamilies.families) {
        expect(family.id).toBeDefined()
        expect(family.rime).toBeDefined()
        expect(family.difficulty).toBeGreaterThanOrEqual(1)
        expect(family.difficulty).toBeLessThanOrEqual(3)
        expect(family.category).toBeDefined()
        expect(family.validOnsets.length).toBeGreaterThan(0)
        expect(family.words.length).toBeGreaterThan(0)
      }
    })

    it('should have matching words for valid onsets', () => {
      for (const family of wordFamilies.families) {
        for (const onset of family.validOnsets) {
          const word = family.words.find((w) => w.onset === onset)
          expect(word).toBeDefined()
          expect(word?.isReal).toBe(true)
          expect(word?.word).toBe(onset + family.rime)
        }
      }
    })

    it('should have only real words marked as real', () => {
      for (const family of wordFamilies.families) {
        for (const word of family.words) {
          if (word.isReal) {
            expect(word.word).toBe(word.onset + family.rime)
          }
        }
      }
    })
  })

  describe('getAllWordFamilies', () => {
    it('should return all families', () => {
      const families = getAllWordFamilies()
      expect(families.length).toBe(wordFamilies.families.length)
    })
  })

  describe('getWordFamilyById', () => {
    it('should find family by id', () => {
      const family = getWordFamilyById('wf-at')
      expect(family).toBeDefined()
      expect(family?.rime).toBe('at')
    })

    it('should return undefined for non-existent id', () => {
      const family = getWordFamilyById('wf-nonexistent')
      expect(family).toBeUndefined()
    })
  })

  describe('getRandomWordFamilies', () => {
    it('should return requested number of families', () => {
      const families = getRandomWordFamilies(3)
      expect(families.length).toBe(3)
    })

    it('should filter by difficulty', () => {
      const families = getRandomWordFamilies(10, { difficulty: 1 })
      for (const family of families) {
        expect(family.difficulty).toBe(1)
      }
    })

    it('should filter by category', () => {
      const families = getRandomWordFamilies(10, { category: 'short-a' })
      for (const family of families) {
        expect(family.category).toBe('short-a')
      }
    })
  })

  describe('getWordFamiliesByDifficulty', () => {
    it('should filter by difficulty level 1', () => {
      const families = getWordFamiliesByDifficulty(wordFamilies.families, 1)
      expect(families.length).toBeGreaterThan(0)
      for (const family of families) {
        expect(family.difficulty).toBe(1)
      }
    })

    it('should filter by difficulty level 2', () => {
      const families = getWordFamiliesByDifficulty(wordFamilies.families, 2)
      expect(families.length).toBeGreaterThan(0)
      for (const family of families) {
        expect(family.difficulty).toBe(2)
      }
    })

    it('should filter by difficulty level 3', () => {
      const families = getWordFamiliesByDifficulty(wordFamilies.families, 3)
      expect(families.length).toBeGreaterThan(0)
      for (const family of families) {
        expect(family.difficulty).toBe(3)
      }
    })
  })

  describe('getWordFamiliesByCategory', () => {
    it('should filter by short-a category', () => {
      const families = getWordFamiliesByCategory(wordFamilies.families, 'short-a')
      expect(families.length).toBeGreaterThan(0)
      for (const family of families) {
        expect(family.category).toBe('short-a')
      }
    })
  })

  describe('getWordFamilyByRime', () => {
    it('should find family by rime', () => {
      const family = getWordFamilyByRime(wordFamilies.families, 'at')
      expect(family).toBeDefined()
      expect(family?.id).toBe('wf-at')
    })

    it('should return undefined for non-existent rime', () => {
      const family = getWordFamilyByRime(wordFamilies.families, 'xyz')
      expect(family).toBeUndefined()
    })
  })

  describe('checkWord', () => {
    it('should return true for valid word', () => {
      expect(checkWord('at', 'c')).toBe(true) // cat
      expect(checkWord('at', 'b')).toBe(true) // bat
    })

    it('should return false for invalid word', () => {
      expect(checkWord('at', 'z')).toBe(false) // zat is not a word
    })

    it('should return false for non-existent rime', () => {
      expect(checkWord('xyz', 'c')).toBe(false)
    })
  })

  describe('getWordByOnset', () => {
    it('should find word by onset', () => {
      const family = getWordFamilyById('wf-at')!
      const word = getWordByOnset(family, 'c')
      expect(word).toBeDefined()
      expect(word?.word).toBe('cat')
    })

    it('should return undefined for non-existent onset', () => {
      const family = getWordFamilyById('wf-at')!
      const word = getWordByOnset(family, 'z')
      expect(word).toBeUndefined()
    })
  })

  describe('getValidWords', () => {
    it('should return only real words', () => {
      const family = getWordFamilyById('wf-at')!
      const validWords = getValidWords(family)
      expect(validWords.length).toBeGreaterThan(0)
      for (const word of validWords) {
        expect(word.isReal).toBe(true)
      }
    })
  })

  describe('getWordFamiliesForGame', () => {
    it('should return families with minimum words', () => {
      const families = getWordFamiliesForGame(3, undefined, 5)
      expect(families.length).toBeLessThanOrEqual(3)
      for (const family of families) {
        const validWords = family.words.filter((w) => w.isReal)
        expect(validWords.length).toBeGreaterThanOrEqual(5)
      }
    })

    it('should filter by difficulty', () => {
      const families = getWordFamiliesForGame(10, 1)
      for (const family of families) {
        expect(family.difficulty).toBe(1)
      }
    })
  })

  describe('getGameOnsets', () => {
    it('should return common consonants', () => {
      const onsets = getGameOnsets()
      expect(onsets).toContain('b')
      expect(onsets).toContain('c')
      expect(onsets).toContain('d')
      expect(onsets.length).toBeGreaterThan(10)
    })
  })

  describe('data integrity', () => {
    it('should have families in each difficulty level', () => {
      const diff1 = wordFamilies.families.filter((f) => f.difficulty === 1)
      const diff2 = wordFamilies.families.filter((f) => f.difficulty === 2)
      const diff3 = wordFamilies.families.filter((f) => f.difficulty === 3)

      expect(diff1.length).toBeGreaterThan(0)
      expect(diff2.length).toBeGreaterThan(0)
      expect(diff3.length).toBeGreaterThan(0)
    })

    it('should have all 15 word families', () => {
      expect(wordFamilies.families.length).toBe(15)
    })

    it('should have unique IDs', () => {
      const ids = wordFamilies.families.map((f) => f.id)
      const uniqueIds = new Set(ids)
      expect(uniqueIds.size).toBe(ids.length)
    })

    it('should have unique rimes', () => {
      const rimes = wordFamilies.families.map((f) => f.rime)
      const uniqueRimes = new Set(rimes)
      expect(uniqueRimes.size).toBe(rimes.length)
    })
  })
})
