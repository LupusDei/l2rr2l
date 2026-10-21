import { useState, useEffect, useCallback, useRef } from 'react'
import { useVoice } from '../hooks/useVoice'
import './WordBuilder.css'

interface WordBuilderProps {
  onBack: () => void
}

interface WordPuzzle {
  word: string
  emoji: string
  hint: string
  phonemes: string[] // Phoneme breakdown for learning
}

// Confetti particle for celebration effect
interface ConfettiParticle {
  id: number
  x: number
  y: number
  color: string
  rotation: number
  scale: number
  delay: number
}

const WORD_PUZZLES: WordPuzzle[] = [
  { word: 'cat', emoji: '🐱', hint: 'A furry pet that meows', phonemes: ['c', 'a', 't'] },
  { word: 'dog', emoji: '🐕', hint: 'A furry pet that barks', phonemes: ['d', 'o', 'g'] },
  { word: 'sun', emoji: '☀️', hint: 'It shines in the sky', phonemes: ['s', 'u', 'n'] },
  { word: 'hat', emoji: '🎩', hint: 'You wear it on your head', phonemes: ['h', 'a', 't'] },
  { word: 'cup', emoji: '🥤', hint: 'You drink from it', phonemes: ['c', 'u', 'p'] },
  { word: 'bed', emoji: '🛏️', hint: 'You sleep on it', phonemes: ['b', 'e', 'd'] },
  { word: 'bus', emoji: '🚌', hint: 'A big vehicle for people', phonemes: ['b', 'u', 's'] },
  { word: 'car', emoji: '🚗', hint: 'You drive it', phonemes: ['c', 'ar'] },
  { word: 'pen', emoji: '🖊️', hint: 'You write with it', phonemes: ['p', 'e', 'n'] },
  { word: 'pig', emoji: '🐷', hint: 'A pink farm animal', phonemes: ['p', 'i', 'g'] },
  { word: 'box', emoji: '📦', hint: 'You put things inside', phonemes: ['b', 'o', 'x'] },
  { word: 'fox', emoji: '🦊', hint: 'A clever orange animal', phonemes: ['f', 'o', 'x'] },
  { word: 'red', emoji: '🔴', hint: 'The color of apples', phonemes: ['r', 'e', 'd'] },
  { word: 'run', emoji: '🏃', hint: 'Move fast with your legs', phonemes: ['r', 'u', 'n'] },
  { word: 'hop', emoji: '🐰', hint: 'Jump like a bunny', phonemes: ['h', 'o', 'p'] },
]

const CONFETTI_COLORS = ['#ff6b6b', '#4ecdc4', '#ffe66d', '#95e1d3', '#f38181', '#aa96da', '#fcbad3']

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
  showPhonemes: boolean
  confetti: ConfettiParticle[]
  animatingLetterIndex: number | null
}

function shuffleArray<T>(array: T[]): T[] {
  const shuffled = [...array]
  for (let i = shuffled.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]]
  }
  return shuffled
}

// Generate confetti particles for celebration
function generateConfetti(count: number): ConfettiParticle[] {
  return Array.from({ length: count }, (_, i) => ({
    id: Date.now() + i,
    x: Math.random() * 100,
    y: -10 - Math.random() * 20,
    color: CONFETTI_COLORS[Math.floor(Math.random() * CONFETTI_COLORS.length)],
    rotation: Math.random() * 360,
    scale: 0.5 + Math.random() * 0.5,
    delay: Math.random() * 0.5,
  }))
}

export default function WordBuilder({ onBack }: WordBuilderProps) {
  const { speak, settings } = useVoice()
  const confettiContainerRef = useRef<HTMLDivElement>(null)
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
    showPhonemes: false,
    confetti: [],
    animatingLetterIndex: null,
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
      showPhonemes: false,
      confetti: [],
      animatingLetterIndex: null,
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
    if (gameState.showFeedback || gameState.animatingLetterIndex !== null) return

    // Set animating state for smooth transition
    setGameState(prev => ({ ...prev, animatingLetterIndex: index }))

    // Remove letter from available and add to built word after brief animation
    setTimeout(() => {
      const newAvailable = [...gameState.availableLetters]
      newAvailable.splice(index, 1)

      setGameState(prev => ({
        ...prev,
        availableLetters: newAvailable,
        builtWord: [...prev.builtWord, letter],
        animatingLetterIndex: null,
      }))
    }, 150)
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

    // Generate confetti for correct answers
    const newConfetti = isCorrect ? generateConfetti(30) : []

    setGameState(prev => ({
      ...prev,
      isCorrect,
      showFeedback: true,
      showPhonemes: true, // Show phoneme breakdown
      score: isCorrect ? prev.score + (10 * (prev.streak + 1)) : prev.score,
      streak: isCorrect ? prev.streak + 1 : 0,
      confetti: newConfetti,
    }))

    if (settings.enabled) {
      if (isCorrect) {
        // Pronounce the word first, then encouragement
        await speak(gameState.currentPuzzle.word)
        if (settings.encouragementEnabled) {
          const msg = ENCOURAGEMENTS[Math.floor(Math.random() * ENCOURAGEMENTS.length)]
          await speak(msg)
        }
      } else {
        // Show correct word pronunciation
        await speak(`The word is ${gameState.currentPuzzle.word}`)
      }
    }

    // Clear confetti after animation
    setTimeout(() => {
      setGameState(prev => ({ ...prev, confetti: [] }))
    }, 2500)

    // Move to next round after delay
    setTimeout(() => {
      const nextRound = gameState.round + 1
      if (nextRound >= gameState.totalRounds) {
        setGameState(prev => ({
          ...prev,
          gameComplete: true,
          confetti: generateConfetti(50), // Big celebration for game complete
        }))
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
    }, 2500)
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
      showPhonemes: false,
      confetti: [],
      animatingLetterIndex: null,
    })
  }

  if (gameState.gameComplete) {
    return (
      <div className="word-builder">
        {/* Confetti celebration */}
        {gameState.confetti.length > 0 && (
          <div className="confetti-container" ref={confettiContainerRef}>
            {gameState.confetti.map((particle) => (
              <div
                key={particle.id}
                className="confetti-particle"
                style={{
                  left: `${particle.x}%`,
                  backgroundColor: particle.color,
                  transform: `rotate(${particle.rotation}deg) scale(${particle.scale})`,
                  animationDelay: `${particle.delay}s`,
                }}
              />
            ))}
          </div>
        )}
        <div className="game-complete">
          <div className="celebration-icon bounce-in">🏆</div>
          <h2 className="slide-up">Amazing Work!</h2>
          <p className="final-score pulse">Score: {gameState.score}</p>
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
      {/* Confetti celebration */}
      {gameState.confetti.length > 0 && (
        <div className="confetti-container" ref={confettiContainerRef}>
          {gameState.confetti.map((particle) => (
            <div
              key={particle.id}
              className="confetti-particle"
              style={{
                left: `${particle.x}%`,
                backgroundColor: particle.color,
                transform: `rotate(${particle.rotation}deg) scale(${particle.scale})`,
                animationDelay: `${particle.delay}s`,
              }}
            />
          ))}
        </div>
      )}

      <header className="word-builder-header">
        <button className="back-button" onClick={onBack} type="button">
          ← Back
        </button>
        <h1 className="word-builder-title">Word Builder</h1>
        <div className="game-stats">
          <span className="score">Score: {gameState.score}</span>
          <span className={`streak ${gameState.streak >= 3 ? 'streak-hot' : ''}`}>
            🔥 {gameState.streak}
          </span>
          <span className="round">Round {gameState.round + 1}/{gameState.totalRounds}</span>
        </div>
      </header>

      <main className="word-builder-content">
        {gameState.currentPuzzle && (
          <>
            <div className="puzzle-display fade-in">
              <span className="puzzle-emoji bounce-in">{gameState.currentPuzzle.emoji}</span>
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
                      className={`letter-tile built pop-in ${gameState.showFeedback ? (gameState.isCorrect ? 'correct' : 'incorrect') : ''}`}
                      onClick={() => handleBuiltLetterClick(letter, index)}
                      disabled={gameState.showFeedback}
                      type="button"
                      style={{ animationDelay: `${index * 0.05}s` }}
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
                    className={`letter-tile available ${gameState.animatingLetterIndex === index ? 'animating-out' : ''}`}
                    onClick={() => handleLetterClick(letter, index)}
                    disabled={gameState.showFeedback || gameState.animatingLetterIndex !== null}
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
              <div className={`feedback slide-up ${gameState.isCorrect ? 'correct' : 'incorrect'}`}>
                {gameState.isCorrect ? (
                  <>✓ Correct! The word is "{gameState.currentPuzzle.word}"</>
                ) : (
                  <>✗ The word was "{gameState.currentPuzzle.word}"</>
                )}
              </div>
            )}

            {/* Phoneme breakdown for word learning */}
            {gameState.showPhonemes && gameState.currentPuzzle && (
              <div className="phoneme-breakdown slide-up">
                <p className="phoneme-label">Sound it out:</p>
                <div className="phoneme-tiles">
                  {gameState.currentPuzzle.phonemes.map((phoneme, index) => (
                    <span
                      key={`phoneme-${index}`}
                      className="phoneme-tile pop-in"
                      style={{ animationDelay: `${index * 0.1}s` }}
                    >
                      {phoneme}
                    </span>
                  ))}
                </div>
              </div>
            )}
          </>
        )}
      </main>
    </div>
  )
}
