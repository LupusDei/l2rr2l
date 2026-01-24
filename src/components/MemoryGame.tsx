import { useState, useCallback, useEffect, useRef } from 'react'
import './MemoryGame.css'
import MemoryCard from './MemoryCard'
import {
  type SightWord,
  type GridConfig,
  gridConfigs,
  getMemoryGameWords,
  shuffleArray,
} from '../game/sightWords'
import { playCorrectSound, playWordCompleteSound } from '../game/sounds'
import { useVoice } from '../hooks/useVoice'

interface MemoryGameProps {
  onBack: () => void
  difficulty?: 'easy' | 'medium' | 'hard'
  wordLevel?: SightWord['level']
}

interface Card {
  id: string
  word: string
  pairId: number
}

// Celebration messages
const celebrationMessages = [
  { text: 'Great Match!', emoji: '🎉' },
  { text: 'Perfect!', emoji: '🌟' },
  { text: 'Awesome!', emoji: '✨' },
  { text: 'Nice Find!', emoji: '🔍' },
  { text: 'Super!', emoji: '🚀' },
]

// Game complete messages
const gameCompleteMessages = [
  { text: 'You Did It!', emoji: '🏆' },
  { text: 'Champion!', emoji: '👑' },
  { text: 'Amazing!', emoji: '🎊' },
]

export default function MemoryGame({
  onBack,
  difficulty = 'easy',
  wordLevel = 'pre-primer',
}: MemoryGameProps) {
  const { speak } = useVoice()

  const gridConfig: GridConfig = gridConfigs[difficulty]

  // Initialize cards
  const [cards, setCards] = useState<Card[]>(() => {
    const words = getMemoryGameWords(wordLevel, gridConfig.pairs)
    const cardPairs: Card[] = []

    words.forEach((sightWord, index) => {
      // Create two cards for each word (a pair)
      cardPairs.push({
        id: `card-${index}-a`,
        word: sightWord.word,
        pairId: index,
      })
      cardPairs.push({
        id: `card-${index}-b`,
        word: sightWord.word,
        pairId: index,
      })
    })

    return shuffleArray(cardPairs)
  })

  const [flippedCards, setFlippedCards] = useState<string[]>([])
  const [matchedPairs, setMatchedPairs] = useState<Set<number>>(new Set())
  const [isChecking, setIsChecking] = useState(false)
  const [moves, setMoves] = useState(0)
  const [matchCount, setMatchCount] = useState(0)
  const [showMatchCelebration, setShowMatchCelebration] = useState(false)
  const [celebrationMessage, setCelebrationMessage] = useState(celebrationMessages[0])
  const [showGameComplete, setShowGameComplete] = useState(false)
  const [gameCompleteMessage, setGameCompleteMessage] = useState(gameCompleteMessages[0])

  const hasAnnouncedRef = useRef(false)

  // Announce game start
  useEffect(() => {
    if (!hasAnnouncedRef.current) {
      hasAnnouncedRef.current = true
      setTimeout(() => {
        speak('Find the matching words!')
      }, 500)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  // Check for game completion
  useEffect(() => {
    if (matchedPairs.size === gridConfig.pairs && matchedPairs.size > 0) {
      setTimeout(() => {
        const randomMsg = gameCompleteMessages[Math.floor(Math.random() * gameCompleteMessages.length)]
        setGameCompleteMessage(randomMsg)
        setShowGameComplete(true)
        playWordCompleteSound()
        speak(`${randomMsg.text} You found all the matches!`)
      }, 600)
    }
  }, [matchedPairs, gridConfig.pairs, speak])

  const handleCardClick = useCallback((cardId: string) => {
    if (isChecking) return
    if (flippedCards.includes(cardId)) return

    const clickedCard = cards.find(c => c.id === cardId)
    if (!clickedCard) return
    if (matchedPairs.has(clickedCard.pairId)) return

    // Speak the word when flipped
    speak(clickedCard.word)

    const newFlipped = [...flippedCards, cardId]
    setFlippedCards(newFlipped)

    if (newFlipped.length === 2) {
      setMoves(prev => prev + 1)
      setIsChecking(true)

      const [firstId, secondId] = newFlipped
      const firstCard = cards.find(c => c.id === firstId)
      const secondCard = cards.find(c => c.id === secondId)

      if (firstCard && secondCard && firstCard.pairId === secondCard.pairId) {
        // Match found!
        setTimeout(() => {
          playCorrectSound()
          setMatchedPairs(prev => new Set([...prev, firstCard.pairId]))
          setMatchCount(prev => prev + 1)
          setFlippedCards([])
          setIsChecking(false)

          // Show match celebration
          const randomMsg = celebrationMessages[Math.floor(Math.random() * celebrationMessages.length)]
          setCelebrationMessage(randomMsg)
          setShowMatchCelebration(true)
          setTimeout(() => setShowMatchCelebration(false), 1000)
        }, 500)
      } else {
        // No match - flip cards back after delay
        setTimeout(() => {
          setFlippedCards([])
          setIsChecking(false)
        }, 1200)
      }
    }
  }, [cards, flippedCards, isChecking, matchedPairs, speak])

  const handlePlayAgain = useCallback(() => {
    const words = getMemoryGameWords(wordLevel, gridConfig.pairs)
    const cardPairs: Card[] = []

    words.forEach((sightWord, index) => {
      cardPairs.push({
        id: `card-${index}-a-${Date.now()}`,
        word: sightWord.word,
        pairId: index,
      })
      cardPairs.push({
        id: `card-${index}-b-${Date.now()}`,
        word: sightWord.word,
        pairId: index,
      })
    })

    setCards(shuffleArray(cardPairs))
    setFlippedCards([])
    setMatchedPairs(new Set())
    setIsChecking(false)
    setMoves(0)
    setMatchCount(0)
    setShowGameComplete(false)

    setTimeout(() => {
      speak('Find the matching words!')
    }, 300)
  }, [wordLevel, gridConfig.pairs, speak])

  return (
    <div className="memory-game">
      {/* Header */}
      <header className="memory-header">
        <button className="back-button" onClick={onBack} type="button">
          <span aria-hidden="true">&#8592;</span> Back
        </button>
        <div className="memory-stats">
          <span className="memory-stat">
            <span className="stat-icon" aria-hidden="true">&#9733;</span>
            <span className="stat-value">{matchCount}</span>
          </span>
          <span className="memory-stat">
            <span className="stat-icon" aria-hidden="true">&#128065;</span>
            <span className="stat-value">{moves}</span>
          </span>
        </div>
      </header>

      {/* Instructions */}
      <div className="memory-instructions">
        <p>Find the matching words!</p>
      </div>

      {/* Match celebration toast */}
      {showMatchCelebration && (
        <div className="match-toast" aria-live="polite">
          <span className="match-toast-emoji">{celebrationMessage.emoji}</span>
          <span className="match-toast-text">{celebrationMessage.text}</span>
        </div>
      )}

      {/* Card grid */}
      <div
        className="memory-grid"
        style={{
          gridTemplateColumns: `repeat(${gridConfig.cols}, 1fr)`,
          gridTemplateRows: `repeat(${gridConfig.rows}, 1fr)`,
        }}
        role="grid"
        aria-label="Memory game card grid"
      >
        {cards.map(card => (
          <MemoryCard
            key={card.id}
            id={card.id}
            word={card.word}
            isFlipped={flippedCards.includes(card.id)}
            isMatched={matchedPairs.has(card.pairId)}
            onClick={handleCardClick}
            disabled={isChecking}
          />
        ))}
      </div>

      {/* Game complete overlay */}
      {showGameComplete && (
        <div className="game-complete-overlay">
          <div className="game-complete-content">
            <span className="game-complete-emoji">{gameCompleteMessage.emoji}</span>
            <h2 className="game-complete-text">{gameCompleteMessage.text}</h2>
            <p className="game-complete-stats">
              You found all {gridConfig.pairs} pairs in {moves} moves!
            </p>
            <div className="game-complete-actions">
              <button
                className="play-again-button"
                onClick={handlePlayAgain}
                type="button"
              >
                Play Again
              </button>
              <button
                className="back-home-button"
                onClick={onBack}
                type="button"
              >
                Back to Home
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
