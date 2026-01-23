import { useState, useCallback, useRef } from 'react'
import './SpellingGame.css'
import LetterTile from './LetterTile'
import DropZone from './DropZone'
import { words, shuffleLetters } from '../game/words'
import { playCorrectSound, playWordCompleteSound } from '../game/sounds'

interface SpellingGameProps {
  onBack: () => void
}

interface PlacedLetter {
  letter: string
  tileId: string
}

// Celebration messages that rotate
const celebrationMessages = [
  { text: 'Great Job!', emoji: '🎉' },
  { text: 'Amazing!', emoji: '🌟' },
  { text: 'Awesome!', emoji: '✨' },
  { text: 'Super!', emoji: '🚀' },
  { text: 'Fantastic!', emoji: '💫' },
  { text: 'Wonderful!', emoji: '🎊' },
]

// Extra special messages for streaks
const streakMessages = [
  { streak: 3, text: 'On Fire!', emoji: '🔥' },
  { streak: 5, text: 'Unstoppable!', emoji: '⚡' },
  { streak: 7, text: 'Legendary!', emoji: '👑' },
  { streak: 10, text: 'Champion!', emoji: '🏆' },
]

// Dancing characters for celebration
const dancingCharacters = ['🎈', '⭐', '🌈', '🎀', '🦋', '🌸']

// Generate confetti positions once, outside component
function generateConfettiPositions(count: number = 40) {
  const shapes = ['square', 'circle', 'rectangle'] as const
  return Array.from({ length: count }).map((_, i) => ({
    id: i,
    left: `${Math.random() * 100}%`,
    delay: `${Math.random() * 0.6}s`,
    color: ['#ff6b6b', '#ffd43b', '#51cf66', '#4dabf7', '#cc5de8', '#ff922b', '#20c997'][i % 7],
    shape: shapes[i % 3],
    size: 8 + Math.random() * 8,
    duration: 1.2 + Math.random() * 0.8
  }))
}

const confettiPositions = generateConfettiPositions(40)

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
  const [correctZoneIndex, setCorrectZoneIndex] = useState<number | null>(null)
  const [showCelebration, setShowCelebration] = useState(false)
  const [wordsCompleted, setWordsCompleted] = useState(0)
  const [streak, setStreak] = useState(0)
  const [celebrationMessage, setCelebrationMessage] = useState(celebrationMessages[0])
  const [isStreakCelebration, setIsStreakCelebration] = useState(false)
  const zoneBoundsRef = useRef<Map<number, DOMRect>>(new Map())

  const currentWord = words[currentWordIndex]

  // Start a new word by advancing to next index
  const goToNextWord = useCallback((resetStreak: boolean = false) => {
    const nextIndex = (currentWordIndex + 1) % words.length
    setCurrentWordIndex(nextIndex)
    setShuffledLetters(getShuffledLetters(nextIndex))
    setPlacedLetters([null, null, null])
    setUsedTileIds(new Set())
    setShowCelebration(false)
    setWrongZoneIndex(null)
    setCorrectZoneIndex(null)
    setIsStreakCelebration(false)
    if (resetStreak) {
      setStreak(0)
    }
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

        // Trigger correct animation and sound
        setCorrectZoneIndex(targetZoneIndex)
        playCorrectSound()
        setTimeout(() => setCorrectZoneIndex(null), 800)

        // Check if word is complete
        const allPlaced = newPlaced.every(p => p !== null)
        if (allPlaced) {
          // Play word complete sound after a short delay
          setTimeout(() => playWordCompleteSound(), 300)
          const newStreak = streak + 1
          setStreak(newStreak)
          setWordsCompleted(prev => prev + 1)

          // Check for streak celebration
          const streakMsg = [...streakMessages].reverse().find(s => newStreak >= s.streak)
          if (streakMsg) {
            setCelebrationMessage({ text: streakMsg.text, emoji: streakMsg.emoji })
            setIsStreakCelebration(true)
          } else {
            // Random celebration message
            const randomMsg = celebrationMessages[Math.floor(Math.random() * celebrationMessages.length)]
            setCelebrationMessage(randomMsg)
            setIsStreakCelebration(false)
          }

          setShowCelebration(true)

          // Move to next word after celebration (longer for streak celebrations)
          const celebrationDuration = streakMsg ? 2500 : 2000
          setTimeout(() => {
            const nextIndex = (currentWordIndex + 1) % words.length
            setCurrentWordIndex(nextIndex)
            setShuffledLetters(getShuffledLetters(nextIndex))
            setPlacedLetters([null, null, null])
            setUsedTileIds(new Set())
            setShowCelebration(false)
            setWrongZoneIndex(null)
            setCorrectZoneIndex(null)
            setIsStreakCelebration(false)
          }, celebrationDuration)
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
    goToNextWord(true) // Reset streak when skipping
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
        <div className={`celebration-overlay ${isStreakCelebration ? 'streak-celebration' : ''}`}>
          <div className="celebration-content">
            {/* Dancing characters on sides */}
            <div className="dancing-characters">
              {dancingCharacters.slice(0, 3).map((char, i) => (
                <span key={`left-${i}`} className="dancing-char left" style={{ animationDelay: `${i * 0.15}s` }}>
                  {char}
                </span>
              ))}
            </div>
            <div className="dancing-characters right">
              {dancingCharacters.slice(3).map((char, i) => (
                <span key={`right-${i}`} className="dancing-char right" style={{ animationDelay: `${i * 0.15}s` }}>
                  {char}
                </span>
              ))}
            </div>

            {/* Main celebration emoji */}
            <span className={`celebration-emoji ${isStreakCelebration ? 'streak-emoji' : ''}`}>
              {celebrationMessage.emoji}
            </span>

            {/* Celebration text */}
            <h2 className={`celebration-text ${isStreakCelebration ? 'streak-text' : ''}`}>
              {celebrationMessage.text}
            </h2>

            {/* Streak indicator */}
            {streak > 1 && (
              <p className="streak-indicator">
                {streak} in a row! {'🔥'.repeat(Math.min(streak, 5))}
              </p>
            )}

            {/* Completed word */}
            <p className="celebration-word">{currentWord.word.toUpperCase()}</p>

            {/* Enhanced confetti */}
            <div className="confetti">
              {confettiPositions.map(({ id, left, delay, color, shape, size, duration }) => (
                <span
                  key={id}
                  className={`confetti-piece confetti-${shape}`}
                  style={{
                    left,
                    animationDelay: delay,
                    backgroundColor: color,
                    width: shape === 'rectangle' ? size * 0.5 : size,
                    height: shape === 'rectangle' ? size * 1.5 : size,
                    animationDuration: `${duration}s`
                  }}
                />
              ))}
            </div>

            {/* Extra fireworks for streaks */}
            {isStreakCelebration && (
              <div className="fireworks">
                {Array.from({ length: 12 }).map((_, i) => (
                  <span
                    key={i}
                    className="firework-particle"
                    style={{
                      '--angle': `${i * 30}deg`,
                      '--delay': `${Math.random() * 0.3}s`,
                      backgroundColor: ['#ff6b6b', '#ffd43b', '#51cf66', '#4dabf7'][i % 4]
                    } as React.CSSProperties}
                  />
                ))}
              </div>
            )}
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
            showCorrectAnimation={correctZoneIndex === index}
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
