// Word family data for word builder game
// Each family has an ending and valid beginning letters that form real words

export interface WordFamily {
  ending: string
  beginningLetters: string[]
  level: 1 | 2 | 3
}

export interface BuiltWord {
  word: string
  family: string
}

// Level 1: Simple -at, -an, -ap families
// Level 2: More families like -ig, -op, -ug
// Level 3: Complex endings like -ick, -ock, -unk

export const wordFamilies: WordFamily[] = [
  // Level 1 - Basic CVC
  { ending: 'at', beginningLetters: ['c', 'b', 'h', 'm', 's', 'r', 'f', 'p'], level: 1 },
  { ending: 'an', beginningLetters: ['c', 'm', 'p', 'r', 't', 'v', 'f'], level: 1 },
  { ending: 'ap', beginningLetters: ['c', 'm', 'n', 't', 'l', 'z', 'g'], level: 1 },
  { ending: 'am', beginningLetters: ['h', 'j', 'r', 's', 'y'], level: 1 },

  // Level 2 - More CVC patterns
  { ending: 'ig', beginningLetters: ['b', 'd', 'f', 'j', 'p', 'w'], level: 2 },
  { ending: 'op', beginningLetters: ['h', 'm', 'p', 't', 's', 'c'], level: 2 },
  { ending: 'ug', beginningLetters: ['b', 'd', 'h', 'j', 'm', 'r', 't'], level: 2 },
  { ending: 'et', beginningLetters: ['b', 'g', 'j', 'n', 'p', 'w'], level: 2 },
  { ending: 'en', beginningLetters: ['d', 'h', 'm', 'p', 't'], level: 2 },
  { ending: 'in', beginningLetters: ['b', 'f', 'p', 't', 'w'], level: 2 },

  // Level 3 - Longer endings
  { ending: 'ick', beginningLetters: ['k', 'l', 'p', 's', 't', 'w'], level: 3 },
  { ending: 'ock', beginningLetters: ['b', 'c', 'd', 'l', 'r', 's'], level: 3 },
  { ending: 'unk', beginningLetters: ['b', 'd', 'f', 'j', 's', 't'], level: 3 },
  { ending: 'ing', beginningLetters: ['k', 'r', 's', 'w', 'z'], level: 3 },
]

// Get word families for a specific level
export function getFamiliesByLevel(level: 1 | 2 | 3): WordFamily[] {
  return wordFamilies.filter(f => f.level === level)
}

// Get a random family for a level
export function getRandomFamily(level: 1 | 2 | 3): WordFamily {
  const families = getFamiliesByLevel(level)
  return families[Math.floor(Math.random() * families.length)]
}

// Check if a word is valid for a family
export function isValidWord(letter: string, family: WordFamily): boolean {
  return family.beginningLetters.includes(letter.toLowerCase())
}

// Build the complete word
export function buildWord(letter: string, ending: string): string {
  return letter.toLowerCase() + ending
}

// Get distractor letters (wrong letters for more challenge)
export function getDistractorLetters(family: WordFamily, count: number = 2): string[] {
  const allLetters = 'bcdfghjklmnpqrstvwxyz'.split('')
  const distractors = allLetters.filter(l => !family.beginningLetters.includes(l))

  // Shuffle and take the requested count
  for (let i = distractors.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1))
    ;[distractors[i], distractors[j]] = [distractors[j], distractors[i]]
  }

  return distractors.slice(0, count)
}

// Get shuffled letters for game (valid + distractors)
export function getGameLetters(family: WordFamily, includeDistractors: boolean = true): string[] {
  const validLetters = [...family.beginningLetters]
  const letters = includeDistractors
    ? [...validLetters, ...getDistractorLetters(family, 2)]
    : validLetters

  // Shuffle
  for (let i = letters.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1))
    ;[letters[i], letters[j]] = [letters[j], letters[i]]
  }

  return letters
}
