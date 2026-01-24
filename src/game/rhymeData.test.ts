import { describe, it, expect } from 'vitest'
import {
  getAllRhymeWords,
  getRhymeWordById,
  getWordFamilies,
  getDistractors,
  getRandomRhymeWords,
  getRhymingPair,
  generateRhymeQuestion,
  getWordFamilyStats,
  getWordsByFamily,
  getWordsByDifficulty,
  doWordsRhyme,
  getDistractorsForFamily,
} from '../game-data/rhyme'

describe('rhymeData', () => {
  describe('getAllRhymeWords', () => {
    it('returns all rhyme words', () => {
      const words = getAllRhymeWords()
      expect(words.length).toBeGreaterThanOrEqual(30)
    })

    it('all words have required properties', () => {
      const words = getAllRhymeWords()
      words.forEach((word) => {
        expect(word.id).toBeDefined()
        expect(word.word).toBeDefined()
        expect(word.wordFamily).toBeDefined()
        expect(word.difficulty).toBeGreaterThanOrEqual(1)
        expect(word.difficulty).toBeLessThanOrEqual(3)
        expect(word.emoji).toBeDefined()
      })
    })
  })

  describe('getRhymeWordById', () => {
    it('returns the correct word by ID', () => {
      const word = getRhymeWordById('cat')
      expect(word?.word).toBe('cat')
      expect(word?.wordFamily).toBe('-at')
    })

    it('returns undefined for non-existent ID', () => {
      const word = getRhymeWordById('nonexistent')
      expect(word).toBeUndefined()
    })
  })

  describe('getWordFamilies', () => {
    it('returns at least 10 word families', () => {
      const families = getWordFamilies()
      expect(families.length).toBeGreaterThanOrEqual(10)
    })

    it('includes common word families', () => {
      const families = getWordFamilies()
      expect(families).toContain('-at')
      expect(families).toContain('-an')
      expect(families).toContain('-op')
    })
  })

  describe('getDistractors', () => {
    it('returns distractor words', () => {
      const distractors = getDistractors()
      expect(distractors.length).toBeGreaterThan(0)
    })

    it('distractors have confusedWith property', () => {
      const distractors = getDistractors()
      distractors.forEach((d) => {
        expect(d.confusedWith).toBeDefined()
        expect(Array.isArray(d.confusedWith)).toBe(true)
        expect(d.confusedWith.length).toBeGreaterThan(0)
      })
    })
  })

  describe('getWordsByFamily', () => {
    it('returns words for a valid word family', () => {
      const words = getWordsByFamily(getAllRhymeWords(), '-at')
      expect(words.length).toBeGreaterThan(0)
      expect(words.every((w) => w.wordFamily === '-at')).toBe(true)
    })

    it('returns empty array for invalid family', () => {
      const words = getWordsByFamily(getAllRhymeWords(), '-xyz')
      expect(words).toEqual([])
    })
  })

  describe('getWordsByDifficulty', () => {
    it('returns words at or below specified difficulty', () => {
      const words = getWordsByDifficulty(getAllRhymeWords(), 1)
      expect(words.length).toBeGreaterThan(0)
      expect(words.every((w) => w.difficulty <= 1)).toBe(true)
    })

    it('higher difficulty includes more words', () => {
      const easy = getWordsByDifficulty(getAllRhymeWords(), 1)
      const medium = getWordsByDifficulty(getAllRhymeWords(), 2)
      const hard = getWordsByDifficulty(getAllRhymeWords(), 3)
      expect(medium.length).toBeGreaterThanOrEqual(easy.length)
      expect(hard.length).toBeGreaterThanOrEqual(medium.length)
    })
  })

  describe('doWordsRhyme', () => {
    it('returns true for words in same family', () => {
      const cat = getRhymeWordById('cat')!
      const hat = getRhymeWordById('hat')!
      expect(doWordsRhyme(cat, hat)).toBe(true)
    })

    it('returns false for words in different families', () => {
      const cat = getRhymeWordById('cat')!
      const hop = getRhymeWordById('hop')!
      expect(doWordsRhyme(cat, hop)).toBe(false)
    })

    it('returns false for same word', () => {
      const cat = getRhymeWordById('cat')!
      expect(doWordsRhyme(cat, cat)).toBe(false)
    })
  })

  describe('getRandomRhymeWords', () => {
    it('returns requested number of words', () => {
      const words = getRandomRhymeWords(5)
      expect(words.length).toBe(5)
    })

    it('filters by difficulty', () => {
      const words = getRandomRhymeWords(10, { difficulty: 1 })
      expect(words.every((w) => w.difficulty <= 1)).toBe(true)
    })

    it('filters by word family', () => {
      const words = getRandomRhymeWords(3, { wordFamily: '-at' })
      expect(words.every((w) => w.wordFamily === '-at')).toBe(true)
    })
  })

  describe('getRhymingPair', () => {
    it('returns two words that rhyme', () => {
      const pair = getRhymingPair()
      expect(pair).not.toBeNull()
      if (pair) {
        expect(pair[0].wordFamily).toBe(pair[1].wordFamily)
        expect(pair[0].id).not.toBe(pair[1].id)
      }
    })

    it('respects difficulty filter', () => {
      const pair = getRhymingPair(1)
      expect(pair).not.toBeNull()
      if (pair) {
        expect(pair[0].difficulty).toBeLessThanOrEqual(1)
        expect(pair[1].difficulty).toBeLessThanOrEqual(1)
      }
    })
  })

  describe('generateRhymeQuestion', () => {
    it('generates a valid question', () => {
      const question = generateRhymeQuestion(1, 2)
      expect(question).not.toBeNull()
      if (question) {
        expect(question.targetWord).toBeDefined()
        expect(question.correctAnswer).toBeDefined()
        expect(question.distractors.length).toBe(2)
        expect(question.allOptions.length).toBe(3)
      }
    })

    it('correct answer rhymes with target', () => {
      const question = generateRhymeQuestion(2, 2)
      if (question) {
        expect(question.targetWord.wordFamily).toBe(
          question.correctAnswer.wordFamily
        )
      }
    })

    it('distractors do not rhyme with target', () => {
      const question = generateRhymeQuestion(2, 2)
      if (question) {
        question.distractors.forEach((d) => {
          if ('wordFamily' in d) {
            expect(d.wordFamily).not.toBe(question.targetWord.wordFamily)
          }
        })
      }
    })

    it('allOptions includes correct answer', () => {
      const question = generateRhymeQuestion(1, 2)
      if (question) {
        expect(question.allOptions).toContainEqual(question.correctAnswer)
      }
    })
  })

  describe('getDistractorsForFamily', () => {
    it('returns distractors confused with the family', () => {
      const distractors = getDistractorsForFamily(getDistractors(), '-at')
      distractors.forEach((d) => {
        expect(d.confusedWith).toContain('-at')
      })
    })

    it('filters by difficulty', () => {
      const distractors = getDistractorsForFamily(getDistractors(), '-ot', 1)
      distractors.forEach((d) => {
        expect(d.difficulty).toBeLessThanOrEqual(1)
      })
    })
  })

  describe('getWordFamilyStats', () => {
    it('returns stats for all families', () => {
      const stats = getWordFamilyStats()
      const families = getWordFamilies()
      expect(stats.length).toBe(families.length)
    })

    it('each stat has correct structure', () => {
      const stats = getWordFamilyStats()
      stats.forEach((stat) => {
        expect(stat.family).toBeDefined()
        expect(stat.count).toBeGreaterThan(0)
        expect(Array.isArray(stat.difficulties)).toBe(true)
      })
    })
  })

  describe('data integrity', () => {
    it('has at least 30 rhyming pairs', () => {
      const words = getAllRhymeWords()
      // Count pairs: for each family with n words, there are n*(n-1)/2 pairs
      const families = getWordFamilies()
      let pairCount = 0
      families.forEach((family) => {
        const wordsInFamily = words.filter((w) => w.wordFamily === family)
        const n = wordsInFamily.length
        pairCount += (n * (n - 1)) / 2
      })
      expect(pairCount).toBeGreaterThanOrEqual(30)
    })

    it('all word IDs are unique', () => {
      const words = getAllRhymeWords()
      const ids = words.map((w) => w.id)
      const uniqueIds = new Set(ids)
      expect(uniqueIds.size).toBe(words.length)
    })

    it('words end with their word family', () => {
      const words = getAllRhymeWords()
      words.forEach((word) => {
        const familySuffix = word.wordFamily.replace('-', '')
        expect(word.word.endsWith(familySuffix)).toBe(true)
      })
    })
  })
})
