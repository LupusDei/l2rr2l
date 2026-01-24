// Word family data for the word builder game
// Organized by difficulty level and word ending patterns

export interface WordFamily {
  ending: string // e.g., "-at", "-an"
  validLetters: string[] // letters that form real words with this ending
  words: WordFamilyWord[] // all valid words in this family
  emoji: string // visual representation for the family
}

export interface WordFamilyWord {
  word: string
  letter: string // the beginning letter
  image: string // emoji for the word
}

export interface DifficultyLevel {
  level: 1 | 2 | 3
  name: string
  description: string
  families: WordFamily[]
}

// Level 1: Short A word families (-at, -an, -ap, -ad)
const level1Families: WordFamily[] = [
  {
    ending: '-at',
    emoji: '🐱',
    validLetters: ['b', 'c', 'f', 'h', 'm', 'p', 'r', 's'],
    words: [
      { word: 'bat', letter: 'b', image: '🦇' },
      { word: 'cat', letter: 'c', image: '🐱' },
      { word: 'fat', letter: 'f', image: '🍔' },
      { word: 'hat', letter: 'h', image: '🎩' },
      { word: 'mat', letter: 'm', image: '🟫' },
      { word: 'pat', letter: 'p', image: '👋' },
      { word: 'rat', letter: 'r', image: '🐀' },
      { word: 'sat', letter: 's', image: '🪑' },
    ],
  },
  {
    ending: '-an',
    emoji: '🥫',
    validLetters: ['c', 'f', 'm', 'p', 'r', 't', 'v'],
    words: [
      { word: 'can', letter: 'c', image: '🥫' },
      { word: 'fan', letter: 'f', image: '🪭' },
      { word: 'man', letter: 'm', image: '👨' },
      { word: 'pan', letter: 'p', image: '🍳' },
      { word: 'ran', letter: 'r', image: '🏃' },
      { word: 'tan', letter: 't', image: '☀️' },
      { word: 'van', letter: 'v', image: '🚐' },
    ],
  },
  {
    ending: '-ap',
    emoji: '🗺️',
    validLetters: ['c', 'g', 'l', 'm', 'n', 'r', 't', 'z'],
    words: [
      { word: 'cap', letter: 'c', image: '🧢' },
      { word: 'gap', letter: 'g', image: '🕳️' },
      { word: 'lap', letter: 'l', image: '🏁' },
      { word: 'map', letter: 'm', image: '🗺️' },
      { word: 'nap', letter: 'n', image: '😴' },
      { word: 'rap', letter: 'r', image: '🎤' },
      { word: 'tap', letter: 't', image: '🚿' },
      { word: 'zap', letter: 'z', image: '⚡' },
    ],
  },
  {
    ending: '-ad',
    emoji: '👨',
    validLetters: ['b', 'd', 'h', 'm', 'p', 's'],
    words: [
      { word: 'bad', letter: 'b', image: '👎' },
      { word: 'dad', letter: 'd', image: '👨' },
      { word: 'had', letter: 'h', image: '🤲' },
      { word: 'mad', letter: 'm', image: '😠' },
      { word: 'pad', letter: 'p', image: '📝' },
      { word: 'sad', letter: 's', image: '😢' },
    ],
  },
]

// Level 2: Short E and I word families
const level2Families: WordFamily[] = [
  {
    ending: '-et',
    emoji: '🥅',
    validLetters: ['b', 'g', 'j', 'l', 'm', 'n', 'p', 's', 'w'],
    words: [
      { word: 'bet', letter: 'b', image: '🎰' },
      { word: 'get', letter: 'g', image: '🤲' },
      { word: 'jet', letter: 'j', image: '✈️' },
      { word: 'let', letter: 'l', image: '👋' },
      { word: 'met', letter: 'm', image: '🤝' },
      { word: 'net', letter: 'n', image: '🥅' },
      { word: 'pet', letter: 'p', image: '🐕' },
      { word: 'set', letter: 's', image: '📐' },
      { word: 'wet', letter: 'w', image: '💧' },
    ],
  },
  {
    ending: '-en',
    emoji: '🐔',
    validLetters: ['d', 'h', 'm', 'p', 't'],
    words: [
      { word: 'den', letter: 'd', image: '🏠' },
      { word: 'hen', letter: 'h', image: '🐔' },
      { word: 'men', letter: 'm', image: '👥' },
      { word: 'pen', letter: 'p', image: '🖊️' },
      { word: 'ten', letter: 't', image: '🔟' },
    ],
  },
  {
    ending: '-ig',
    emoji: '🐷',
    validLetters: ['b', 'd', 'f', 'j', 'p', 'w'],
    words: [
      { word: 'big', letter: 'b', image: '🦣' },
      { word: 'dig', letter: 'd', image: '⛏️' },
      { word: 'fig', letter: 'f', image: '🫐' },
      { word: 'jig', letter: 'j', image: '💃' },
      { word: 'pig', letter: 'p', image: '🐷' },
      { word: 'wig', letter: 'w', image: '💇' },
    ],
  },
  {
    ending: '-in',
    emoji: '📍',
    validLetters: ['b', 'f', 'k', 'p', 't', 'w'],
    words: [
      { word: 'bin', letter: 'b', image: '🗑️' },
      { word: 'fin', letter: 'f', image: '🦈' },
      { word: 'kin', letter: 'k', image: '👪' },
      { word: 'pin', letter: 'p', image: '📍' },
      { word: 'tin', letter: 't', image: '🥫' },
      { word: 'win', letter: 'w', image: '🏆' },
    ],
  },
]

// Level 3: Short O and U word families
const level3Families: WordFamily[] = [
  {
    ending: '-ot',
    emoji: '🍲',
    validLetters: ['c', 'd', 'g', 'h', 'l', 'n', 'p'],
    words: [
      { word: 'cot', letter: 'c', image: '🛏️' },
      { word: 'dot', letter: 'd', image: '⚫' },
      { word: 'got', letter: 'g', image: '🤲' },
      { word: 'hot', letter: 'h', image: '🔥' },
      { word: 'lot', letter: 'l', image: '📦' },
      { word: 'not', letter: 'n', image: '🚫' },
      { word: 'pot', letter: 'p', image: '🍲' },
    ],
  },
  {
    ending: '-op',
    emoji: '🔝',
    validLetters: ['b', 'c', 'h', 'm', 'p', 's', 't'],
    words: [
      { word: 'bop', letter: 'b', image: '👊' },
      { word: 'cop', letter: 'c', image: '👮' },
      { word: 'hop', letter: 'h', image: '🐰' },
      { word: 'mop', letter: 'm', image: '🧹' },
      { word: 'pop', letter: 'p', image: '🎈' },
      { word: 'sop', letter: 's', image: '🧽' },
      { word: 'top', letter: 't', image: '🔝' },
    ],
  },
  {
    ending: '-ug',
    emoji: '🐛',
    validLetters: ['b', 'd', 'h', 'j', 'm', 'r', 't'],
    words: [
      { word: 'bug', letter: 'b', image: '🐛' },
      { word: 'dug', letter: 'd', image: '⛏️' },
      { word: 'hug', letter: 'h', image: '🤗' },
      { word: 'jug', letter: 'j', image: '🫗' },
      { word: 'mug', letter: 'm', image: '☕' },
      { word: 'rug', letter: 'r', image: '🟫' },
      { word: 'tug', letter: 't', image: '🚢' },
    ],
  },
  {
    ending: '-un',
    emoji: '☀️',
    validLetters: ['b', 'f', 'g', 'r', 's'],
    words: [
      { word: 'bun', letter: 'b', image: '🍔' },
      { word: 'fun', letter: 'f', image: '🎉' },
      { word: 'gun', letter: 'g', image: '🔫' },
      { word: 'run', letter: 'r', image: '🏃' },
      { word: 'sun', letter: 's', image: '☀️' },
    ],
  },
]

// All difficulty levels
export const difficultyLevels: DifficultyLevel[] = [
  {
    level: 1,
    name: 'Easy',
    description: 'Short A word families',
    families: level1Families,
  },
  {
    level: 2,
    name: 'Medium',
    description: 'Short E and I word families',
    families: level2Families,
  },
  {
    level: 3,
    name: 'Hard',
    description: 'Short O and U word families',
    families: level3Families,
  },
]

// Get all word families across all levels
export function getAllFamilies(): WordFamily[] {
  return difficultyLevels.flatMap((level) => level.families)
}

// Get families for a specific difficulty level
export function getFamiliesByLevel(level: 1 | 2 | 3): WordFamily[] {
  const levelData = difficultyLevels.find((l) => l.level === level)
  return levelData ? levelData.families : []
}

// Get a specific word family by its ending
export function getFamilyByEnding(ending: string): WordFamily | undefined {
  return getAllFamilies().find((f) => f.ending === ending)
}

// Validate if a letter + ending makes a valid word
export function isValidWord(letter: string, ending: string): boolean {
  const family = getFamilyByEnding(ending)
  if (!family) return false
  return family.validLetters.includes(letter.toLowerCase())
}

// Get the word data for a valid letter + ending combination
export function getWordData(
  letter: string,
  ending: string
): WordFamilyWord | undefined {
  const family = getFamilyByEnding(ending)
  if (!family) return undefined
  return family.words.find((w) => w.letter === letter.toLowerCase())
}

// Get available letters for a family (for display to user)
export function getAvailableLetters(ending: string): string[] {
  const family = getFamilyByEnding(ending)
  return family ? family.validLetters : []
}

// Get distractor letters (letters that don't make valid words with this ending)
export function getDistractorLetters(
  ending: string,
  count: number
): string[] {
  const validLetters = getAvailableLetters(ending)
  const allLetters = 'abcdefghijklmnopqrstuvwxyz'.split('')
  const distractors = allLetters.filter((l) => !validLetters.includes(l))
  // Shuffle and return requested count
  return distractors.sort(() => Math.random() - 0.5).slice(0, count)
}

// Get total words available in a family
export function getFamilyWordCount(ending: string): number {
  const family = getFamilyByEnding(ending)
  return family ? family.words.length : 0
}

// Get total words available at a difficulty level
export function getLevelWordCount(level: 1 | 2 | 3): number {
  const families = getFamiliesByLevel(level)
  return families.reduce((sum, family) => sum + family.words.length, 0)
}
