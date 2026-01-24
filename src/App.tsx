import { useState } from 'react'
import './App.css'
import Onboarding from './components/Onboarding'
import LessonSelection from './components/LessonSelection'
import LessonPlayer from './components/LessonPlayer'
import SpellingGame from './components/SpellingGame'
import MemoryGame from './components/MemoryGame'
import RhymeGame from './components/RhymeGame'
import WordBuilder from './components/WordBuilder'
import PhonicsGame from './components/PhonicsGame'
import Settings from './components/Settings'
import { VoiceProvider } from './hooks/useVoice'
import type { Lesson as LegacyLesson } from './components/LessonCard'
import type { Lesson, ActivityProgress } from './types/lesson'
import { version } from '../package.json'

type Screen = 'home' | 'onboarding' | 'lessons' | 'lesson-player' | 'spelling' | 'memory' | 'rhyme' | 'builder' | 'phonics' | 'settings'

// Temporary child ID for development (would come from auth in production)
const DEV_CHILD_ID = 'dev-child-1'

interface ChildData {
  name: string
  age: number | null
  sex: string | null
  avatar: string | null
}

function App() {
  const [screen, setScreen] = useState<Screen>('home')
  const [childData, setChildData] = useState<ChildData | null>(null)
  const [selectedLesson, setSelectedLesson] = useState<Lesson | null>(null)

  const handleGetStarted = () => {
    setScreen('onboarding')
  }

  const handleOnboardingComplete = (data: ChildData) => {
    setChildData(data)
    // TODO: Save to backend
    console.log('Onboarding complete:', data)
    setScreen('lessons')
  }

  const handleOnboardingBack = () => {
    setScreen('home')
  }

  const handleSelectLesson = async (legacyLesson: LegacyLesson) => {
    // Fetch full lesson data from API
    try {
      const response = await fetch(`/api/lessons/${legacyLesson.id}`)
      if (response.ok) {
        const data = await response.json()
        if (data.lesson) {
          setSelectedLesson(data.lesson as Lesson)
          setScreen('lesson-player')
          return
        }
      }
    } catch {
      // Fall back to legacy lesson if API fails
    }
    console.log('Failed to load lesson:', legacyLesson)
  }

  const handleLessonComplete = async (progress: { overallScore: number; activityProgress: ActivityProgress[] }) => {
    if (selectedLesson) {
      // Save progress to API
      try {
        await fetch(`/api/progress/child/${DEV_CHILD_ID}/lesson/${selectedLesson.id}/complete`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            score: progress.overallScore,
            timeSpent: progress.activityProgress.reduce((t, a) => t + a.timeSpentSeconds, 0),
          }),
        })
      } catch {
        // Silently fail - progress saving is non-critical
      }
    }
    setSelectedLesson(null)
    setScreen('lessons')
  }

  const handleLessonExit = () => {
    setSelectedLesson(null)
    setScreen('lessons')
  }

  const handleLessonsBack = () => {
    setScreen('home')
  }

  const handleSpellingGame = () => {
    setScreen('spelling')
  }

  const handleSpellingBack = () => {
    setScreen('home')
  }

  const handleMemoryGame = () => {
    setScreen('memory')
  }

  const handleMemoryBack = () => {
    setScreen('home')
  }

  const handleRhymeGame = () => {
    setScreen('rhyme')
  }

  const handleRhymeBack = () => {
    setScreen('home')
  }

  const handleBuilderGame = () => {
    setScreen('builder')
  }

  const handleBuilderBack = () => {
    setScreen('home')
  }

  const handlePhonicsGame = () => {
    setScreen('phonics')
  }

  const handlePhonicsBack = () => {
    setScreen('home')
  }

  const handleSettings = () => {
    setScreen('settings')
  }

  const handleSettingsBack = () => {
    setScreen('home')
  }

  const renderContent = () => {
    if (screen === 'settings') {
      return (
        <Settings
          childId={DEV_CHILD_ID}
          onBack={handleSettingsBack}
        />
      )
    }

    if (screen === 'lesson-player' && selectedLesson) {
      return (
        <VoiceProvider>
          <LessonPlayer
            lesson={selectedLesson}
            onComplete={handleLessonComplete}
            onExit={handleLessonExit}
          />
        </VoiceProvider>
      )
    }

    if (screen === 'spelling') {
      return (
        <VoiceProvider>
          <SpellingGame onBack={handleSpellingBack} />
        </VoiceProvider>
      )
    }

    if (screen === 'memory') {
      return (
        <VoiceProvider>
          <MemoryGame onBack={handleMemoryBack} />
        </VoiceProvider>
      )
    }

    if (screen === 'rhyme') {
      return (
        <VoiceProvider>
          <RhymeGame onBack={handleRhymeBack} />
        </VoiceProvider>
      )
    }

    if (screen === 'builder') {
      return (
        <VoiceProvider>
          <WordBuilder onBack={handleBuilderBack} />
        </VoiceProvider>
      )
    }

    if (screen === 'phonics') {
      return (
        <VoiceProvider>
          <PhonicsGame onBack={handlePhonicsBack} />
        </VoiceProvider>
      )
    }

    if (screen === 'onboarding') {
      return (
        <Onboarding
          onComplete={handleOnboardingComplete}
          onBack={handleOnboardingBack}
        />
      )
    }

    if (screen === 'lessons' && childData) {
      return (
        <LessonSelection
          childData={childData}
          childId={DEV_CHILD_ID}
          onSelectLesson={handleSelectLesson}
          onBack={handleLessonsBack}
        />
      )
    }

    return (
      <div className="app homescreen">
        {/* Settings button */}
        <button
          className="home-settings-btn"
          type="button"
          onClick={handleSettings}
          aria-label="Settings"
        >
          <span aria-hidden="true">&#9881;</span>
        </button>

        {/* Decorative floating elements */}
        <div className="decorations" aria-hidden="true">
          <span className="decoration crayon crayon-red">&#9998;</span>
          <span className="decoration crayon crayon-blue">&#9998;</span>
          <span className="decoration crayon crayon-yellow">&#9998;</span>
          <span className="decoration letter letter-a">A</span>
          <span className="decoration letter letter-b">B</span>
          <span className="decoration letter letter-c">C</span>
          <span className="decoration paint paint-splash-1"></span>
          <span className="decoration paint paint-splash-2"></span>
          <span className="decoration star star-1">&#9733;</span>
          <span className="decoration star star-2">&#9733;</span>
        </div>

        <main className="main homescreen-content">
          <div className="logo-container">
            <h1 className="logo">
              <span className="logo-letter logo-l1">L</span>
              <span className="logo-letter logo-2">2</span>
              <span className="logo-letter logo-r1">R</span>
              <span className="logo-letter logo-r2">R</span>
              <span className="logo-letter logo-2b">2</span>
              <span className="logo-letter logo-l2">L</span>
            </h1>
          </div>

          <p className="tagline">Learn to Read, Read to Learn!</p>

          {childData ? (
            <div className="welcome-back">
              <p className="welcome-message">
                Welcome back, {childData.name}!
              </p>
              <button className="cta-button" type="button" onClick={handleGetStarted}>
                Continue Learning!
              </button>
            </div>
          ) : (
            <button className="cta-button" type="button" onClick={handleGetStarted}>
              Get Started!
            </button>
          )}

          <div className="games-section">
            <button className="game-card spelling-card" type="button" onClick={handleSpellingGame}>
              <span className="game-icon" aria-hidden="true">ABC</span>
              <span className="game-title">Spelling Game</span>
              <span className="game-description">Practice spelling words!</span>
            </button>
            <button className="game-card memory-card" type="button" onClick={handleMemoryGame}>
              <span className="game-icon" aria-hidden="true">&#127183;</span>
              <span className="game-title">Sight Words</span>
              <span className="game-description">Match the sight words!</span>
            </button>
            <button className="game-card rhyme-card" type="button" onClick={handleRhymeGame}>
              <span className="game-icon" aria-hidden="true">&#127925;</span>
              <span className="game-title">Rhyme Time</span>
              <span className="game-description">Find words that rhyme!</span>
            </button>
            <button className="game-card builder-card" type="button" onClick={handleBuilderGame}>
              <span className="game-icon" aria-hidden="true">&#127981;</span>
              <span className="game-title">Word Builder</span>
              <span className="game-description">Build words in the factory!</span>
            </button>
            <button className="game-card phonics-card" type="button" onClick={handlePhonicsGame}>
              <span className="game-icon" aria-hidden="true">&#128264;</span>
              <span className="game-title">Phonics Fun</span>
              <span className="game-description">Match sounds to letters!</span>
            </button>
          </div>
        </main>
      </div>
    )
  }

  return (
    <>
      {renderContent()}
      <footer className="version-footer">v{version}</footer>
    </>
  )
}

export default App
