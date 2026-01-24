import { useState, useCallback, useEffect, useRef } from 'react'
import './WordBuilder.css'
import {
  getRandomFamily,
  getGameLetters,
  isValidWord,
  buildWord,
  type WordFamily,
  type BuiltWord,
} from '../game/wordFamilies'
import { playCorrectSound, playWordCompleteSound } from '../game/sounds'
import { useVoice } from '../hooks/useVoice'

interface WordBuilderProps {
  onBack: () => void
  level?: 1 | 2 | 3
}

// Celebration messages
const celebrationMessages = [
  { text: 'Great Build!', emoji: '🏭' },
  { text: 'Word Made!', emoji: '🎉' },
  { text: 'Factory Star!', emoji: '⭐' },
  { text: 'Super Builder!', emoji: '🔧' },
  { text: 'Word Power!', emoji: '⚡' },
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

export default function WordBuilder({ onBack, level = 1 }: WordBuilderProps) {
  const { speak, isSpeaking } = useVoice()
  const [currentFamily, setCurrentFamily] = useState<WordFamily>(() => getRandomFamily(level))
  const [gameLetters, setGameLetters] = useState<string[]>(() => getGameLetters(currentFamily))
  const [selectedLetter, setSelectedLetter] = useState<string | null>(null)
  const [builtWords, setBuiltWords] = useState<BuiltWord[]>([])
  const [showCelebration, setShowCelebration] = useState(false)
  const [celebrationMessage, setCelebrationMessage] = useState(celebrationMessages[0])
  const [lastBuiltWord, setLastBuiltWord] = useState<string | null>(null)
  const [conveyorActive, setConveyorActive] = useState(false)
  const [treasureGlow, setTreasureGlow] = useState(false)
  const [wrongLetter, setWrongLetter] = useState<string | null>(null)
  const [wordsThisRound, setWordsThisRound] = useState(0)
  const hasAnnouncedRef = useRef(false)

  // Announce game start
  useEffect(() => {
    if (!hasAnnouncedRef.current) {
      hasAnnouncedRef.current = true
      const timer = setTimeout(() => {
        speak(`Build words that end with ${currentFamily.ending}!`)
      }, 500)
      return () => clearTimeout(timer)
    }
  }, [currentFamily.ending, speak])

  // Start a new round with a different word family
  const newRound = useCallback(() => {
    const newFamily = getRandomFamily(level)
    setCurrentFamily(newFamily)
    setGameLetters(getGameLetters(newFamily))
    setSelectedLetter(null)
    setWordsThisRound(0)
    setTimeout(() => {
      speak(`Now build words that end with ${newFamily.ending}!`)
    }, 300)
  }, [level, speak])

  // Handle letter button tap
  const handleLetterTap = useCallback((letter: string) => {
    if (selectedLetter === letter) {
      // Deselect
      setSelectedLetter(null)
      return
    }

    setSelectedLetter(letter)

    // Check if valid word
    if (isValidWord(letter, currentFamily)) {
      const word = buildWord(letter, currentFamily.ending)
      setLastBuiltWord(word)

      // Animate conveyor
      setConveyorActive(true)
      playCorrectSound()

      // Speak the word
      speak(word)

      // After conveyor animation, add to treasure
      setTimeout(() => {
        setConveyorActive(false)
        setTreasureGlow(true)
        playWordCompleteSound()

        // Add to built words collection
        setBuiltWords(prev => {
          const alreadyBuilt = prev.some(w => w.word === word)
          if (!alreadyBuilt) {
            return [...prev, { word, family: currentFamily.ending }]
          }
          return prev
        })

        setWordsThisRound(prev => prev + 1)
        setSelectedLetter(null)
        setLastBuiltWord(null)

        // Show celebration
        const msg = celebrationMessages[Math.floor(Math.random() * celebrationMessages.length)]
        setCelebrationMessage(msg)
        setShowCelebration(true)

        setTimeout(() => {
          setTreasureGlow(false)
          setShowCelebration(false)

          // After building enough words, offer new round
          if (wordsThisRound >= 4) {
            setTimeout(() => {
              speak('Great job! Try a new word family!')
              newRound()
            }, 500)
          }
        }, 1500)
      }, 1200)
    } else {
      // Wrong letter - shake and clear
      setWrongLetter(letter)
      setTimeout(() => {
        setWrongLetter(null)
        setSelectedLetter(null)
      }, 500)
    }
  }, [selectedLetter, currentFamily, speak, wordsThisRound, newRound])

  // Handle repeat button
  const handleRepeat = useCallback(() => {
    speak(`Build words that end with ${currentFamily.ending}`)
  }, [speak, currentFamily.ending])

  return (
    <div className="word-builder">
      {/* Factory background decorations */}
      <div className="factory-bg" aria-hidden="true">
        <div className="gear gear-1"></div>
        <div className="gear gear-2"></div>
        <div className="gear gear-3"></div>
        <div className="pipe pipe-left"></div>
        <div className="pipe pipe-right"></div>
        <div className="smoke smoke-1"></div>
        <div className="smoke smoke-2"></div>
      </div>

      {/* Header */}
      <header className="builder-header">
        <button className="back-button" onClick={onBack} type="button">
          &#8592; Back
        </button>
        <button
          className="repeat-button"
          onClick={handleRepeat}
          disabled={isSpeaking}
          type="button"
          aria-label="Repeat instructions"
        >
          &#128266;
        </button>
        <div className="word-counter">
          &#9733; {builtWords.length} words
        </div>
      </header>

      {/* Celebration overlay */}
      {showCelebration && (
        <div className="celebration-overlay">
          <div className="celebration-content">
            <span className="celebration-emoji">{celebrationMessage.emoji}</span>
            <h2 className="celebration-text">{celebrationMessage.text}</h2>
            {lastBuiltWord && (
              <p className="celebration-word">{lastBuiltWord.toUpperCase()}</p>
            )}
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

      {/* Word ending display */}
      <div className="word-ending-zone">
        <div className="ending-machine">
          <div className="machine-frame">
            <span className="ending-label">Word Ending</span>
            <div className="ending-display">
              <span className="dash">-</span>
              <span className="ending">{currentFamily.ending}</span>
            </div>
          </div>
        </div>
      </div>

      {/* Build zone with conveyor */}
      <div className="build-zone">
        <div className={`conveyor-belt ${conveyorActive ? 'active' : ''}`}>
          <div className="conveyor-track">
            <div className="track-lines"></div>
          </div>

          {/* Word being built */}
          <div className={`word-box ${conveyorActive ? 'moving' : ''}`}>
            {selectedLetter && (
              <span className="built-letter">{selectedLetter.toUpperCase()}</span>
            )}
            <span className="built-ending">{currentFamily.ending}</span>
          </div>
        </div>

        {/* Treasure chest */}
        <div className={`treasure-chest ${treasureGlow ? 'glowing' : ''}`}>
          <div className="chest-lid"></div>
          <div className="chest-body">
            <span className="chest-icon">&#128230;</span>
          </div>
          {treasureGlow && <div className="chest-sparkle"></div>}
        </div>
      </div>

      {/* Letter selection tiles */}
      <div className="letter-factory">
        <div className="factory-sign">
          <span className="sign-text">Pick a Letter!</span>
        </div>
        <div className="letter-tiles-container">
          {gameLetters.map((letter, index) => (
            <button
              key={`${letter}-${index}`}
              className={`factory-tile ${selectedLetter === letter ? 'selected' : ''} ${wrongLetter === letter ? 'wrong' : ''}`}
              onClick={() => handleLetterTap(letter)}
              disabled={conveyorActive}
              type="button"
              aria-label={`Letter ${letter.toUpperCase()}`}
            >
              <span className="tile-letter">{letter.toUpperCase()}</span>
              <div className="tile-shadow"></div>
            </button>
          ))}
        </div>
      </div>

      {/* Word collection display */}
      {builtWords.length > 0 && (
        <div className="word-collection">
          <div className="collection-header">
            <span className="collection-icon">&#128081;</span>
            <span className="collection-title">Your Words</span>
          </div>
          <div className="word-list">
            {builtWords.slice(-8).map((item, index) => (
              <span key={`${item.word}-${index}`} className="collected-word">
                {item.word}
              </span>
            ))}
          </div>
        </div>
      )}

      {/* New round button */}
      <button
        className="new-round-button"
        onClick={newRound}
        type="button"
      >
        New Word Family
      </button>
    </div>
  )
}
