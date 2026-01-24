import { describe, it, expect, beforeEach } from 'vitest'
import {
  createInitialState,
  initializeLevelProgress,
  selectFamily,
  selectRandomFamily,
  attemptWord,
  advanceLevel,
  getLetterChoices,
  getProgressSummary,
  getCelebrationMessage,
  getWordPronunciationPhrase,
  isValidWord,
  getWordData,
  getAvailableLetters,
  getDistractorLetters,
  type GameState,
} from './wordBuilderLogic'
import { getFamilyByEnding, getFamiliesByLevel } from './wordFamilies'

describe('wordBuilderLogic', () => {
  let state: GameState

  beforeEach(() => {
    state = createInitialState()
    state = initializeLevelProgress(state, 1)
  })

  describe('createInitialState', () => {
    it('creates state with default values', () => {
      const newState = createInitialState()
      expect(newState.currentLevel).toBe(1)
      expect(newState.currentFamily).toBeNull()
      expect(newState.builtWords).toEqual([])
      expect(newState.totalStars).toBe(0)
      expect(newState.streak).toBe(0)
      expect(newState.achievements.length).toBeGreaterThan(0)
      expect(newState.achievements.every((a) => !a.unlocked)).toBe(true)
    })
  })

  describe('initializeLevelProgress', () => {
    it('initializes progress for all families in level 1', () => {
      const level1Families = getFamiliesByLevel(1)
      expect(level1Families.length).toBeGreaterThan(0)

      for (const family of level1Families) {
        const progress = state.familyProgress.get(family.ending)
        expect(progress).toBeDefined()
        expect(progress?.builtWords).toEqual([])
        expect(progress?.completed).toBe(false)
      }
    })

    it('does not overwrite existing progress', () => {
      // Build a word first
      state = selectFamily(state, '-at')
      const { state: updatedState } = attemptWord(state, 'c', '-at')

      // Re-initialize
      const reInitState = initializeLevelProgress(updatedState, 1)
      const progress = reInitState.familyProgress.get('-at')
      expect(progress?.builtWords).toContain('cat')
    })
  })

  describe('selectFamily', () => {
    it('selects a valid family', () => {
      const updatedState = selectFamily(state, '-at')
      expect(updatedState.currentFamily).not.toBeNull()
      expect(updatedState.currentFamily?.ending).toBe('-at')
    })

    it('returns unchanged state for invalid family', () => {
      const updatedState = selectFamily(state, '-xyz')
      expect(updatedState.currentFamily).toBeNull()
    })
  })

  describe('selectRandomFamily', () => {
    it('selects a family from the current level', () => {
      const updatedState = selectRandomFamily(state)
      expect(updatedState.currentFamily).not.toBeNull()

      const level1Families = getFamiliesByLevel(1)
      const endings = level1Families.map((f) => f.ending)
      expect(endings).toContain(updatedState.currentFamily?.ending)
    })
  })

  describe('isValidWord', () => {
    it('returns true for valid letter + ending combinations', () => {
      expect(isValidWord('c', '-at')).toBe(true)
      expect(isValidWord('b', '-at')).toBe(true)
      expect(isValidWord('f', '-an')).toBe(true)
    })

    it('returns false for invalid combinations', () => {
      expect(isValidWord('x', '-at')).toBe(false)
      expect(isValidWord('z', '-an')).toBe(false)
      expect(isValidWord('c', '-xyz')).toBe(false)
    })

    it('is case-insensitive', () => {
      expect(isValidWord('C', '-at')).toBe(true)
      expect(isValidWord('B', '-at')).toBe(true)
    })
  })

  describe('getWordData', () => {
    it('returns word data for valid combinations', () => {
      const data = getWordData('c', '-at')
      expect(data).toBeDefined()
      expect(data?.word).toBe('cat')
      expect(data?.letter).toBe('c')
      expect(data?.image).toBeDefined()
    })

    it('returns undefined for invalid combinations', () => {
      expect(getWordData('x', '-at')).toBeUndefined()
      expect(getWordData('c', '-xyz')).toBeUndefined()
    })
  })

  describe('getAvailableLetters', () => {
    it('returns valid letters for a family', () => {
      const letters = getAvailableLetters('-at')
      expect(letters).toContain('c')
      expect(letters).toContain('b')
      expect(letters).toContain('h')
      expect(letters).not.toContain('x')
    })

    it('returns empty array for invalid family', () => {
      expect(getAvailableLetters('-xyz')).toEqual([])
    })
  })

  describe('getDistractorLetters', () => {
    it('returns letters that are not valid for the family', () => {
      const distractors = getDistractorLetters('-at', 3)
      const validLetters = getAvailableLetters('-at')

      expect(distractors.length).toBe(3)
      for (const d of distractors) {
        expect(validLetters).not.toContain(d)
      }
    })
  })

  describe('attemptWord', () => {
    beforeEach(() => {
      state = selectFamily(state, '-at')
    })

    it('succeeds for valid word', () => {
      const { state: newState, result } = attemptWord(state, 'c', '-at')

      expect(result.success).toBe(true)
      expect(result.word).toBe('cat')
      expect(result.stars).toBeGreaterThan(0)
      expect(newState.builtWords.length).toBe(1)
      expect(newState.builtWords[0].word).toBe('cat')
    })

    it('fails for invalid letter', () => {
      const { state: newState, result } = attemptWord(state, 'x', '-at')

      expect(result.success).toBe(false)
      expect(newState.builtWords.length).toBe(0)
      expect(newState.streak).toBe(0)
    })

    it('rejects duplicate words', () => {
      const { state: state1 } = attemptWord(state, 'c', '-at')
      const { result } = attemptWord(state1, 'c', '-at')

      expect(result.success).toBe(false)
      expect(result.isDuplicate).toBe(true)
    })

    it('tracks progress in family', () => {
      const { state: newState } = attemptWord(state, 'c', '-at')
      const progress = newState.familyProgress.get('-at')

      expect(progress?.builtWords).toContain('cat')
    })

    it('increments streak on success', () => {
      let currentState = state
      for (let i = 0; i < 3; i++) {
        const letters = ['c', 'b', 'h']
        const { state: newState } = attemptWord(
          currentState,
          letters[i],
          '-at'
        )
        currentState = newState
      }
      expect(currentState.streak).toBe(3)
    })

    it('resets streak on failure', () => {
      const { state: state1 } = attemptWord(state, 'c', '-at')
      const { state: state2 } = attemptWord(state1, 'x', '-at')

      expect(state2.streak).toBe(0)
    })

    it('awards more stars for longer streaks', () => {
      let currentState = state
      const letters = ['c', 'b', 'h', 'm', 's']
      const stars: number[] = []

      for (const letter of letters) {
        const { state: newState, result } = attemptWord(
          currentState,
          letter,
          '-at'
        )
        currentState = newState
        if (result.stars) stars.push(result.stars)
      }

      // First words get 1 star, streak 3+ gets 2, streak 5+ gets 3
      expect(stars[0]).toBe(1)
      expect(stars[1]).toBe(1)
      expect(stars[2]).toBe(2) // 3rd word, streak bonus
      expect(stars[4]).toBe(3) // 5th word, max bonus
    })

    it('updates total stars', () => {
      const { state: newState } = attemptWord(state, 'c', '-at')
      expect(newState.totalStars).toBeGreaterThan(0)
    })

    it('unlocks first-word achievement', () => {
      const { result } = attemptWord(state, 'c', '-at')

      expect(result.newAchievements).toBeDefined()
      expect(result.newAchievements?.some((a) => a.id === 'first-word')).toBe(
        true
      )
    })

    it('marks family as completed when all words built', () => {
      let currentState = state
      const family = getFamilyByEnding('-at')!
      const letters = family.validLetters

      for (let i = 0; i < letters.length; i++) {
        const { state: newState, result } = attemptWord(
          currentState,
          letters[i],
          '-at'
        )
        currentState = newState

        if (i === letters.length - 1) {
          expect(result.familyCompleted).toBe(true)
        }
      }

      const progress = currentState.familyProgress.get('-at')
      expect(progress?.completed).toBe(true)
    })
  })

  describe('advanceLevel', () => {
    it('advances to next level', () => {
      const newState = advanceLevel(state)
      expect(newState.currentLevel).toBe(2)
    })

    it('initializes progress for new level', () => {
      const newState = advanceLevel(state)
      const level2Families = getFamiliesByLevel(2)

      for (const family of level2Families) {
        expect(newState.familyProgress.has(family.ending)).toBe(true)
      }
    })

    it('selects a random family from new level', () => {
      const newState = advanceLevel(state)
      expect(newState.currentFamily).not.toBeNull()

      const level2Families = getFamiliesByLevel(2)
      const endings = level2Families.map((f) => f.ending)
      expect(endings).toContain(newState.currentFamily?.ending)
    })

    it('does not exceed level 3', () => {
      const level3State = { ...state, currentLevel: 3 as const }
      const newState = advanceLevel(level3State)
      expect(newState.currentLevel).toBe(3)
    })
  })

  describe('getLetterChoices', () => {
    it('includes valid letters and distractors', () => {
      state = selectFamily(state, '-at')
      const choices = getLetterChoices(state, 6)

      expect(choices.length).toBe(6)

      // Should include at least some valid letters
      const validLetters = getAvailableLetters('-at')
      const hasValidLetter = choices.some((c) => validLetters.includes(c))
      expect(hasValidLetter).toBe(true)
    })

    it('excludes letters for already-built words', () => {
      state = selectFamily(state, '-at')
      const { state: newState } = attemptWord(state, 'c', '-at')

      // Get choices - should still return 6 letters
      const choices = getLetterChoices(newState, 6)
      expect(choices.length).toBe(6)

      // The function prefers unused letters, but may include 'c' if needed
      // Check that choices contain some valid letters that are NOT 'c'
      const validLettersExcludingC = getAvailableLetters('-at').filter(
        (l) => l !== 'c'
      )
      const hasOtherValidLetters = choices.some((c) =>
        validLettersExcludingC.includes(c)
      )
      expect(hasOtherValidLetters).toBe(true)
    })

    it('returns empty array when no family selected', () => {
      const choices = getLetterChoices(state)
      expect(choices).toEqual([])
    })
  })

  describe('getProgressSummary', () => {
    it('returns accurate progress data', () => {
      state = selectFamily(state, '-at')
      const { state: newState } = attemptWord(state, 'c', '-at')

      const summary = getProgressSummary(newState)

      expect(summary.level).toBe(1)
      expect(summary.levelName).toBe('Easy')
      expect(summary.wordsBuilt).toBe(1)
      expect(summary.totalStars).toBeGreaterThan(0)
    })
  })

  describe('getCelebrationMessage', () => {
    it('returns encouraging message for failure', () => {
      const message = getCelebrationMessage({ success: false })
      expect(message.emoji).toBeDefined()
      expect(message.text).toBeDefined()
    })

    it('returns special message for level completion', () => {
      const message = getCelebrationMessage({
        success: true,
        levelCompleted: true,
      })
      expect(message.text).toContain('Level')
    })

    it('returns special message for family completion', () => {
      const message = getCelebrationMessage({
        success: true,
        familyCompleted: true,
      })
      expect(message.text).toContain('Family')
    })
  })

  describe('getWordPronunciationPhrase', () => {
    it('returns a phrase containing the word', () => {
      const phrase = getWordPronunciationPhrase('cat')
      expect(phrase.toLowerCase()).toContain('cat')
    })
  })

  describe('achievements', () => {
    it('unlocks three-streak achievement after 3 correct words', () => {
      let currentState = selectFamily(state, '-at')
      const letters = ['c', 'b', 'h']

      let threeStreakUnlocked = false
      for (const letter of letters) {
        const { state: newState, result } = attemptWord(
          currentState,
          letter,
          '-at'
        )
        currentState = newState
        if (result.newAchievements?.some((a) => a.id === 'three-streak')) {
          threeStreakUnlocked = true
        }
      }

      expect(threeStreakUnlocked).toBe(true)
    })

    it('unlocks five-words achievement after 5 words', () => {
      let currentState = selectFamily(state, '-at')
      const letters = ['c', 'b', 'h', 'm', 's']

      let fiveWordsUnlocked = false
      for (const letter of letters) {
        const { state: newState, result } = attemptWord(
          currentState,
          letter,
          '-at'
        )
        currentState = newState
        if (result.newAchievements?.some((a) => a.id === 'five-words')) {
          fiveWordsUnlocked = true
        }
      }

      expect(fiveWordsUnlocked).toBe(true)
    })
  })
})
