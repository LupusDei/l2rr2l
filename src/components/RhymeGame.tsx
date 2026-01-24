import { useState, useCallback, useEffect, useRef } from 'react'
import './RhymeGame.css'
import {
  generateRhymeQuestion,
  type RhymeQuestion,
  type RhymeWord,
  type RhymeDistractor,
} from '../game-data/rhyme'
import { playCorrectSound, playWordCompleteSound } from '../game/sounds'
import { useVoice } from '../hooks/useVoice'

interface RhymeGameProps {
  onBack: () => void
  difficulty?: 1 | 2 | 3
  questionsPerLevel?: number
}

// Difficulty level info for display
const difficultyInfo: Record<1 | 2 | 3, { name: string; description: string }> = {
  1: { name: 'Easy', description: 'Simple rhymes' },
  2: { name: 'Medium', description: 'More word families' },
  3: { name: 'Hard', description: 'All rhymes with tricky distractors' },
}

// Celebration messages
const celebrationMessages = [
  { text: 'Amazing!', emoji: '🌟' },
  { text: 'Super Star!', emoji: '⭐' },
  { text: 'Rhyme Time!', emoji: '🎵' },
  { text: 'Fantastic!', emoji: '🚀' },
  { text: 'You Rock!', emoji: '🎸' },
]

// Streak milestones
const streakMilestones = [3, 5, 10]

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

// Get display emoji from option
function getOptionEmoji(option: RhymeWord | RhymeDistractor): string {
  return option.emoji
}

export default function RhymeGame({
  onBack,
  difficulty = 1,
  questionsPerLevel = 10,
}: RhymeGameProps) {
  const { speak, isSpeaking } = useVoice()

  const [currentQuestion, setCurrentQuestion] = useState<RhymeQuestion | null>(
    () => generateRhymeQuestion(difficulty, 2)
  )
  const [score, setScore] = useState(0)
  const [streak, setStreak] = useState(0)
  const [questionsAnswered, setQuestionsAnswered] = useState(0)
  const [selectedOption, setSelectedOption] = useState<
    RhymeWord | RhymeDistractor | null
  >(null)
  const [showResult, setShowResult] = useState(false)
  const [showCelebration, setShowCelebration] = useState(false)
  const [celebrationMessage, setCelebrationMessage] = useState(
    celebrationMessages[0]
  )
  const [showStreakMilestone, setShowStreakMilestone] = useState<number | null>(
    null
  )
  const hasAnnouncedRef = useRef(false)

  const levelInfo = difficultyInfo[difficulty]

  // Generate a new question
  const nextQuestion = useCallback(() => {
    setCurrentQuestion(generateRhymeQuestion(difficulty, 2))
    setSelectedOption(null)
    setShowResult(false)
    setQuestionsAnswered((prev) => prev + 1)
  }, [difficulty])

  // Reset game
  const resetGame = useCallback(() => {
    setCurrentQuestion(generateRhymeQuestion(difficulty, 2))
    setScore(0)
    setStreak(0)
    setQuestionsAnswered(0)
    setSelectedOption(null)
    setShowResult(false)
    setShowCelebration(false)
    hasAnnouncedRef.current = false
  }, [difficulty])

  // Announce game start
  useEffect(() => {
    if (!hasAnnouncedRef.current) {
      hasAnnouncedRef.current = true
      const timer = setTimeout(() => {
        speak('Find the word that rhymes!')
      }, 500)
      return () => clearTimeout(timer)
    }
  }, [speak])

  // Speak the target word
  const speakTargetWord = useCallback(() => {
    if (!isSpeaking && currentQuestion) {
      speak(currentQuestion.targetWord.word)
    }
  }, [currentQuestion, isSpeaking, speak])

  // Handle choice selection
  const handleChoiceClick = useCallback(
    (option: RhymeWord | RhymeDistractor) => {
      if (showResult || !currentQuestion) return

      setSelectedOption(option)
      setShowResult(true)

      const isCorrect = option.id === currentQuestion.correctAnswer.id

      // Play sound effect
      if (isCorrect) {
        playCorrectSound()
        setScore((prev) => prev + 1)
        const newStreak = streak + 1
        setStreak(newStreak)

        // Check for streak milestone
        if (streakMilestones.includes(newStreak)) {
          setShowStreakMilestone(newStreak)
          setTimeout(() => setShowStreakMilestone(null), 1000)
        }

        // Speak feedback
        speak(
          `Yes! ${option.word} rhymes with ${currentQuestion.targetWord.word}!`
        )
      } else {
        setStreak(0)
        speak(`Oops! ${option.word} doesn't rhyme. Try again!`)
      }

      // Check for level complete
      if (questionsAnswered + 1 >= questionsPerLevel) {
        setTimeout(() => {
          playWordCompleteSound()
          const msg =
            celebrationMessages[
              Math.floor(Math.random() * celebrationMessages.length)
            ]
          setCelebrationMessage(msg)
          setShowCelebration(true)
          speak(
            `${msg.text} You got ${score + (isCorrect ? 1 : 0)} out of ${questionsPerLevel}!`
          )
        }, 1500)
      }
    },
    [currentQuestion, questionsAnswered, questionsPerLevel, score, showResult, speak, streak]
  )

  // Auto-advance after showing result (if not level complete)
  useEffect(() => {
    if (
      showResult &&
      !showCelebration &&
      questionsAnswered + 1 < questionsPerLevel
    ) {
      const timer = setTimeout(() => {
        nextQuestion()
      }, 2000)
      return () => clearTimeout(timer)
    }
  }, [showResult, showCelebration, questionsAnswered, questionsPerLevel, nextQuestion])

  // Speak the new word after question changes
  useEffect(() => {
    if (currentQuestion && questionsAnswered > 0 && !showResult) {
      const timer = setTimeout(() => {
        speak(currentQuestion.targetWord.word)
      }, 300)
      return () => clearTimeout(timer)
    }
  }, [currentQuestion, questionsAnswered, showResult, speak])

  // Play again
  const handlePlayAgain = useCallback(() => {
    resetGame()
    setTimeout(() => {
      speak('Find the word that rhymes!')
    }, 300)
  }, [resetGame, speak])

  if (!currentQuestion) {
    return (
      <div className="rhyme-game">
        <header className="rhyme-header">
          <button className="back-button" onClick={onBack} type="button">
            &#8592; Back
          </button>
        </header>
        <div className="target-word-container">
          <p>Loading...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="rhyme-game">
      {/* Header */}
      <header className="rhyme-header">
        <button className="back-button" onClick={onBack} type="button">
          &#8592; Back
        </button>
        <div className="rhyme-stats">
          <span className="stat">
            Score: {score}/{questionsPerLevel}
          </span>
          {streak > 0 && <span className="stat streak">Streak: {streak}</span>}
        </div>
      </header>

      {/* Streak milestone popup */}
      {showStreakMilestone !== null && (
        <div className="streak-milestone">{showStreakMilestone} in a row!</div>
      )}

      {/* Celebration overlay */}
      {showCelebration && (
        <div className="celebration-overlay">
          <div className="celebration-content">
            <span className="celebration-emoji">{celebrationMessage.emoji}</span>
            <h2 className="celebration-text">{celebrationMessage.text}</h2>
            <p className="celebration-stats">
              You got {score} out of {questionsPerLevel} rhymes!
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

      {/* Target word */}
      <div className="target-word-container">
        <span className="target-emoji">{currentQuestion.targetWord.emoji}</span>
        <h2 className="target-word">{currentQuestion.targetWord.word}</h2>
        <p className="target-prompt">Find the word that rhymes!</p>
        <button
          className="speak-button"
          onClick={speakTargetWord}
          disabled={isSpeaking}
          type="button"
        >
          <span role="img" aria-label="speaker">
            🔊
          </span>
          Hear Word
        </button>
      </div>

      {/* Answer choices */}
      <div className="choices-container">
        {currentQuestion.allOptions.map((option, index) => {
          const isSelected = selectedOption?.id === option.id
          const isCorrectAnswer = option.id === currentQuestion.correctAnswer.id
          let className = 'choice-button'

          if (showResult) {
            className += ' revealed'
            if (isSelected && isCorrectAnswer) {
              className += ' correct'
            } else if (isSelected && !isCorrectAnswer) {
              className += ' wrong'
            } else if (isCorrectAnswer) {
              className += ' correct'
            }
          }

          return (
            <button
              key={`${option.id}-${index}`}
              className={className}
              onClick={() => handleChoiceClick(option)}
              disabled={showResult}
              type="button"
              aria-label={option.word}
            >
              <span className="choice-emoji">{getOptionEmoji(option)}</span>
              <span className="choice-word">{option.word}</span>
            </button>
          )
        })}
      </div>

      {/* Difficulty info */}
      <p
        style={{
          color: 'rgba(255,255,255,0.7)',
          marginTop: '1rem',
          fontSize: '0.9rem',
        }}
      >
        {levelInfo.name} - {levelInfo.description}
      </p>

      {/* New game button */}
      <button className="new-game-button" onClick={handlePlayAgain} type="button">
        New Game
      </button>
    </div>
  )
}
