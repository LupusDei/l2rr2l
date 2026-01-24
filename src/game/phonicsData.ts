// Phonics game data - words organized by beginning sounds and difficulty
// Used for the phonics sound matching game

export interface PhonicsWord {
  word: string
  image: string // emoji placeholder - can be replaced with actual image URLs
  beginningSound: string // the letter sound to match (e.g., 'c' for 'cat')
  audio?: string // audio file path (optional)
}

export interface DifficultyLevel {
  name: string
  description: string
  words: PhonicsWord[]
  choiceCount: number // how many letter choices to show (3-4)
}

// Words grouped by beginning sound, then organized into difficulty levels
const wordsBySound: Record<string, PhonicsWord[]> = {
  c: [
    { word: 'cat', image: '🐱', beginningSound: 'c' },
    { word: 'car', image: '🚗', beginningSound: 'c' },
    { word: 'cup', image: '🥤', beginningSound: 'c' },
    { word: 'cow', image: '🐄', beginningSound: 'c' },
  ],
  d: [
    { word: 'dog', image: '🐕', beginningSound: 'd' },
    { word: 'duck', image: '🦆', beginningSound: 'd' },
    { word: 'door', image: '🚪', beginningSound: 'd' },
    { word: 'drum', image: '🥁', beginningSound: 'd' },
  ],
  f: [
    { word: 'fish', image: '🐟', beginningSound: 'f' },
    { word: 'fox', image: '🦊', beginningSound: 'f' },
    { word: 'frog', image: '🐸', beginningSound: 'f' },
    { word: 'fan', image: '🪭', beginningSound: 'f' },
  ],
  s: [
    { word: 'sun', image: '☀️', beginningSound: 's' },
    { word: 'star', image: '⭐', beginningSound: 's' },
    { word: 'snake', image: '🐍', beginningSound: 's' },
    { word: 'sock', image: '🧦', beginningSound: 's' },
  ],
  b: [
    { word: 'ball', image: '⚽', beginningSound: 'b' },
    { word: 'bear', image: '🐻', beginningSound: 'b' },
    { word: 'bus', image: '🚌', beginningSound: 'b' },
    { word: 'bird', image: '🐦', beginningSound: 'b' },
  ],
  m: [
    { word: 'moon', image: '🌙', beginningSound: 'm' },
    { word: 'mouse', image: '🐭', beginningSound: 'm' },
    { word: 'map', image: '🗺️', beginningSound: 'm' },
    { word: 'milk', image: '🥛', beginningSound: 'm' },
  ],
  p: [
    { word: 'pig', image: '🐷', beginningSound: 'p' },
    { word: 'pizza', image: '🍕', beginningSound: 'p' },
    { word: 'pen', image: '🖊️', beginningSound: 'p' },
    { word: 'pear', image: '🍐', beginningSound: 'p' },
  ],
  t: [
    { word: 'tree', image: '🌳', beginningSound: 't' },
    { word: 'turtle', image: '🐢', beginningSound: 't' },
    { word: 'train', image: '🚂', beginningSound: 't' },
    { word: 'tent', image: '⛺', beginningSound: 't' },
  ],
  h: [
    { word: 'hat', image: '🎩', beginningSound: 'h' },
    { word: 'house', image: '🏠', beginningSound: 'h' },
    { word: 'heart', image: '❤️', beginningSound: 'h' },
    { word: 'horse', image: '🐴', beginningSound: 'h' },
  ],
  r: [
    { word: 'rain', image: '🌧️', beginningSound: 'r' },
    { word: 'ring', image: '💍', beginningSound: 'r' },
    { word: 'rabbit', image: '🐰', beginningSound: 'r' },
    { word: 'rose', image: '🌹', beginningSound: 'r' },
  ],
}

// Get all available letter sounds
export function getAvailableSounds(): string[] {
  return Object.keys(wordsBySound)
}

// Get all words for a specific sound
export function getWordsBySound(sound: string): PhonicsWord[] {
  return wordsBySound[sound.toLowerCase()] || []
}

// Difficulty levels with progressive challenge
export const difficultyLevels: DifficultyLevel[] = [
  {
    name: 'Easy',
    description: 'Common sounds with 3 choices',
    choiceCount: 3,
    words: [
      ...wordsBySound.c.slice(0, 2),
      ...wordsBySound.d.slice(0, 2),
      ...wordsBySound.s.slice(0, 2),
      ...wordsBySound.b.slice(0, 2),
    ],
  },
  {
    name: 'Medium',
    description: 'More sounds with 3 choices',
    choiceCount: 3,
    words: [
      ...wordsBySound.f.slice(0, 2),
      ...wordsBySound.m.slice(0, 2),
      ...wordsBySound.p.slice(0, 2),
      ...wordsBySound.t.slice(0, 2),
    ],
  },
  {
    name: 'Hard',
    description: 'All sounds with 4 choices',
    choiceCount: 4,
    words: [
      ...wordsBySound.c.slice(2),
      ...wordsBySound.d.slice(2),
      ...wordsBySound.f.slice(2),
      ...wordsBySound.s.slice(2),
      ...wordsBySound.h,
      ...wordsBySound.r,
    ],
  },
]

// Get a random word from a specific level
export function getRandomWordFromLevel(levelIndex: number): PhonicsWord {
  const level = difficultyLevels[levelIndex] || difficultyLevels[0]
  return level.words[Math.floor(Math.random() * level.words.length)]
}

// Get wrong answer choices (letters that are NOT the correct answer)
export function getWrongChoices(
  correctSound: string,
  count: number
): string[] {
  const allSounds = getAvailableSounds()
  const wrongSounds = allSounds.filter((s) => s !== correctSound.toLowerCase())

  // Shuffle and take the needed count
  const shuffled = [...wrongSounds].sort(() => Math.random() - 0.5)
  return shuffled.slice(0, count)
}

// Get all choices (correct + wrong, shuffled)
export function getShuffledChoices(
  correctSound: string,
  totalChoices: number
): string[] {
  const wrongChoices = getWrongChoices(correctSound, totalChoices - 1)
  const allChoices = [correctSound.toLowerCase(), ...wrongChoices]
  return allChoices.sort(() => Math.random() - 0.5)
}

// Get total word count across all levels
export function getTotalWordCount(): number {
  return difficultyLevels.reduce((sum, level) => sum + level.words.length, 0)
}

// Get word count for a specific level
export function getLevelWordCount(levelIndex: number): number {
  const level = difficultyLevels[levelIndex]
  return level ? level.words.length : 0
}
