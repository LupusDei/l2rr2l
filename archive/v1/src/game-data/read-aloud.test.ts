import { describe, it, expect } from 'vitest'
import {
  readAloudWords,
  readAloudTiers,
  getReadAloudWordsByTier,
  getRandomReadAloudWords,
  getNextWord,
  getReadAloudWordById,
  isWordMatch,
  getCategoriesForTier,
  updateProgression,
  createInitialProgression,
  isWordMastered,
  PROGRESSION_THRESHOLDS,
} from './read-aloud'
import type { DifficultyProgression, WordProgress } from './read-aloud'

describe('read-aloud word data', () => {
  describe('readAloudWords', () => {
    it('contains words from all three tiers', () => {
      const tier1 = readAloudWords.filter((w) => w.tier === 1)
      const tier2 = readAloudWords.filter((w) => w.tier === 2)
      const tier3 = readAloudWords.filter((w) => w.tier === 3)

      expect(tier1.length).toBeGreaterThan(0)
      expect(tier2.length).toBeGreaterThan(0)
      expect(tier3.length).toBeGreaterThan(0)
    })

    it('all words have required properties', () => {
      for (const word of readAloudWords) {
        expect(word.id).toBeDefined()
        expect(word.word).toBeDefined()
        expect(word.tier).toBeGreaterThanOrEqual(1)
        expect(word.tier).toBeLessThanOrEqual(3)
        expect(word.category).toBeDefined()
        expect(word.syllables).toBeGreaterThanOrEqual(1)
      }
    })

    it('all word IDs are unique', () => {
      const ids = readAloudWords.map((w) => w.id)
      const uniqueIds = new Set(ids)
      expect(uniqueIds.size).toBe(ids.length)
    })
  })

  describe('readAloudTiers', () => {
    it('has metadata for all three tiers', () => {
      expect(readAloudTiers[1]).toBeDefined()
      expect(readAloudTiers[2]).toBeDefined()
      expect(readAloudTiers[3]).toBeDefined()
    })

    it('tier metadata has correct word counts', () => {
      expect(readAloudTiers[1].wordCount).toBe(getReadAloudWordsByTier(1).length)
      expect(readAloudTiers[2].wordCount).toBe(getReadAloudWordsByTier(2).length)
      expect(readAloudTiers[3].wordCount).toBe(getReadAloudWordsByTier(3).length)
    })

    it('tier names are descriptive', () => {
      expect(readAloudTiers[1].name).toBe('Starter')
      expect(readAloudTiers[2].name).toBe('Explorer')
      expect(readAloudTiers[3].name).toBe('Champion')
    })
  })

  describe('getReadAloudWordsByTier', () => {
    it('returns only words from the specified tier', () => {
      const tier1Words = getReadAloudWordsByTier(1)
      const tier2Words = getReadAloudWordsByTier(2)
      const tier3Words = getReadAloudWordsByTier(3)

      expect(tier1Words.every((w) => w.tier === 1)).toBe(true)
      expect(tier2Words.every((w) => w.tier === 2)).toBe(true)
      expect(tier3Words.every((w) => w.tier === 3)).toBe(true)
    })
  })

  describe('getRandomReadAloudWords', () => {
    it('returns the requested number of words', () => {
      const words = getRandomReadAloudWords(5)
      expect(words.length).toBe(5)
    })

    it('filters by tier when specified', () => {
      const words = getRandomReadAloudWords(5, { tier: 1 })
      expect(words.every((w) => w.tier === 1)).toBe(true)
    })

    it('filters by category when specified', () => {
      const words = getRandomReadAloudWords(5, { category: 'cvc' })
      expect(words.every((w) => w.category === 'cvc')).toBe(true)
    })

    it('excludes specified IDs', () => {
      const excludeIds = ['ra-cat', 'ra-dog', 'ra-pig']
      const words = getRandomReadAloudWords(10, { excludeIds })
      expect(words.some((w) => excludeIds.includes(w.id))).toBe(false)
    })

    it('returns fewer words if pool is limited', () => {
      const words = getRandomReadAloudWords(1000, { tier: 1 })
      expect(words.length).toBeLessThan(1000)
      expect(words.length).toBe(getReadAloudWordsByTier(1).length)
    })
  })

  describe('getNextWord', () => {
    it('returns a word from the current tier', () => {
      const progression = createInitialProgression()
      const word = getNextWord(progression)

      expect(word).toBeDefined()
      expect(word!.tier).toBe(1)
    })

    it('excludes specified word IDs', () => {
      const progression = createInitialProgression()
      const tier1Words = getReadAloudWordsByTier(1)
      const excludeIds = tier1Words.slice(0, tier1Words.length - 1).map((w) => w.id)

      const word = getNextWord(progression, excludeIds)
      expect(word).toBeDefined()
      expect(excludeIds.includes(word!.id)).toBe(false)
    })

    it('returns null if all words excluded', () => {
      const progression = createInitialProgression()
      const tier1Words = getReadAloudWordsByTier(1)
      const allIds = tier1Words.map((w) => w.id)

      const word = getNextWord(progression, allIds)
      expect(word).toBeNull()
    })
  })

  describe('getReadAloudWordById', () => {
    it('returns the word with matching ID', () => {
      const word = getReadAloudWordById('ra-cat')
      expect(word).toBeDefined()
      expect(word!.word).toBe('cat')
    })

    it('returns undefined for non-existent ID', () => {
      const word = getReadAloudWordById('non-existent')
      expect(word).toBeUndefined()
    })
  })

  describe('isWordMatch', () => {
    it('matches exact word', () => {
      const word = getReadAloudWordById('ra-cat')!
      expect(isWordMatch(word, 'cat')).toBe(true)
    })

    it('matches case-insensitively', () => {
      const word = getReadAloudWordById('ra-cat')!
      expect(isWordMatch(word, 'CAT')).toBe(true)
      expect(isWordMatch(word, 'Cat')).toBe(true)
    })

    it('trims whitespace', () => {
      const word = getReadAloudWordById('ra-cat')!
      expect(isWordMatch(word, ' cat ')).toBe(true)
    })

    it('does not match different words', () => {
      const word = getReadAloudWordById('ra-cat')!
      expect(isWordMatch(word, 'dog')).toBe(false)
    })
  })

  describe('getCategoriesForTier', () => {
    it('returns categories present in tier 1', () => {
      const categories = getCategoriesForTier(1)
      expect(categories).toContain('cvc')
    })

    it('returns categories present in tier 2', () => {
      const categories = getCategoriesForTier(2)
      expect(categories).toContain('sight')
      expect(categories).toContain('word-family')
    })

    it('returns categories present in tier 3', () => {
      const categories = getCategoriesForTier(3)
      expect(categories).toContain('phonics')
      expect(categories).toContain('multi-syllable')
    })
  })
})

describe('difficulty progression', () => {
  describe('createInitialProgression', () => {
    it('starts at tier 1', () => {
      const progression = createInitialProgression()
      expect(progression.currentTier).toBe(1)
    })

    it('starts with zero counters', () => {
      const progression = createInitialProgression()
      expect(progression.wordsAttemptedInTier).toBe(0)
      expect(progression.correctInRow).toBe(0)
      expect(progression.incorrectInRow).toBe(0)
    })
  })

  describe('updateProgression', () => {
    it('increments correct streak on correct answer', () => {
      const initial = createInitialProgression()
      const updated = updateProgression(initial, true)

      expect(updated.correctInRow).toBe(1)
      expect(updated.incorrectInRow).toBe(0)
    })

    it('increments incorrect streak on incorrect answer', () => {
      const initial = createInitialProgression()
      const updated = updateProgression(initial, false)

      expect(updated.correctInRow).toBe(0)
      expect(updated.incorrectInRow).toBe(1)
    })

    it('resets correct streak on incorrect answer', () => {
      const initial: DifficultyProgression = {
        currentTier: 1,
        wordsAttemptedInTier: 3,
        correctInRow: 3,
        incorrectInRow: 0,
      }
      const updated = updateProgression(initial, false)

      expect(updated.correctInRow).toBe(0)
      expect(updated.incorrectInRow).toBe(1)
    })

    it('advances tier after threshold correct in a row with enough attempts', () => {
      const initial: DifficultyProgression = {
        currentTier: 1,
        wordsAttemptedInTier: PROGRESSION_THRESHOLDS.minAttemptsBeforeAdvance,
        correctInRow: PROGRESSION_THRESHOLDS.advanceThreshold - 1,
        incorrectInRow: 0,
      }
      const updated = updateProgression(initial, true)

      expect(updated.currentTier).toBe(2)
      expect(updated.wordsAttemptedInTier).toBe(0)
      expect(updated.correctInRow).toBe(0)
    })

    it('does not advance tier before minimum attempts', () => {
      const initial: DifficultyProgression = {
        currentTier: 1,
        wordsAttemptedInTier: 2,
        correctInRow: PROGRESSION_THRESHOLDS.advanceThreshold - 1,
        incorrectInRow: 0,
      }
      const updated = updateProgression(initial, true)

      expect(updated.currentTier).toBe(1)
    })

    it('does not advance past tier 3', () => {
      const initial: DifficultyProgression = {
        currentTier: 3,
        wordsAttemptedInTier: PROGRESSION_THRESHOLDS.minAttemptsBeforeAdvance,
        correctInRow: PROGRESSION_THRESHOLDS.advanceThreshold - 1,
        incorrectInRow: 0,
      }
      const updated = updateProgression(initial, true)

      expect(updated.currentTier).toBe(3)
    })

    it('decreases tier after threshold incorrect in a row', () => {
      const initial: DifficultyProgression = {
        currentTier: 2,
        wordsAttemptedInTier: 5,
        correctInRow: 0,
        incorrectInRow: PROGRESSION_THRESHOLDS.decreaseThreshold - 1,
      }
      const updated = updateProgression(initial, false)

      expect(updated.currentTier).toBe(1)
      expect(updated.wordsAttemptedInTier).toBe(0)
    })

    it('does not decrease below tier 1', () => {
      const initial: DifficultyProgression = {
        currentTier: 1,
        wordsAttemptedInTier: 5,
        correctInRow: 0,
        incorrectInRow: PROGRESSION_THRESHOLDS.decreaseThreshold - 1,
      }
      const updated = updateProgression(initial, false)

      expect(updated.currentTier).toBe(1)
    })
  })

  describe('isWordMastered', () => {
    it('returns false with insufficient attempts', () => {
      const progress: WordProgress = {
        wordId: 'ra-cat',
        attempts: 2,
        successes: 2,
        lastAttempted: new Date(),
        mastered: false,
      }
      expect(isWordMastered(progress)).toBe(false)
    })

    it('returns true with enough attempts and high success rate', () => {
      const progress: WordProgress = {
        wordId: 'ra-cat',
        attempts: 5,
        successes: 5,
        lastAttempted: new Date(),
        mastered: false,
      }
      expect(isWordMastered(progress)).toBe(true)
    })

    it('returns false with low success rate', () => {
      const progress: WordProgress = {
        wordId: 'ra-cat',
        attempts: 5,
        successes: 2,
        lastAttempted: new Date(),
        mastered: false,
      }
      expect(isWordMastered(progress)).toBe(false)
    })

    it('returns true at exactly mastery threshold', () => {
      const minAttempts = PROGRESSION_THRESHOLDS.masteryMinAttempts
      const requiredSuccesses = Math.ceil(minAttempts * PROGRESSION_THRESHOLDS.masteryRate)
      const progress: WordProgress = {
        wordId: 'ra-cat',
        attempts: minAttempts,
        successes: requiredSuccesses,
        lastAttempted: new Date(),
        mastered: false,
      }
      expect(isWordMastered(progress)).toBe(true)
    })
  })
})

describe('word categories', () => {
  it('tier 1 focuses on CVC words', () => {
    const tier1 = getReadAloudWordsByTier(1)
    const cvcCount = tier1.filter((w) => w.category === 'cvc').length
    expect(cvcCount / tier1.length).toBeGreaterThan(0.9)
  })

  it('tier 2 includes sight words and word families', () => {
    const tier2 = getReadAloudWordsByTier(2)
    const sightCount = tier2.filter((w) => w.category === 'sight').length
    const familyCount = tier2.filter((w) => w.category === 'word-family').length
    expect(sightCount).toBeGreaterThan(0)
    expect(familyCount).toBeGreaterThan(0)
  })

  it('tier 3 includes phonics and multi-syllable', () => {
    const tier3 = getReadAloudWordsByTier(3)
    const phonicsCount = tier3.filter((w) => w.category === 'phonics').length
    const multiCount = tier3.filter((w) => w.category === 'multi-syllable').length
    expect(phonicsCount).toBeGreaterThan(0)
    expect(multiCount).toBeGreaterThan(0)
  })
})
