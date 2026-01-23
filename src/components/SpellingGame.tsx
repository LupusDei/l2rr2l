import { useState, useCallback, useRef } from 'react'
import './SpellingGame.css'
import LetterTile from './LetterTile'
import DropZone from './DropZone'
import { words, shuffleLetters } from '../game/words'

interface SpellingGameProps {
  onBack: () => void
}

interface PlacedLetter {
  letter: string
  tileId: string
}

// Generate confetti positions once, outside component
function generateConfettiPositions() {
  return Array.from({ length: 20 }).map((_, i) => ({
    id: i,
    left: `${(i * 5) % 100}%`,
    delay: `${(i * 0.025) % 0.5}s`,
    color: ['#ff6b6b', '#ffd43b', '#51cf66', '#4dabf7', '#cc5de8'][i % 5]
  }))
}

const confettiPositions = generateConfettiPositions()

// Helper to get shuffled letters for a word
function getShuffledLetters(wordIndex: number): string[] {
  const word = words[wordIndex]
  const shuffled = shuffleLetters(word.word)
  // Ensure letters aren't in correct order
  if (shuffled.join('') === word.word) {
    shuffled.reverse()
  }
  return shuffled
}

export default function SpellingGame({ onBack }: SpellingGameProps) {
  // Use lazy initialization to avoid setState in effect
  const [currentWordIndex, setCurrentWordIndex] = useState(0)
  const [shuffledLetters, setShuffledLetters] = useState(() => getShuffledLetters(0))
  const [placedLetters, setPlacedLetters] = useState<(PlacedLetter | null)[]>([null, null, null])
  const [usedTileIds, setUsedTileIds] = useState<Set<string>>(new Set())
  const [draggedTile, setDraggedTile] = useState<{ id: string; letter: string } | null>(null)
  const [activeZoneIndex, setActiveZoneIndex] = useState<number | null>(null)
  const [wrongZoneIndex, setWrongZoneIndex] = useState<number | null>(null)
  const [showCelebration, setShowCelebration] = useState(false)
  const [wordsCompleted, setWordsCompleted] = useState(0)
  const zoneBoundsRef = useRef<Map<number, DOMRect>>(new Map())

  const currentWord = words[currentWordIndex]

  // Start a new word by advancing to next index
  const goToNextWord = useCallback(() => {
    const nextIndex = (currentWordIndex + 1) % words.length
    setCurrentWordIndex(nextIndex)
    setShuffledLetters(getShuffledLetters(nextIndex))
    setPlacedLetters([null, null, null])
    setUsedTileIds(new Set())
    setShowCelebration(false)
    setWrongZoneIndex(null)
  }, [currentWordIndex])

  const handleDragStart = (id: string, letter: string) => {
    setDraggedTile({ id, letter })
  }

  const handleDragEnd = useCallback(() => {
    if (!draggedTile) return

    // Check if over any drop zone
    const tileElement = document.querySelector(`[data-id="${draggedTile.id}"]`)
    if (!tileElement) {
      setDraggedTile(null)
      setActiveZoneIndex(null)
      return
    }

    const tileRect = tileElement.getBoundingClientRect()
    const tileCenterX = tileRect.left + tileRect.width / 2
    const tileCenterY = tileRect.top + tileRect.height / 2

    // Find which zone the tile is over
    let targetZoneIndex: number | null = null
    zoneBoundsRef.current.forEach((bounds, index) => {
      if (
        tileCenterX >= bounds.left &&
        tileCenterX <= bounds.right &&
        tileCenterY >= bounds.top &&
        tileCenterY <= bounds.bottom
      ) {
        targetZoneIndex = index
      }
    })

    if (targetZoneIndex !== null && placedLetters[targetZoneIndex] === null) {
      // Check if correct letter for this position
      const expectedLetter = currentWord.word[targetZoneIndex]
      if (draggedTile.letter === expectedLetter) {
        // Correct placement!
        const newPlaced = [...placedLetters]
        newPlaced[targetZoneIndex] = { letter: draggedTile.letter, tileId: draggedTile.id }
        setPlacedLetters(newPlaced)
        setUsedTileIds(prev => new Set([...prev, draggedTile.id]))

        // Check if word is complete
        const allPlaced = newPlaced.every(p => p !== null)
        if (allPlaced) {
          setShowCelebration(true)
          setWordsCompleted(prev => prev + 1)

          // Move to next word after celebration
          setTimeout(() => {
            const nextIndex = (currentWordIndex + 1) % words.length
            setCurrentWordIndex(nextIndex)
            setShuffledLetters(getShuffledLetters(nextIndex))
            setPlacedLetters([null, null, null])
            setUsedTileIds(new Set())
            setShowCelebration(false)
            setWrongZoneIndex(null)
          }, 2000)
        }
      } else {
        // Wrong position - trigger shake animation
        setWrongZoneIndex(targetZoneIndex)
        setTimeout(() => setWrongZoneIndex(null), 400)
      }
    }

    setDraggedTile(null)
    setActiveZoneIndex(null)
  }, [draggedTile, placedLetters, currentWord.word, currentWordIndex])

  const handleZoneBounds = useCallback((index: number, bounds: DOMRect) => {
    zoneBoundsRef.current.set(index, bounds)
  }, [])

  const handleSkip = () => {
    goToNextWord()
  }

  return (
    <div className="spelling-game">
      {/* Header */}
      <header className="spelling-header">
        <button className="back-button" onClick={onBack} type="button">
          ← Back
        </button>
        <div className="progress-indicator">
          ⭐ {wordsCompleted}
        </div>
      </header>

      {/* Celebration overlay */}
      {showCelebration && (
        <div className="celebration-overlay">
          <div className="celebration-content">
            <span className="celebration-emoji">🎉</span>
            <h2 className="celebration-text">Great Job!</h2>
            <p className="celebration-word">{currentWord.word.toUpperCase()}</p>
            <div className="confetti">
              {confettiPositions.map(({ id, left, delay, color }) => (
                <span
                  key={id}
                  className="confetti-piece"
                  style={{
                    left,
                    animationDelay: delay,
                    backgroundColor: color
                  }}
                />
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Word hint */}
      <div className="word-hint">
        <div className="hint-image">{currentWord.image}</div>
        <p className="hint-text">Spell the word!</p>
      </div>

      {/* Drop zones */}
      <div className="drop-zones">
        {[0, 1, 2].map(index => (
          <DropZone
            key={index}
            index={index}
            expectedLetter={currentWord.word[index]}
            currentLetter={placedLetters[index]?.letter || null}
            isActive={activeZoneIndex === index}
            onGetBounds={handleZoneBounds}
            showWrongAnimation={wrongZoneIndex === index}
          />
        ))}
      </div>

      {/* Letter tiles */}
      <div className="letter-tiles">
        {shuffledLetters.map((letter, index) => {
          const tileId = `tile-${index}`
          const isUsed = usedTileIds.has(tileId)
          return (
            <LetterTile
              key={tileId}
              id={tileId}
              letter={letter}
              onDragStart={handleDragStart}
              onDragEnd={handleDragEnd}
              disabled={isUsed}
              placed={isUsed}
            />
          )
        })}
      </div>

      {/* Skip button */}
      <button className="skip-button" onClick={handleSkip} type="button">
        Skip →
      </button>
    </div>
  )
}
