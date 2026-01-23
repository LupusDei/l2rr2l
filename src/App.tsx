import { useState } from 'react'
import './App.css'
import Onboarding from './components/Onboarding'
import LessonSelection from './components/LessonSelection'
import SpellingGame from './components/SpellingGame'
import { VoiceProvider } from './hooks/useVoice'
import type { Lesson } from './components/LessonCard'

type Screen = 'home' | 'onboarding' | 'lessons' | 'spelling'

interface ChildData {
  name: string
  age: number | null
  sex: string | null
  avatar: string | null
}

function App() {
  const [screen, setScreen] = useState<Screen>('home')
  const [childData, setChildData] = useState<ChildData | null>(null)

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

  const handleSelectLesson = (lesson: Lesson) => {
    // TODO: Navigate to lesson player
    console.log('Selected lesson:', lesson)
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

  if (screen === 'spelling') {
    return (
      <VoiceProvider>
        <SpellingGame onBack={handleSpellingBack} />
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
        onSelectLesson={handleSelectLesson}
        onBack={handleLessonsBack}
      />
    )
  }

  return (
    <div className="app homescreen">
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
        </div>
      </main>
    </div>
  )
}

export default App
