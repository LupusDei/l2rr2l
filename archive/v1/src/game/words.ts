// 3-letter CVC words for spelling game
// Sorted roughly by difficulty - start with common, phonetically simple words

export interface Word {
  word: string
  image: string // emoji placeholder - can be replaced with actual image URLs
  audio?: string // audio file path (optional for now)
}

export const words: Word[] = [
  { word: 'cat', image: '🐱' },
  { word: 'dog', image: '🐕' },
  { word: 'sun', image: '☀️' },
  { word: 'hat', image: '🎩' },
  { word: 'bug', image: '🐛' },
  { word: 'cup', image: '🥤' },
  { word: 'bed', image: '🛏️' },
  { word: 'pig', image: '🐷' },
  { word: 'fox', image: '🦊' },
  { word: 'hen', image: '🐔' },
  { word: 'bat', image: '🦇' },
  { word: 'bus', image: '🚌' },
  { word: 'map', image: '🗺️' },
  { word: 'web', image: '🕸️' },
  { word: 'jam', image: '🍓' },
  { word: 'log', image: '🪵' },
  { word: 'pot', image: '🍲' },
  { word: 'rug', image: '🟫' },
  { word: 'net', image: '🥅' },
  { word: 'box', image: '📦' },
]

// Utility to get a random word
export function getRandomWord(): Word {
  return words[Math.floor(Math.random() * words.length)]
}

// Utility to shuffle letters
export function shuffleLetters(word: string): string[] {
  const letters = word.split('')
  for (let i = letters.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1))
    ;[letters[i], letters[j]] = [letters[j], letters[i]]
  }
  return letters
}
