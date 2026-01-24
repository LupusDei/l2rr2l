import { useState, useEffect } from 'react'
import { useVoice } from '../hooks/useVoice'
import type {
  LessonActivity as ActivityType,
  ReadingActivity,
  SpellingActivity,
  PhonicsActivity,
  SightWordsActivity,
  QuizActivity,
  MatchingActivity,
  FillInBlankActivity,
  ListenRepeatActivity,
  WordBuildingActivity,
} from '../types/lesson'
import './LessonActivity.css'

interface LessonActivityProps {
  activity: ActivityType
  onComplete: (score?: number) => void
}

export default function LessonActivity({ activity, onComplete }: LessonActivityProps) {
  const { speak, isSpeaking } = useVoice()

  useEffect(() => {
    // Speak instructions when activity loads
    const textToSpeak = activity.spokenInstructions || activity.instructions
    if (textToSpeak) {
      speak(textToSpeak)
    }
  }, [activity.id])

  const renderActivity = () => {
    switch (activity.type) {
      case 'reading':
        return <ReadingActivityView activity={activity} onComplete={onComplete} speak={speak} isSpeaking={isSpeaking} />
      case 'spelling':
        return <SpellingActivityView activity={activity} onComplete={onComplete} speak={speak} />
      case 'phonics':
        return <PhonicsActivityView activity={activity} onComplete={onComplete} speak={speak} />
      case 'sight-words':
        return <SightWordsActivityView activity={activity} onComplete={onComplete} speak={speak} />
      case 'quiz':
        return <QuizActivityView activity={activity} onComplete={onComplete} />
      case 'matching':
        return <MatchingActivityView activity={activity} onComplete={onComplete} />
      case 'fill-in-blank':
        return <FillInBlankActivityView activity={activity} onComplete={onComplete} />
      case 'listen-repeat':
        return <ListenRepeatActivityView activity={activity} onComplete={onComplete} speak={speak} />
      case 'word-building':
        return <WordBuildingActivityView activity={activity} onComplete={onComplete} speak={speak} />
      default:
        return <div className="activity-error">Unknown activity type</div>
    }
  }

  return (
    <div className="lesson-activity">
      <p className="activity-instructions">{activity.instructions}</p>
      {renderActivity()}
    </div>
  )
}

// Reading Activity - display text for reading
function ReadingActivityView({
  activity,
  onComplete,
  speak,
  isSpeaking,
}: {
  activity: ReadingActivity
  onComplete: (score?: number) => void
  speak: (text: string) => Promise<void>
  isSpeaking: boolean
}) {
  const handleReadAloud = () => {
    speak(activity.content)
  }

  return (
    <div className="activity-reading">
      {activity.imageUrl && (
        <img
          src={activity.imageUrl}
          alt=""
          className="activity-image"
        />
      )}
      <div className="reading-content">{activity.content}</div>
      <div className="activity-buttons">
        {activity.readAloud && (
          <button
            type="button"
            className="activity-button secondary"
            onClick={handleReadAloud}
            disabled={isSpeaking}
          >
            {isSpeaking ? 'Reading...' : 'Read Aloud'}
          </button>
        )}
        <button
          type="button"
          className="activity-button primary"
          onClick={() => onComplete(100)}
        >
          I Read It!
        </button>
      </div>
    </div>
  )
}

// Spelling Activity - spell a word
function SpellingActivityView({
  activity,
  onComplete,
  speak,
}: {
  activity: SpellingActivity
  onComplete: (score?: number) => void
  speak: (text: string) => Promise<void>
}) {
  const [userInput, setUserInput] = useState('')
  const [showHint, setShowHint] = useState(false)

  const handleSubmit = () => {
    const isCorrect = userInput.toLowerCase().trim() === activity.word.toLowerCase()
    if (isCorrect) {
      speak('Great job!')
      onComplete(100)
    } else {
      speak('Try again!')
      setUserInput('')
    }
  }

  return (
    <div className="activity-spelling">
      {activity.hint && (
        <div className="spelling-hint">
          {showHint ? activity.hint : (
            <button
              type="button"
              className="hint-button"
              onClick={() => setShowHint(true)}
            >
              Show Hint
            </button>
          )}
        </div>
      )}
      <button
        type="button"
        className="activity-button secondary"
        onClick={() => speak(activity.word)}
      >
        Hear the Word
      </button>
      <input
        type="text"
        className="spelling-input"
        value={userInput}
        onChange={(e) => setUserInput(e.target.value)}
        placeholder="Type the word..."
        autoComplete="off"
        autoCapitalize="off"
      />
      <button
        type="button"
        className="activity-button primary"
        onClick={handleSubmit}
        disabled={!userInput.trim()}
      >
        Check Spelling
      </button>
    </div>
  )
}

// Phonics Activity - practice sounds
function PhonicsActivityView({
  activity,
  onComplete,
  speak,
}: {
  activity: PhonicsActivity
  onComplete: (score?: number) => void
  speak: (text: string) => Promise<void>
}) {
  const [currentWordIndex, setCurrentWordIndex] = useState(0)

  const handleSaySound = () => {
    speak(activity.sound)
  }

  const handleSayWord = () => {
    speak(activity.exampleWords[currentWordIndex])
  }

  const handleNext = () => {
    if (currentWordIndex < activity.exampleWords.length - 1) {
      setCurrentWordIndex(currentWordIndex + 1)
    } else {
      onComplete(100)
    }
  }

  return (
    <div className="activity-phonics">
      <div className="phonics-sound">
        <span className="sound-display">{activity.sound}</span>
        <button
          type="button"
          className="activity-button secondary"
          onClick={handleSaySound}
        >
          Hear Sound
        </button>
      </div>
      <div className="phonics-word">
        <span className="word-display">{activity.exampleWords[currentWordIndex]}</span>
        <button
          type="button"
          className="activity-button secondary"
          onClick={handleSayWord}
        >
          Hear Word
        </button>
      </div>
      <button
        type="button"
        className="activity-button primary"
        onClick={handleNext}
      >
        {currentWordIndex < activity.exampleWords.length - 1 ? 'Next Word' : 'Done!'}
      </button>
    </div>
  )
}

// Sight Words Activity
function SightWordsActivityView({
  activity,
  onComplete,
  speak,
}: {
  activity: SightWordsActivity
  onComplete: (score?: number) => void
  speak: (text: string) => Promise<void>
}) {
  const [currentIndex, setCurrentIndex] = useState(0)

  const handleSayWord = () => {
    speak(activity.words[currentIndex])
  }

  const handleNext = () => {
    if (currentIndex < activity.words.length - 1) {
      setCurrentIndex(currentIndex + 1)
    } else {
      onComplete(100)
    }
  }

  return (
    <div className="activity-sight-words">
      <div className="sight-word-display">
        {activity.words[currentIndex]}
      </div>
      <div className="activity-buttons">
        <button
          type="button"
          className="activity-button secondary"
          onClick={handleSayWord}
        >
          Hear Word
        </button>
        <button
          type="button"
          className="activity-button primary"
          onClick={handleNext}
        >
          {currentIndex < activity.words.length - 1 ? 'Next' : 'Done!'}
        </button>
      </div>
      <div className="sight-word-progress">
        {currentIndex + 1} / {activity.words.length}
      </div>
    </div>
  )
}

// Quiz Activity
function QuizActivityView({
  activity,
  onComplete,
}: {
  activity: QuizActivity
  onComplete: (score?: number) => void
}) {
  const [selectedIndex, setSelectedIndex] = useState<number | null>(null)
  const [showResult, setShowResult] = useState(false)

  const handleSelect = (index: number) => {
    if (showResult) return
    setSelectedIndex(index)
    setShowResult(true)

    setTimeout(() => {
      const isCorrect = index === activity.correctIndex
      onComplete(isCorrect ? 100 : 0)
    }, 1500)
  }

  return (
    <div className="activity-quiz">
      <div className="quiz-question">{activity.question}</div>
      <div className="quiz-options">
        {activity.options.map((option, index) => (
          <button
            key={index}
            type="button"
            className={`quiz-option ${
              showResult
                ? index === activity.correctIndex
                  ? 'correct'
                  : index === selectedIndex
                  ? 'incorrect'
                  : ''
                : ''
            } ${selectedIndex === index ? 'selected' : ''}`}
            onClick={() => handleSelect(index)}
            disabled={showResult}
          >
            {option}
          </button>
        ))}
      </div>
      {showResult && activity.explanation && (
        <div className="quiz-explanation">{activity.explanation}</div>
      )}
    </div>
  )
}

// Matching Activity (simplified)
function MatchingActivityView({
  activity,
  onComplete,
}: {
  activity: MatchingActivity
  onComplete: (score?: number) => void
}) {
  const [matched, setMatched] = useState<number[]>([])
  const [selected, setSelected] = useState<{ side: 'left' | 'right'; index: number } | null>(null)

  const leftItems = activity.pairs.map(p => p[0])
  const rightItems = activity.pairs.map(p => p[1])

  const handleSelect = (side: 'left' | 'right', index: number) => {
    if (matched.includes(index)) return

    if (!selected) {
      setSelected({ side, index })
    } else if (selected.side !== side) {
      // Check if match
      if (selected.index === index) {
        setMatched([...matched, index])
        if (matched.length + 1 === activity.pairs.length) {
          onComplete(100)
        }
      }
      setSelected(null)
    } else {
      setSelected({ side, index })
    }
  }

  return (
    <div className="activity-matching">
      <div className="matching-columns">
        <div className="matching-column">
          {leftItems.map((item, index) => (
            <button
              key={index}
              type="button"
              className={`matching-item ${
                matched.includes(index) ? 'matched' : ''
              } ${
                selected?.side === 'left' && selected?.index === index ? 'selected' : ''
              }`}
              onClick={() => handleSelect('left', index)}
              disabled={matched.includes(index)}
            >
              {item}
            </button>
          ))}
        </div>
        <div className="matching-column">
          {rightItems.map((item, index) => (
            <button
              key={index}
              type="button"
              className={`matching-item ${
                matched.includes(index) ? 'matched' : ''
              } ${
                selected?.side === 'right' && selected?.index === index ? 'selected' : ''
              }`}
              onClick={() => handleSelect('right', index)}
              disabled={matched.includes(index)}
            >
              {item}
            </button>
          ))}
        </div>
      </div>
    </div>
  )
}

// Fill in the Blank Activity
function FillInBlankActivityView({
  activity,
  onComplete,
}: {
  activity: FillInBlankActivity
  onComplete: (score?: number) => void
}) {
  const [answer, setAnswer] = useState('')
  const [showResult, setShowResult] = useState(false)

  const handleSubmit = () => {
    setShowResult(true)
    const isCorrect = answer.toLowerCase().trim() === activity.answer.toLowerCase()
    setTimeout(() => {
      onComplete(isCorrect ? 100 : 0)
    }, 1500)
  }

  const parts = activity.sentence.split('___')

  return (
    <div className="activity-fill-blank">
      <div className="fill-blank-sentence">
        {parts[0]}
        <input
          type="text"
          className={`fill-blank-input ${
            showResult
              ? answer.toLowerCase().trim() === activity.answer.toLowerCase()
                ? 'correct'
                : 'incorrect'
              : ''
          }`}
          value={answer}
          onChange={(e) => setAnswer(e.target.value)}
          disabled={showResult}
          autoComplete="off"
        />
        {parts[1]}
      </div>
      {activity.wordBank && (
        <div className="word-bank">
          {activity.wordBank.map((word, index) => (
            <button
              key={index}
              type="button"
              className="word-bank-word"
              onClick={() => setAnswer(word)}
              disabled={showResult}
            >
              {word}
            </button>
          ))}
        </div>
      )}
      <button
        type="button"
        className="activity-button primary"
        onClick={handleSubmit}
        disabled={!answer.trim() || showResult}
      >
        Check Answer
      </button>
    </div>
  )
}

// Listen and Repeat Activity
function ListenRepeatActivityView({
  activity,
  onComplete,
  speak,
}: {
  activity: ListenRepeatActivity
  onComplete: (score?: number) => void
  speak: (text: string) => Promise<void>
}) {
  const handleListen = () => {
    speak(activity.phrase)
  }

  return (
    <div className="activity-listen-repeat">
      <div className="phrase-display">{activity.phrase}</div>
      <div className="activity-buttons">
        <button
          type="button"
          className="activity-button secondary"
          onClick={handleListen}
        >
          Listen Again
        </button>
        <button
          type="button"
          className="activity-button primary"
          onClick={() => onComplete(100)}
        >
          I Said It!
        </button>
      </div>
    </div>
  )
}

// Word Building Activity
function WordBuildingActivityView({
  activity,
  onComplete,
  speak,
}: {
  activity: WordBuildingActivity
  onComplete: (score?: number) => void
  speak: (text: string) => Promise<void>
}) {
  const [currentOnsetIndex, setCurrentOnsetIndex] = useState(0)

  const currentWord = activity.onsets[currentOnsetIndex] + activity.pattern

  const handleSayWord = () => {
    speak(currentWord)
  }

  const handleNext = () => {
    if (currentOnsetIndex < activity.onsets.length - 1) {
      setCurrentOnsetIndex(currentOnsetIndex + 1)
    } else {
      onComplete(100)
    }
  }

  return (
    <div className="activity-word-building">
      <div className="word-building-display">
        <span className="onset">{activity.onsets[currentOnsetIndex]}</span>
        <span className="pattern">{activity.pattern}</span>
      </div>
      <div className="word-result">{currentWord}</div>
      <div className="activity-buttons">
        <button
          type="button"
          className="activity-button secondary"
          onClick={handleSayWord}
        >
          Hear Word
        </button>
        <button
          type="button"
          className="activity-button primary"
          onClick={handleNext}
        >
          {currentOnsetIndex < activity.onsets.length - 1 ? 'Next' : 'Done!'}
        </button>
      </div>
    </div>
  )
}
