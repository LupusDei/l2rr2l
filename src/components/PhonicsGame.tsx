import { useState, useEffect, useCallback } from 'react'
import { useVoice } from '../hooks/useVoice'
import { getRandomPhonicsWords, getBeginningSounds, type PhonicsWord } from '../game-data/phonics'
import { playCorrectSound, playWordCompleteSound } from '../game/sounds'
import './PhonicsGame.css'

interface PhonicsGameProps {
  onBack: () => void
}

interface GameState {
  currentWord: PhonicsWord | null
  options: string[]
  score: number
  streak: number
  round: number
  totalRounds: number
  isCorrect: boolean | null
  showFeedback: boolean
  gameComplete: boolean
  selectedSound: string | null
  isSpeaking: boolean
  showCelebration: boolean
}

const ENCOURAGEMENTS = [
  "Great job!", "You got it!", "Awesome!", "Perfect!",
  "Amazing!", "Fantastic!", "Super star!", "Well done!"
]

const CELEBRATIONS = [
  { text: "You're a phonics champion!", emoji: '🏆' },
  { text: "Incredible work!", emoji: '🌟' },
  { text: "You really know your sounds!", emoji: '🎉' },
  { text: "Keep up the great work!", emoji: '✨' },
  { text: "Sound superstar!", emoji: '🚀' },
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

export default function PhonicsGame({ onBack }: PhonicsGameProps) {
  const { speak, settings } = useVoice()
  const [celebrationMessage, setCelebrationMessage] = useState(CELEBRATIONS[0])
  const [gameState, setGameState] = useState<GameState>({
    currentWord: null,
    options: [],
    score: 0,
    streak: 0,
    round: 0,
    totalRounds: 10,
    isCorrect: null,
    showFeedback: false,
    gameComplete: false,
    selectedSound: null,
    isSpeaking: false,
    showCelebration: false,
  })

  const generateRound = useCallback(() => {
    const words = getRandomPhonicsWords(1, { difficulty: 1 })
    if (words.length === 0) return

    const currentWord = words[0]
    const allSounds = getBeginningSounds()

    // Get 3 wrong options
    const wrongOptions = allSounds
      .filter(s => s !== currentWord.beginningSound)
      .sort(() => Math.random() - 0.5)
      .slice(0, 3)

    // Combine and shuffle
    const options = [...wrongOptions, currentWord.beginningSound]
      .sort(() => Math.random() - 0.5)

    setGameState(prev => ({
      ...prev,
      currentWord,
      options,
      isCorrect: null,
      showFeedback: false,
      selectedSound: null,
      isSpeaking: false,
    }))

    // Speak the word
    if (settings.enabled) {
      setTimeout(() => {
        setGameState(prev => ({ ...prev, isSpeaking: true }))
        speak(`What sound does ${currentWord.word} start with?`).then(() => {
          setGameState(prev => ({ ...prev, isSpeaking: false }))
        })
      }, 500)
    }
  }, [speak, settings.enabled])

  useEffect(() => {
    if (!gameState.gameComplete && !gameState.currentWord) {
      generateRound()
    }
  }, [generateRound, gameState.gameComplete, gameState.currentWord])

  const handleAnswer = async (sound: string) => {
    if (gameState.showFeedback || !gameState.currentWord) return

    const isCorrect = sound === gameState.currentWord.beginningSound

    // Play sound effect immediately
    if (isCorrect) {
      playCorrectSound()
    }

    setGameState(prev => ({
      ...prev,
      isCorrect,
      showFeedback: true,
      selectedSound: sound,
      score: isCorrect ? prev.score + (10 * (prev.streak + 1)) : prev.score,
      streak: isCorrect ? prev.streak + 1 : 0,
    }))

    if (settings.enabled && settings.encouragementEnabled) {
      if (isCorrect) {
        const msg = ENCOURAGEMENTS[Math.floor(Math.random() * ENCOURAGEMENTS.length)]
        await speak(msg)
      } else {
        await speak(`The word ${gameState.currentWord.word} starts with ${gameState.currentWord.beginningSound}`)
      }
    }

    // Move to next round after delay
    setTimeout(() => {
      const nextRound = gameState.round + 1
      if (nextRound >= gameState.totalRounds) {
        playWordCompleteSound()
        const celebration = CELEBRATIONS[Math.floor(Math.random() * CELEBRATIONS.length)]
        setCelebrationMessage(celebration)
        setGameState(prev => ({ ...prev, gameComplete: true, showCelebration: true }))
        if (settings.enabled) {
          speak(celebration.text)
        }
      } else {
        setGameState(prev => ({
          ...prev,
          round: nextRound,
          currentWord: null,
          selectedSound: null,
        }))
      }
    }, 1500)
  }

  const handlePlayAgain = () => {
    setGameState({
      currentWord: null,
      options: [],
      score: 0,
      streak: 0,
      round: 0,
      totalRounds: 10,
      isCorrect: null,
      showFeedback: false,
      gameComplete: false,
      selectedSound: null,
      isSpeaking: false,
      showCelebration: false,
    })
  }

  const handleRepeatWord = () => {
    if (gameState.currentWord && settings.enabled) {
      setGameState(prev => ({ ...prev, isSpeaking: true }))
      speak(gameState.currentWord.word).then(() => {
        setGameState(prev => ({ ...prev, isSpeaking: false }))
      })
    }
  }

  const speakSound = (sound: string) => {
    if (settings.enabled) {
      speak(`${sound} says ${sound}`)
    }
  }

  if (gameState.gameComplete) {
    return (
      <div className="phonics-game">
        {gameState.showCelebration && (
          <div className="celebration-overlay">
            <div className="celebration-content">
              <span className="celebration-emoji">{celebrationMessage.emoji}</span>
              <h2 className="celebration-text">{celebrationMessage.text}</h2>
              <p className="celebration-stats">
                Score: {gameState.score}
              </p>
              <p className="rounds-info">You completed {gameState.totalRounds} rounds!</p>
              <div className="complete-buttons">
                <button className="play-again-btn" onClick={handlePlayAgain} type="button">
                  Play Again
                </button>
                <button className="back-btn" onClick={onBack} type="button">
                  Back to Home
                </button>
              </div>
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
      </div>
    )
  }

  return (
    <div className="phonics-game">
      <header className="game-header">
        <button className="back-button" onClick={onBack} type="button">
          ← Back
        </button>
        <h1>Phonics Game</h1>
        <div className="game-stats">
          <span className="score">Score: {gameState.score}</span>
          <span className="streak">🔥 {gameState.streak}</span>
          <span className="round">Round {gameState.round + 1}/{gameState.totalRounds}</span>
        </div>
      </header>

      <main className="game-content">
        {gameState.currentWord && (
          <>
            <div className="word-display">
              <span className="word-emoji">{gameState.currentWord.emoji}</span>
              <h2 className="current-word">
                <span className={`first-letter ${gameState.showFeedback && gameState.isCorrect ? 'highlight' : ''}`}>
                  {gameState.currentWord.word.charAt(0).toUpperCase()}
                </span>
                {gameState.currentWord.word.slice(1)}
              </h2>
              <button
                className={`repeat-btn ${gameState.isSpeaking ? 'speaking' : ''}`}
                onClick={handleRepeatWord}
                type="button"
              >
                <span className="sound-icon">🔊</span>
                <span className="sound-waves">
                  <span className="wave"></span>
                  <span className="wave"></span>
                  <span className="wave"></span>
                </span>
                Hear Word
              </button>
            </div>

            <p className="instruction">What sound does this word start with?</p>

            <div className="options-grid">
              {gameState.options.map((sound) => {
                const isCorrectSound = sound === gameState.currentWord?.beginningSound
                const isSelected = sound === gameState.selectedSound
                const showAsCorrect = gameState.showFeedback && isCorrectSound
                const showAsWrong = gameState.showFeedback && isSelected && !isCorrectSound

                return (
                  <button
                    key={sound}
                    className={`option-btn ${showAsCorrect ? 'correct' : ''} ${showAsWrong ? 'wrong' : ''}`}
                    onClick={() => handleAnswer(sound)}
                    onMouseEnter={() => !gameState.showFeedback && speakSound(sound)}
                    disabled={gameState.showFeedback}
                    type="button"
                  >
                    <span className="sound-letter">{sound.toUpperCase()}</span>
                    {showAsCorrect && <span className="check-mark">✓</span>}
                    {showAsWrong && <span className="wrong-mark">✗</span>}
                  </button>
                )
              })}
            </div>

            {gameState.showFeedback && (
              <div className={`feedback ${gameState.isCorrect ? 'correct' : 'incorrect'}`}>
                {gameState.isCorrect ? (
                  <span className="feedback-content">
                    <span className="feedback-icon">✓</span>
                    Correct! "{gameState.currentWord.beginningSound}" makes the {gameState.currentWord.beginningSound} sound!
                  </span>
                ) : (
                  <span className="feedback-content">
                    <span className="feedback-icon">💡</span>
                    "{gameState.currentWord.word}" starts with the "{gameState.currentWord.beginningSound}" sound
                  </span>
                )}
              </div>
            )}
          </>
        )}
      </main>
    </div>
  )
}
