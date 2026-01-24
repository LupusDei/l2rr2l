import { useState, useCallback, useEffect, useRef } from 'react'
import './MemoryGame.css'
import { getRandomWordsForGame, type SightWord } from '../game/sightWords'
import { playCorrectSound, playWordCompleteSound } from '../game/sounds'
import { useVoice } from '../hooks/useVoice'

interface MemoryGameProps {
  onBack: () => void
  level?: SightWord['level']
  gridSize?: 8 | 12 | 16 // 4x2, 4x3, 4x4
}

interface Card {
  id: number
  word: string
  isFlipped: boolean
  isMatched: boolean
}

// Celebration messages
const celebrationMessages = [
  { text: 'Amazing!', emoji: '🌟' },
  { text: 'Great Job!', emoji: '🎉' },
  { text: 'Wonderful!', emoji: '✨' },
  { text: 'Fantastic!', emoji: '🚀' },
  { text: 'You Did It!', emoji: '🏆' },
]

// Generate confetti positions
function generateConfettiPositions(count: number = 30) {
  const colors = ['#ff6b6b', '#ffd43b', '#51cf66', '#4dabf7', '#cc5de8', '#ff922b']
  return Array.from({ length: count }).map((_, i) => ({
    id: i,
    left: `${Math.random() * 100}%`,
    delay: `${Math.random() * 0.5}s`,
    color: colors[i % colors.length],
    duration: 1 + Math.random() * 0.5,
  }))
}

const confettiPositions = generateConfettiPositions(30)

// Helper to create initial cards
function createInitialCards(gridSize: number, level?: SightWord['level']): Card[] {
  const words = getRandomWordsForGame(gridSize, level)
  return words.map((word, index) => ({
    id: index,
    word,
    isFlipped: false,
    isMatched: false,
  }))
}

export default function MemoryGame({ onBack, level, gridSize = 12 }: MemoryGameProps) {
  const { speak, isSpeaking } = useVoice()
  // Use lazy initialization to avoid setState in effect
  const [cards, setCards] = useState<Card[]>(() => createInitialCards(gridSize, level))
  const [flippedCards, setFlippedCards] = useState<number[]>([])
  const [moves, setMoves] = useState(0)
  const [matchedPairs, setMatchedPairs] = useState(0)
  const [showCelebration, setShowCelebration] = useState(false)
  const [celebrationMessage, setCelebrationMessage] = useState(celebrationMessages[0])
  const [isProcessing, setIsProcessing] = useState(false)
  const hasAnnouncedRef = useRef(false)

  const totalPairs = gridSize / 2

  // Reset game state
  const resetGame = useCallback(() => {
    setCards(createInitialCards(gridSize, level))
    setFlippedCards([])
    setMoves(0)
    setMatchedPairs(0)
    setShowCelebration(false)
    setIsProcessing(false)
    hasAnnouncedRef.current = false
  }, [gridSize, level])

  // Announce game start
  useEffect(() => {
    if (cards.length > 0 && !hasAnnouncedRef.current) {
      hasAnnouncedRef.current = true
      const timer = setTimeout(() => {
        speak('Find the matching words!')
      }, 500)
      return () => clearTimeout(timer)
    }
  }, [cards.length, speak])

  // Handle card click
  const handleCardClick = useCallback((cardId: number) => {
    // Don't allow clicks while processing or if card is already flipped/matched
    if (isProcessing) return
    if (flippedCards.length >= 2) return

    const card = cards.find(c => c.id === cardId)
    if (!card || card.isFlipped || card.isMatched) return

    // Flip the card
    setCards(prev => prev.map(c =>
      c.id === cardId ? { ...c, isFlipped: true } : c
    ))

    // Speak the word
    if (!isSpeaking) {
      speak(card.word)
    }

    const newFlippedCards = [...flippedCards, cardId]
    setFlippedCards(newFlippedCards)

    // Check for match when 2 cards are flipped
    if (newFlippedCards.length === 2) {
      setMoves(prev => prev + 1)
      setIsProcessing(true)

      const [firstId, secondId] = newFlippedCards
      const firstCard = cards.find(c => c.id === firstId)!
      const secondCard = cards.find(c => c.id === secondId)!

      if (firstCard.word === secondCard.word) {
        // Match found!
        playCorrectSound()

        setTimeout(() => {
          setCards(prev => prev.map(c =>
            c.id === firstId || c.id === secondId
              ? { ...c, isMatched: true }
              : c
          ))
          setFlippedCards([])
          setIsProcessing(false)

          const newMatchedPairs = matchedPairs + 1
          setMatchedPairs(newMatchedPairs)

          // Check for game completion
          if (newMatchedPairs === totalPairs) {
            setTimeout(() => {
              playWordCompleteSound()
              const msg = celebrationMessages[Math.floor(Math.random() * celebrationMessages.length)]
              setCelebrationMessage(msg)
              setShowCelebration(true)
              speak(`${msg.text} You found all the matches!`)
            }, 500)
          } else {
            speak('Match!')
          }
        }, 600)
      } else {
        // No match - flip cards back after delay
        setTimeout(() => {
          setCards(prev => prev.map(c =>
            c.id === firstId || c.id === secondId
              ? { ...c, isFlipped: false }
              : c
          ))
          setFlippedCards([])
          setIsProcessing(false)
        }, 1200)
      }
    }
  }, [cards, flippedCards, isProcessing, isSpeaking, matchedPairs, speak, totalPairs])

  // Play again
  const handlePlayAgain = useCallback(() => {
    resetGame()
    setTimeout(() => {
      speak('Find the matching words!')
    }, 300)
  }, [resetGame, speak])

  // Calculate grid columns based on size
  const getGridCols = () => {
    if (gridSize === 8) return 4
    if (gridSize === 12) return 4
    if (gridSize === 16) return 4
    return 4
  }

  return (
    <div className="memory-game">
      {/* Header */}
      <header className="memory-header">
        <button className="back-button" onClick={onBack} type="button">
          &#8592; Back
        </button>
        <div className="memory-stats">
          <span className="stat">Moves: {moves}</span>
          <span className="stat">Matches: {matchedPairs}/{totalPairs}</span>
        </div>
      </header>

      {/* Celebration overlay */}
      {showCelebration && (
        <div className="celebration-overlay">
          <div className="celebration-content">
            <span className="celebration-emoji">{celebrationMessage.emoji}</span>
            <h2 className="celebration-text">{celebrationMessage.text}</h2>
            <p className="celebration-stats">
              Completed in {moves} moves!
            </p>
            <button
              className="play-again-button"
              onClick={handlePlayAgain}
              type="button"
            >
              Play Again
            </button>
            <div className="confetti">
              {confettiPositions.map(({ id, left, delay, color, duration }) => (
                <span
                  key={id}
                  className="confetti-piece"
                  style={{
                    left,
                    animationDelay: delay,
                    backgroundColor: color,
                    animationDuration: `${duration}s`,
                  }}
                />
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Card grid */}
      <div
        className="memory-grid"
        style={{ gridTemplateColumns: `repeat(${getGridCols()}, 1fr)` }}
      >
        {cards.map(card => (
          <button
            key={card.id}
            className={`memory-card ${card.isFlipped ? 'flipped' : ''} ${card.isMatched ? 'matched' : ''}`}
            onClick={() => handleCardClick(card.id)}
            disabled={card.isFlipped || card.isMatched || isProcessing}
            type="button"
            aria-label={card.isFlipped || card.isMatched ? card.word : 'Hidden card'}
          >
            <div className="card-inner">
              <div className="card-front">
                <span className="card-symbol">?</span>
              </div>
              <div className="card-back">
                <span className="card-word">{card.word}</span>
              </div>
            </div>
          </button>
        ))}
      </div>

      {/* New game button */}
      <button
        className="new-game-button"
        onClick={handlePlayAgain}
        type="button"
      >
        New Game
      </button>
    </div>
  )
}
