import { useState, useCallback, useEffect } from 'react'
import { useVoice, type PronunciationResult } from '../hooks/useVoice'
import { getRandomWords, type SightWordLevel, sightWordLevels } from '../game-data/sight-words'
import Confetti from './Confetti'
import './ReadAloudGame.css'

interface ReadAloudGameProps {
  onBack: () => void
}

interface GameState {
  currentWord: string
  score: number
  streak: number
  bestStreak: number
  round: number
  totalRounds: number
  result: PronunciationResult | null
  showFeedback: boolean
  gameComplete: boolean
  level: SightWordLevel
  showConfetti: boolean
}

const ENCOURAGEMENTS = [
  "Great reading!", "You got it!", "Perfect!",
  "Amazing!", "Super reader!", "Well done!"
]

const CELEBRATIONS = [
  "You're a reading champion!", "Incredible work!",
  "You're reading so well!", "Keep up the great work!"
]

const MILESTONE_MESSAGES: { [key: number]: string } = {
  3: 'Three in a row! Amazing!',
  5: 'Five streak! Unstoppable!',
  7: 'Seven perfect! Reading star!',
  10: 'Perfect 10! Reading superstar!',
}

export default function ReadAloudGame({ onBack }: ReadAloudGameProps) {
  const { speak, settings, isRecording, startRecording, checkPronunciation } = useVoice()
  const [gameState, setGameState] = useState<GameState>({
    currentWord: '',
    score: 0,
    streak: 0,
    bestStreak: 0,
    round: 0,
    totalRounds: 10,
    result: null,
    showFeedback: false,
    gameComplete: false,
    level: 'pre-primer',
    showConfetti: false,
  })
  const [isProcessing, setIsProcessing] = useState(false)

  const generateRound = useCallback((level: SightWordLevel) => {
    const words = getRandomWords(level, 1)
    if (words.length === 0) return

    const currentWord = words[0]

    setGameState(prev => ({
      ...prev,
      currentWord,
      result: null,
      showFeedback: false,
    }))

    // Speak the instruction
    if (settings.enabled) {
      setTimeout(() => {
        speak(`Can you read the word: ${currentWord}?`)
      }, 500)
    }
  }, [speak, settings.enabled])

  useEffect(() => {
    if (!gameState.gameComplete && !gameState.currentWord) {
      generateRound(gameState.level)
    }
  }, [generateRound, gameState.gameComplete, gameState.currentWord, gameState.level])

  const handleMicClick = useCallback(async () => {
    if (isRecording) {
      // Stop recording and check pronunciation
      setIsProcessing(true)
      const result = await checkPronunciation(gameState.currentWord)
      setIsProcessing(false)

      if (result) {
        const isCorrect = result.isCorrect
        const newStreak = isCorrect ? gameState.streak + 1 : 0
        const isMilestone = isCorrect && MILESTONE_MESSAGES[newStreak]
        const triggerConfetti = isCorrect && (newStreak >= 3 || isMilestone)

        setGameState(prev => ({
          ...prev,
          result,
          showFeedback: true,
          score: isCorrect ? prev.score + (10 * (prev.streak + 1)) : prev.score,
          streak: newStreak,
          bestStreak: Math.max(prev.bestStreak, newStreak),
          showConfetti: triggerConfetti,
        }))

        if (settings.enabled && settings.encouragementEnabled) {
          if (isCorrect) {
            // Check for milestone celebration first
            if (isMilestone) {
              await speak(MILESTONE_MESSAGES[newStreak])
            } else {
              const msg = ENCOURAGEMENTS[Math.floor(Math.random() * ENCOURAGEMENTS.length)]
              await speak(msg)
            }
          } else {
            await speak(result.feedback)
          }
        }

        // Move to next round after delay
        setTimeout(() => {
          const nextRound = gameState.round + 1
          if (nextRound >= gameState.totalRounds) {
            setGameState(prev => ({ ...prev, gameComplete: true, showConfetti: true }))
            if (settings.enabled) {
              const celebration = CELEBRATIONS[Math.floor(Math.random() * CELEBRATIONS.length)]
              speak(celebration)
            }
          } else {
            setGameState(prev => ({
              ...prev,
              round: nextRound,
              currentWord: '',
              showConfetti: false,
            }))
          }
        }, 2000)
      }
    } else {
      // Start recording
      try {
        await startRecording()
      } catch {
        // Error handled by useVoice hook
      }
    }
  }, [isRecording, checkPronunciation, gameState.currentWord, gameState.round, gameState.totalRounds, settings, speak, startRecording])

  const handlePlayAgain = () => {
    setGameState({
      currentWord: '',
      score: 0,
      streak: 0,
      bestStreak: 0,
      round: 0,
      totalRounds: 10,
      result: null,
      showFeedback: false,
      gameComplete: false,
      level: gameState.level,
      showConfetti: false,
    })
  }

  const handleLevelChange = (level: SightWordLevel) => {
    setGameState(prev => ({
      ...prev,
      level,
      currentWord: '',
      result: null,
      showFeedback: false,
    }))
  }

  const handleRepeatWord = () => {
    if (gameState.currentWord && settings.enabled) {
      speak(gameState.currentWord)
    }
  }

  const handleSkip = () => {
    const nextRound = gameState.round + 1
    if (nextRound >= gameState.totalRounds) {
      setGameState(prev => ({ ...prev, gameComplete: true }))
    } else {
      setGameState(prev => ({
        ...prev,
        round: nextRound,
        currentWord: '',
        streak: 0,
      }))
    }
  }

  if (gameState.gameComplete) {
    return (
      <div className="read-aloud-game">
        <Confetti active={gameState.showConfetti} duration={4000} pieceCount={100} />
        <div className="game-complete">
          <div className="celebration-icon">🏆</div>
          <h2>Amazing Reading!</h2>
          <p className="final-score">Score: {gameState.score}</p>
          <div className="stats-row">
            <div className="stat-item">
              <span className="stat-value">{gameState.totalRounds}</span>
              <span className="stat-label">Words Read</span>
            </div>
            <div className="stat-item">
              <span className="stat-value">{gameState.bestStreak}</span>
              <span className="stat-label">Best Streak</span>
            </div>
          </div>
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

  // Handle confetti completion
  const handleConfettiComplete = () => {
    if (!gameState.gameComplete) {
      setGameState(prev => ({ ...prev, showConfetti: false }))
    }
  }

  return (
    <div className="read-aloud-game">
      <Confetti
        active={gameState.showConfetti}
        duration={2000}
        pieceCount={50}
        onComplete={handleConfettiComplete}
      />
      <header className="game-header">
        <button className="back-button" onClick={onBack} type="button">
          ← Back
        </button>
        <h1>Read Aloud</h1>
        <div className="game-stats">
          <span className="score">Score: {gameState.score}</span>
          <span className="streak">🔥 {gameState.streak}</span>
          <span className="round">Word {gameState.round + 1}/{gameState.totalRounds}</span>
        </div>
      </header>

      <main className="game-content">
        <div className="level-selector">
          {(Object.keys(sightWordLevels) as SightWordLevel[]).map((level) => (
            <button
              key={level}
              className={`level-btn ${gameState.level === level ? 'active' : ''}`}
              onClick={() => handleLevelChange(level)}
              type="button"
            >
              {sightWordLevels[level].name}
            </button>
          ))}
        </div>

        {gameState.currentWord && (
          <>
            <div className="word-display">
              <h2 className="target-word">{gameState.currentWord}</h2>
              <button className="repeat-btn" onClick={handleRepeatWord} type="button">
                🔊 Hear Word
              </button>
            </div>

            <p className="instruction">
              {isRecording
                ? 'Tap the microphone when you\'re done reading'
                : 'Tap the microphone and read the word aloud'}
            </p>

            <div className="mic-container">
              <button
                className={`mic-button ${isRecording ? 'recording' : ''} ${isProcessing ? 'processing' : ''}`}
                onClick={handleMicClick}
                disabled={gameState.showFeedback || isProcessing}
                type="button"
                aria-label={isRecording ? 'Stop recording' : 'Start recording'}
              >
                {isProcessing ? (
                  <span className="mic-icon">⏳</span>
                ) : isRecording ? (
                  <span className="mic-icon recording-icon">🎙️</span>
                ) : (
                  <span className="mic-icon">🎤</span>
                )}
              </button>
              {isRecording && (
                <div className="recording-indicator">
                  <span className="recording-dot"></span>
                  Recording...
                </div>
              )}
            </div>

            {gameState.showFeedback && gameState.result && (
              <div className={`feedback ${gameState.result.isCorrect ? 'correct' : 'incorrect'}`}>
                {gameState.result.isCorrect ? (
                  <>
                    <span className="feedback-icon">✓</span>
                    <span className="feedback-text">{gameState.result.feedback}</span>
                  </>
                ) : (
                  <>
                    <span className="feedback-icon">✗</span>
                    <span className="feedback-text">{gameState.result.feedback}</span>
                    {gameState.result.transcribed && (
                      <span className="transcribed">You said: "{gameState.result.transcribed}"</span>
                    )}
                  </>
                )}
              </div>
            )}

            {!gameState.showFeedback && !isRecording && (
              <button className="skip-btn" onClick={handleSkip} type="button">
                Skip this word
              </button>
            )}

            {/* Progress bar */}
            <div className="progress-bar-container">
              <div
                className="progress-bar-fill"
                style={{ width: `${((gameState.round) / gameState.totalRounds) * 100}%` }}
              />
            </div>
          </>
        )}
      </main>
    </div>
  )
}
