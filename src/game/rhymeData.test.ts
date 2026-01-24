import { describe, it, expect } from 'vitest'
import {
  getAvailableFamilies,
  getWordsByFamily,
  getRandomWordFromFamily,
  getDistractorWords,
  generateRhymeQuestion,
  getShuffledChoices,
  getQuestionsForLevel,
  getTotalQuestionCount,
  doWordsRhyme,
  rhymeDifficultyLevels,
  type RhymeWord,
} from './rhymeData'

describe('rhymeData', () => {
  describe('getAvailableFamilies', () => {
    it('should return an array of family names', () => {
      const families = getAvailableFamilies()
      expect(Array.isArray(families)).toBe(true)
      expect(families.length).toBeGreaterThan(0)
    })

    it('should include common word families', () => {
      const families = getAvailableFamilies()
      expect(families).toContain('at')
      expect(families).toContain('an')
      expect(families).toContain('op')
    })
  })

  describe('getWordsByFamily', () => {
    it('should return words for a valid family', () => {
      const words = getWordsByFamily('at')
      expect(words.length).toBeGreaterThan(0)
      expect(words[0].family).toBe('at')
    })

    it('should return empty array for invalid family', () => {
      const words = getWordsByFamily('xyz')
      expect(words).toEqual([])
    })

    it('should be case insensitive', () => {
      const wordsLower = getWordsByFamily('at')
      const wordsUpper = getWordsByFamily('AT')
      expect(wordsLower).toEqual(wordsUpper)
    })
  })

  describe('getRandomWordFromFamily', () => {
    it('should return a word from the specified family', () => {
      const word = getRandomWordFromFamily('at')
      expect(word).not.toBeUndefined()
      expect(word?.family).toBe('at')
    })

    it('should return undefined for invalid family', () => {
      const word = getRandomWordFromFamily('xyz')
      expect(word).toBeUndefined()
    })
  })

  describe('getDistractorWords', () => {
    it('should return words from different families', () => {
      const distractors = getDistractorWords('at', 2)
      expect(distractors.length).toBe(2)
      distractors.forEach((d) => {
        expect(d.family).not.toBe('at')
      })
    })

    it('should return the requested count', () => {
      const distractors = getDistractorWords('at', 3)
      expect(distractors.length).toBe(3)
    })

    it('should not include duplicates', () => {
      const distractors = getDistractorWords('at', 5)
      const words = distractors.map((d) => d.word)
      const uniqueWords = [...new Set(words)]
      expect(words.length).toBe(uniqueWords.length)
    })
  })

  describe('generateRhymeQuestion', () => {
    it('should generate a valid question', () => {
      const question = generateRhymeQuestion('at', 2)
      expect(question).not.toBeNull()
      expect(question?.targetWord.family).toBe('at')
      expect(question?.correctAnswer.family).toBe('at')
    })

    it('should include different target and correct answer words', () => {
      const question = generateRhymeQuestion('at', 2)
      expect(question?.targetWord.word).not.toBe(question?.correctAnswer.word)
    })

    it('should include distractors from other families', () => {
      const question = generateRhymeQuestion('at', 2)
      expect(question?.distractors.length).toBe(2)
      question?.distractors.forEach((d) => {
        expect(d.family).not.toBe('at')
      })
    })

    it('should respect available families constraint', () => {
      const question = generateRhymeQuestion('at', 2, ['at', 'an'])
      question?.distractors.forEach((d) => {
        expect(['an']).toContain(d.family)
      })
    })
  })

  describe('getShuffledChoices', () => {
    it('should include the correct answer', () => {
      const question = generateRhymeQuestion('at', 2)!
      const choices = getShuffledChoices(question)
      const choiceWords = choices.map((c) => c.word)
      expect(choiceWords).toContain(question.correctAnswer.word)
    })

    it('should include all distractors', () => {
      const question = generateRhymeQuestion('at', 2)!
      const choices = getShuffledChoices(question)
      const choiceWords = choices.map((c) => c.word)
      question.distractors.forEach((d) => {
        expect(choiceWords).toContain(d.word)
      })
    })

    it('should return correct total count', () => {
      const question = generateRhymeQuestion('at', 2)!
      const choices = getShuffledChoices(question)
      expect(choices.length).toBe(3) // 1 correct + 2 distractors
    })
  })

  describe('getQuestionsForLevel', () => {
    it('should return questions for level 0', () => {
      const questions = getQuestionsForLevel(0, 4)
      expect(questions.length).toBe(4)
    })

    it('should use families from the level config', () => {
      const questions = getQuestionsForLevel(0, 4)
      const level = rhymeDifficultyLevels[0]
      questions.forEach((q) => {
        expect(level.families).toContain(q.targetWord.family)
      })
    })

    it('should return empty array for invalid level', () => {
      const questions = getQuestionsForLevel(999, 4)
      expect(questions).toEqual([])
    })
  })

  describe('getTotalQuestionCount', () => {
    it('should return correct total', () => {
      const total = getTotalQuestionCount(8)
      expect(total).toBe(rhymeDifficultyLevels.length * 8)
    })
  })

  describe('doWordsRhyme', () => {
    it('should return true for words in same family', () => {
      const word1: RhymeWord = { word: 'cat', image: '🐱', family: 'at' }
      const word2: RhymeWord = { word: 'hat', image: '🎩', family: 'at' }
      expect(doWordsRhyme(word1, word2)).toBe(true)
    })

    it('should return false for words in different families', () => {
      const word1: RhymeWord = { word: 'cat', image: '🐱', family: 'at' }
      const word2: RhymeWord = { word: 'sun', image: '☀️', family: 'un' }
      expect(doWordsRhyme(word1, word2)).toBe(false)
    })
  })

  describe('rhymeDifficultyLevels', () => {
    it('should have at least 3 levels', () => {
      expect(rhymeDifficultyLevels.length).toBeGreaterThanOrEqual(3)
    })

    it('should have Easy as first level', () => {
      expect(rhymeDifficultyLevels[0].name).toBe('Easy')
    })

    it('should have increasing difficulty', () => {
      expect(rhymeDifficultyLevels[0].families.length).toBeLessThanOrEqual(
        rhymeDifficultyLevels[1].families.length
      )
      expect(rhymeDifficultyLevels[1].families.length).toBeLessThanOrEqual(
        rhymeDifficultyLevels[2].families.length
      )
    })

    it('should have valid distractorCount', () => {
      rhymeDifficultyLevels.forEach((level) => {
        expect(level.distractorCount).toBeGreaterThanOrEqual(2)
        expect(level.distractorCount).toBeLessThanOrEqual(3)
      })
    })
  })
})
