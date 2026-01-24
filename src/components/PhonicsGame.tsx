import { useState, useEffect, useCallback } from 'react'
import { useVoice } from '../hooks/useVoice'
import { getRandomPhonicsWords, getBeginningSounds, type PhonicsWord } from '../game-data/phonics'
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
}

const ENCOURAGEMENTS = [
  "Great job!", "You got it!", "Awesome!", "Perfect!",
  "Amazing!", "Fantastic!", "Super star!", "Well done!"
]

const CELEBRATIONS = [
  "You're a phonics champion!", "Incredible work!",
  "You really know your sounds!", "Keep up the great work!"
]

export default function PhonicsGame({ onBack }: PhonicsGameProps) {
  const { speak, settings } = useVoice()
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
    }))

    // Speak the word
    if (settings.enabled) {
      setTimeout(() => {
        speak(`What sound does ${currentWord.word} start with?`)
      }, 500)
    }
  }, [speak, settings.enabled])

  useEffect(() => {
    if (!gameState.gameComplete && !gameState.currentWord) {
      generateRound()
    }
  }, [generateRound, gameState.gameComplete, gameState.currentWord])

  const handleAnswer = async (selectedSound: string) => {
    if (gameState.showFeedback || !gameState.currentWord) return

    const isCorrect = selectedSound === gameState.currentWord.beginningSound

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
        await speak(`The word ${gameState.currentWord.word} starts with ${gameState.currentWord.beginningSound}`)
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
          currentWord: null,
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
    })
  }

  const handleRepeatWord = () => {
    if (gameState.currentWord && settings.enabled) {
      speak(gameState.currentWord.word)
    }
  }

  if (gameState.gameComplete) {
    return (
      <div className="phonics-game">
        <div className="game-complete">
          <div className="celebration-icon">🎉</div>
          <h2>Great Job!</h2>
          <p className="final-score">Score: {gameState.score}</p>
          <p className="rounds-info">You completed {gameState.totalRounds} rounds!</p>
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
              <h2 className="current-word">{gameState.currentWord.word}</h2>
              <button className="repeat-btn" onClick={handleRepeatWord} type="button">
                🔊 Hear Word
              </button>
            </div>

            <p className="instruction">What sound does this word start with?</p>

            <div className="options-grid">
              {gameState.options.map((sound) => (
                <button
                  key={sound}
                  className={`option-btn ${
                    gameState.showFeedback
                      ? sound === gameState.currentWord?.beginningSound
                        ? 'correct'
                        : gameState.isCorrect === false && sound === gameState.options.find(o => o !== gameState.currentWord?.beginningSound)
                          ? ''
                          : ''
                      : ''
                  } ${gameState.showFeedback && sound === gameState.currentWord?.beginningSound ? 'correct' : ''}`}
                  onClick={() => handleAnswer(sound)}
                  disabled={gameState.showFeedback}
                  type="button"
                >
                  {sound.toUpperCase()}
                </button>
              ))}
            </div>

            {gameState.showFeedback && (
              <div className={`feedback ${gameState.isCorrect ? 'correct' : 'incorrect'}`}>
                {gameState.isCorrect ? '✓ Correct!' : `✗ It starts with "${gameState.currentWord.beginningSound}"`}
              </div>
            )}
          </>
        )}
      </main>
    </div>
  )
}
