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

// Extract the rhyming ending from a word (the part that rhymes)
function getRhymePattern(word: string): { prefix: string; pattern: string } {
  // Common rhyme patterns - find the longest matching ending
  const patterns = [
    'ight', 'ound', 'tion', 'ness', 'ment', 'able', 'ible',
    'ing', 'ang', 'ong', 'ung', 'ink', 'ank', 'onk', 'unk',
    'ack', 'eck', 'ick', 'ock', 'uck', 'all', 'ell', 'ill', 'oll', 'ull',
    'at', 'et', 'it', 'ot', 'ut', 'an', 'en', 'in', 'on', 'un',
    'ap', 'ep', 'ip', 'op', 'up', 'ar', 'er', 'ir', 'or', 'ur',
    'ay', 'ey', 'oy', 'aw', 'ow', 'ew', 'oo', 'ee', 'ea',
    'ake', 'ike', 'oke', 'uke', 'ace', 'ice', 'ose', 'use',
    'ame', 'ime', 'ome', 'ade', 'ide', 'ode', 'ude',
    'ain', 'ine', 'one', 'une', 'ane', 'ene',
    'air', 'ear', 'ore', 'are', 'ire', 'ure',
    'ash', 'esh', 'ish', 'osh', 'ush',
    'ath', 'eth', 'ith', 'oth', 'uth',
    'amp', 'emp', 'imp', 'omp', 'ump',
    'and', 'end', 'ind', 'ond', 'und',
    'ant', 'ent', 'int', 'ont', 'unt',
    'est', 'ist', 'ost', 'ust',
    'ck', 'ng', 'nk', 'mp', 'nd', 'nt', 'st',
  ]

  const lowerWord = word.toLowerCase()
  for (const pattern of patterns) {
    if (lowerWord.endsWith(pattern)) {
      const prefixEnd = lowerWord.length - pattern.length
      return {
        prefix: word.slice(0, prefixEnd),
        pattern: word.slice(prefixEnd),
      }
    }
  }

  // Fallback: last 2 characters as pattern
  if (word.length > 2) {
    return {
      prefix: word.slice(0, -2),
      pattern: word.slice(-2),
    }
  }

  return { prefix: '', pattern: word }
}

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

const confettiPositions = generateConfettiPositions(40)

// Generate sparkle positions for correct answer celebration
function generateSparklePositions(count: number = 8) {
  return Array.from({ length: count }).map((_, i) => ({
    id: i,
    top: `${20 + Math.random() * 60}%`,
    left: `${10 + Math.random() * 80}%`,
    delay: `${Math.random() * 0.3}s`,
    size: 12 + Math.random() * 12,
  }))
}

// Get display emoji from option
function getOptionEmoji(option: RhymeWord | RhymeDistractor): string {
  return option.emoji
}

// Component for displaying word with highlighted rhyme pattern
function HighlightedWord({
  word,
  highlight,
  className = '',
}: {
  word: string
  highlight: boolean
  className?: string
}) {
  const { prefix, pattern } = getRhymePattern(word)

  if (!highlight) {
    return <span className={className}>{word}</span>
  }

  return (
    <span className={className}>
      {prefix}
      <span className="rhyme-pattern">{pattern}</span>
    </span>
  )
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
  const [isEntering, setIsEntering] = useState(false)
  const [showSparkles, setShowSparkles] = useState(false)
  const [sparklePositions, setSparklePositions] = useState<ReturnType<typeof generateSparklePositions>>([])
  const hasAnnouncedRef = useRef(false)
  const targetWordRef = useRef<HTMLDivElement>(null)

  const levelInfo = difficultyInfo[difficulty]

  // Generate a new question with smooth transition
  const nextQuestion = useCallback(() => {
    setIsEntering(true)
    setCurrentQuestion(generateRhymeQuestion(difficulty, 2))
    setSelectedOption(null)
    setShowResult(false)
    setShowSparkles(false)
    setQuestionsAnswered((prev) => prev + 1)

    // Reset entering state after animation
    setTimeout(() => setIsEntering(false), 600)
  }, [difficulty])

  // Reset game
  const resetGame = useCallback(() => {
    setIsEntering(true)
    setCurrentQuestion(generateRhymeQuestion(difficulty, 2))
    setScore(0)
    setStreak(0)
    setQuestionsAnswered(0)
    setSelectedOption(null)
    setShowResult(false)
    setShowCelebration(false)
    setShowSparkles(false)
    hasAnnouncedRef.current = false
    setTimeout(() => setIsEntering(false), 600)
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

        // Show sparkle celebration
        setSparklePositions(generateSparklePositions(8))
        setShowSparkles(true)
        setTimeout(() => setShowSparkles(false), 800)

        // Check for streak milestone
        if (streakMilestones.includes(newStreak)) {
          setShowStreakMilestone(newStreak)
          setTimeout(() => setShowStreakMilestone(null), 1200)
        }

        // Speak feedback with rhyme pattern emphasis
        const { pattern } = getRhymePattern(option.word)
        speak(
          `Yes! ${option.word} rhymes with ${currentQuestion.targetWord.word}! They both end in ${pattern}!`
        )
      } else {
        setStreak(0)
        speak(`Oops! ${option.word} doesn't rhyme with ${currentQuestion.targetWord.word}. Try again!`)
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
      <div
        ref={targetWordRef}
        className={`target-word-container${isEntering ? ' entering' : ''}`}
      >
        <span className="target-emoji">{currentQuestion.targetWord.emoji}</span>
        <h2 className="target-word">
          <HighlightedWord
            word={currentQuestion.targetWord.word}
            highlight={showResult}
          />
        </h2>
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

        {/* Sparkle celebration */}
        {showSparkles && (
          <div className="sparkle-container">
            {sparklePositions.map(({ id, top, left, delay, size }) => (
              <span
                key={id}
                className="sparkle"
                style={{
                  top,
                  left,
                  animationDelay: delay,
                  width: size,
                  height: size,
                }}
              />
            ))}
          </div>
        )}
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
              <HighlightedWord
                word={option.word}
                highlight={showResult && isCorrectAnswer}
                className="choice-word"
              />
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
