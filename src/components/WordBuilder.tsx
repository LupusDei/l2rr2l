import { useState, useEffect, useCallback } from 'react'
import { useVoice } from '../hooks/useVoice'
import './WordBuilder.css'

interface WordBuilderProps {
  onBack: () => void
}

interface WordPuzzle {
  word: string
  emoji: string
  hint: string
}

const WORD_PUZZLES: WordPuzzle[] = [
  { word: 'cat', emoji: '🐱', hint: 'A furry pet that meows' },
  { word: 'dog', emoji: '🐕', hint: 'A furry pet that barks' },
  { word: 'sun', emoji: '☀️', hint: 'It shines in the sky' },
  { word: 'hat', emoji: '🎩', hint: 'You wear it on your head' },
  { word: 'cup', emoji: '🥤', hint: 'You drink from it' },
  { word: 'bed', emoji: '🛏️', hint: 'You sleep on it' },
  { word: 'bus', emoji: '🚌', hint: 'A big vehicle for people' },
  { word: 'car', emoji: '🚗', hint: 'You drive it' },
  { word: 'pen', emoji: '🖊️', hint: 'You write with it' },
  { word: 'pig', emoji: '🐷', hint: 'A pink farm animal' },
  { word: 'box', emoji: '📦', hint: 'You put things inside' },
  { word: 'fox', emoji: '🦊', hint: 'A clever orange animal' },
  { word: 'red', emoji: '🔴', hint: 'The color of apples' },
  { word: 'run', emoji: '🏃', hint: 'Move fast with your legs' },
  { word: 'hop', emoji: '🐰', hint: 'Jump like a bunny' },
]

const ENCOURAGEMENTS = [
  "Great job!", "You got it!", "Awesome!", "Perfect!",
  "Amazing!", "Fantastic!", "Super star!", "Well done!"
]

const CELEBRATIONS = [
  "You're a word builder champion!", "Incredible work!",
  "You really know your letters!", "Keep up the great work!"
]

interface GameState {
  currentPuzzle: WordPuzzle | null
  availableLetters: string[]
  builtWord: string[]
  score: number
  streak: number
  round: number
  totalRounds: number
  showFeedback: boolean
  isCorrect: boolean | null
  gameComplete: boolean
}

function shuffleArray<T>(array: T[]): T[] {
  const shuffled = [...array]
  for (let i = shuffled.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]]
  }
  return shuffled
}

export default function WordBuilder({ onBack }: WordBuilderProps) {
  const { speak, settings } = useVoice()
  const [gameState, setGameState] = useState<GameState>({
    currentPuzzle: null,
    availableLetters: [],
    builtWord: [],
    score: 0,
    streak: 0,
    round: 0,
    totalRounds: 10,
    showFeedback: false,
    isCorrect: null,
    gameComplete: false,
  })

  const generateRound = useCallback(() => {
    const puzzle = WORD_PUZZLES[Math.floor(Math.random() * WORD_PUZZLES.length)]

    // Add 2-3 extra random letters as distractors
    const extraLetters = 'abcdefghijklmnopqrstuvwxyz'
      .split('')
      .filter(l => !puzzle.word.includes(l))
      .sort(() => Math.random() - 0.5)
      .slice(0, 2 + Math.floor(Math.random() * 2))

    const allLetters = shuffleArray([...puzzle.word.split(''), ...extraLetters])

    setGameState(prev => ({
      ...prev,
      currentPuzzle: puzzle,
      availableLetters: allLetters,
      builtWord: [],
      showFeedback: false,
      isCorrect: null,
    }))

    if (settings.enabled) {
      setTimeout(() => {
        speak(`Build the word! ${puzzle.hint}`)
      }, 500)
    }
  }, [speak, settings.enabled])

  useEffect(() => {
    if (!gameState.gameComplete && !gameState.currentPuzzle) {
      generateRound()
    }
  }, [generateRound, gameState.gameComplete, gameState.currentPuzzle])

  const handleLetterClick = (letter: string, index: number) => {
    if (gameState.showFeedback) return

    // Remove letter from available and add to built word
    const newAvailable = [...gameState.availableLetters]
    newAvailable.splice(index, 1)

    setGameState(prev => ({
      ...prev,
      availableLetters: newAvailable,
      builtWord: [...prev.builtWord, letter],
    }))
  }

  const handleBuiltLetterClick = (letter: string, index: number) => {
    if (gameState.showFeedback) return

    // Remove letter from built word and add back to available
    const newBuilt = [...gameState.builtWord]
    newBuilt.splice(index, 1)

    setGameState(prev => ({
      ...prev,
      builtWord: newBuilt,
      availableLetters: [...prev.availableLetters, letter],
    }))
  }

  const handleSubmit = async () => {
    if (!gameState.currentPuzzle || gameState.showFeedback) return

    const builtWordStr = gameState.builtWord.join('')
    const isCorrect = builtWordStr === gameState.currentPuzzle.word

    setGameState(prev => ({
      ...prev,
      isCorrect,
      showFeedback: true,
      score: isCorrect ? prev.score + (10 * (prev.streak + 1)) : prev.score,
      streak: isCorrect ? prev.streak + 1 : 0,
    }))

    if (settings.enabled && settings.encouragementEnabled) {
      if (isCorrect) {
        const msg = ENCOURAGEMENTS[Math.floor(Math.random() * ENCOURAGEMENTS.length)]
        await speak(msg)
      } else {
        await speak(`The word is ${gameState.currentPuzzle.word}`)
      }
    }

    // Move to next round after delay
    setTimeout(() => {
      const nextRound = gameState.round + 1
      if (nextRound >= gameState.totalRounds) {
        setGameState(prev => ({ ...prev, gameComplete: true }))
        if (settings.enabled) {
          const celebration = CELEBRATIONS[Math.floor(Math.random() * CELEBRATIONS.length)]
          speak(celebration)
        }
      } else {
        setGameState(prev => ({
          ...prev,
          round: nextRound,
          currentPuzzle: null,
        }))
      }
    }, 2000)
  }

  const handleClear = () => {
    if (gameState.showFeedback || !gameState.currentPuzzle) return

    // Put all letters back to available
    const allLetters = [...gameState.availableLetters, ...gameState.builtWord]
    setGameState(prev => ({
      ...prev,
      availableLetters: shuffleArray(allLetters),
      builtWord: [],
    }))
  }

  const handleHint = () => {
    if (gameState.currentPuzzle && settings.enabled) {
      speak(gameState.currentPuzzle.hint)
    }
  }

  const handlePlayAgain = () => {
    setGameState({
      currentPuzzle: null,
      availableLetters: [],
      builtWord: [],
      score: 0,
      streak: 0,
      round: 0,
      totalRounds: 10,
      showFeedback: false,
      isCorrect: null,
      gameComplete: false,
    })
  }

  if (gameState.gameComplete) {
    return (
      <div className="word-builder">
        <div className="game-complete">
          <div className="celebration-icon">🏆</div>
          <h2>Amazing Work!</h2>
          <p className="final-score">Score: {gameState.score}</p>
          <p className="rounds-info">You built {gameState.totalRounds} words!</p>
          <div className="complete-buttons">
            <button className="play-again-btn" onClick={handlePlayAgain}>
              Play Again
            </button>
            <button className="back-btn" onClick={onBack}>
              Back to Home
            </button>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="word-builder">
      <header className="word-builder-header">
        <button className="back-button" onClick={onBack} type="button">
          ← Back
        </button>
        <h1 className="word-builder-title">Word Builder</h1>
        <div className="game-stats">
          <span className="score">Score: {gameState.score}</span>
          <span className="streak">🔥 {gameState.streak}</span>
          <span className="round">Round {gameState.round + 1}/{gameState.totalRounds}</span>
        </div>
      </header>

      <main className="word-builder-content">
        {gameState.currentPuzzle && (
          <>
            <div className="puzzle-display">
              <span className="puzzle-emoji">{gameState.currentPuzzle.emoji}</span>
              <p className="puzzle-hint">{gameState.currentPuzzle.hint}</p>
              <button className="hint-btn" onClick={handleHint} type="button">
                🔊 Hear Hint
              </button>
            </div>

            <div className="build-area">
              <p className="build-label">Build the word:</p>
              <div className="built-word-container">
                {gameState.builtWord.length === 0 ? (
                  <div className="empty-slot">Tap letters below</div>
                ) : (
                  gameState.builtWord.map((letter, index) => (
                    <button
                      key={`built-${index}`}
                      className={`letter-tile built ${gameState.showFeedback ? (gameState.isCorrect ? 'correct' : 'incorrect') : ''}`}
                      onClick={() => handleBuiltLetterClick(letter, index)}
                      disabled={gameState.showFeedback}
                      type="button"
                    >
                      {letter.toUpperCase()}
                    </button>
                  ))
                )}
              </div>
            </div>

            <div className="letters-tray">
              <p className="tray-label">Available letters:</p>
              <div className="available-letters">
                {gameState.availableLetters.map((letter, index) => (
                  <button
                    key={`avail-${index}`}
                    className="letter-tile available"
                    onClick={() => handleLetterClick(letter, index)}
                    disabled={gameState.showFeedback}
                    type="button"
                  >
                    {letter.toUpperCase()}
                  </button>
                ))}
              </div>
            </div>

            <div className="action-buttons">
              <button
                className="clear-btn"
                onClick={handleClear}
                disabled={gameState.showFeedback || gameState.builtWord.length === 0}
                type="button"
              >
                Clear
              </button>
              <button
                className="submit-btn"
                onClick={handleSubmit}
                disabled={gameState.showFeedback || gameState.builtWord.length === 0}
                type="button"
              >
                Check Word
              </button>
            </div>

            {gameState.showFeedback && (
              <div className={`feedback ${gameState.isCorrect ? 'correct' : 'incorrect'}`}>
                {gameState.isCorrect ? (
                  <>✓ Correct! The word is "{gameState.currentPuzzle.word}"</>
                ) : (
                  <>✗ The word was "{gameState.currentPuzzle.word}"</>
                )}
              </div>
            )}
          </>
        )}
      </main>
    </div>
  )
}
