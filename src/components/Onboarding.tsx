import { useState } from 'react'
import './Onboarding.css'

interface OnboardingData {
  name: string
  age: number | null
  sex: string | null
  avatar: string | null
}

interface OnboardingProps {
  onComplete: (data: OnboardingData) => void
  onBack: () => void
}

const AVATARS = [
  { id: 'bear', emoji: '🐻', label: 'Bear' },
  { id: 'bunny', emoji: '🐰', label: 'Bunny' },
  { id: 'fox', emoji: '🦊', label: 'Fox' },
  { id: 'owl', emoji: '🦉', label: 'Owl' },
  { id: 'cat', emoji: '🐱', label: 'Cat' },
  { id: 'dog', emoji: '🐶', label: 'Dog' },
  { id: 'panda', emoji: '🐼', label: 'Panda' },
  { id: 'lion', emoji: '🦁', label: 'Lion' },
]

const AGES = [4, 5, 6]

const ENCOURAGEMENTS = [
  "Great job!",
  "You're doing amazing!",
  "Wonderful choice!",
  "That's perfect!",
  "Fantastic!",
]

function getRandomEncouragement() {
  return ENCOURAGEMENTS[Math.floor(Math.random() * ENCOURAGEMENTS.length)]
}

export default function Onboarding({ onComplete, onBack }: OnboardingProps) {
  const [step, setStep] = useState(0)
  const [data, setData] = useState<OnboardingData>({
    name: '',
    age: null,
    sex: null,
    avatar: null,
  })
  const [encouragement, setEncouragement] = useState('')
  const [isAnimating, setIsAnimating] = useState(false)

  const showEncouragement = () => {
    setEncouragement(getRandomEncouragement())
    setIsAnimating(true)
    setTimeout(() => {
      setIsAnimating(false)
      setEncouragement('')
    }, 1500)
  }

  const nextStep = () => {
    showEncouragement()
    setTimeout(() => {
      setStep(s => s + 1)
    }, 800)
  }

  const prevStep = () => {
    if (step === 0) {
      onBack()
    } else {
      setStep(s => s - 1)
    }
  }

  const handleNameSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    if (data.name.trim()) {
      nextStep()
    }
  }

  const handleAgeSelect = (age: number) => {
    setData(d => ({ ...d, age }))
    nextStep()
  }

  const handleSexSelect = (sex: string) => {
    setData(d => ({ ...d, sex }))
    nextStep()
  }

  const handleAvatarSelect = (avatar: string) => {
    setData(d => ({ ...d, avatar }))
    nextStep()
  }

  const handleComplete = () => {
    onComplete(data)
  }

  const renderStep = () => {
    switch (step) {
      case 0:
        return (
          <div className="onboarding-step step-name">
            <div className="step-icon">👋</div>
            <h2 className="step-title">Hi there!</h2>
            <p className="step-subtitle">What's your name?</p>
            <form onSubmit={handleNameSubmit} className="name-form">
              <input
                type="text"
                value={data.name}
                onChange={e => setData(d => ({ ...d, name: e.target.value }))}
                placeholder="Type your name..."
                className="name-input"
                autoFocus
                maxLength={30}
              />
              <button
                type="submit"
                className="next-button"
                disabled={!data.name.trim()}
              >
                Next
              </button>
            </form>
          </div>
        )

      case 1:
        return (
          <div className="onboarding-step step-age">
            <div className="step-icon">🎂</div>
            <h2 className="step-title">
              Nice to meet you, {data.name}!
            </h2>
            <p className="step-subtitle">How old are you?</p>
            <div className="age-buttons">
              {AGES.map(age => (
                <button
                  key={age}
                  type="button"
                  className={`age-button ${data.age === age ? 'selected' : ''}`}
                  onClick={() => handleAgeSelect(age)}
                >
                  <span className="age-number">{age}</span>
                  <span className="age-label">years old</span>
                </button>
              ))}
            </div>
          </div>
        )

      case 2:
        return (
          <div className="onboarding-step step-sex">
            <div className="step-icon">✨</div>
            <h2 className="step-title">Awesome!</h2>
            <p className="step-subtitle">Are you a...</p>
            <div className="sex-buttons">
              <button
                type="button"
                className={`sex-button boy ${data.sex === 'boy' ? 'selected' : ''}`}
                onClick={() => handleSexSelect('boy')}
              >
                <span className="sex-emoji">👦</span>
                <span className="sex-label">Boy</span>
              </button>
              <button
                type="button"
                className={`sex-button girl ${data.sex === 'girl' ? 'selected' : ''}`}
                onClick={() => handleSexSelect('girl')}
              >
                <span className="sex-emoji">👧</span>
                <span className="sex-label">Girl</span>
              </button>
            </div>
          </div>
        )

      case 3:
        return (
          <div className="onboarding-step step-avatar">
            <div className="step-icon">🌟</div>
            <h2 className="step-title">Pick your friend!</h2>
            <p className="step-subtitle">Choose an animal buddy</p>
            <div className="avatar-grid">
              {AVATARS.map(avatar => (
                <button
                  key={avatar.id}
                  type="button"
                  className={`avatar-button ${data.avatar === avatar.id ? 'selected' : ''}`}
                  onClick={() => handleAvatarSelect(avatar.id)}
                  aria-label={avatar.label}
                >
                  <span className="avatar-emoji">{avatar.emoji}</span>
                  <span className="avatar-label">{avatar.label}</span>
                </button>
              ))}
            </div>
          </div>
        )

      case 4:
        return (
          <div className="onboarding-step step-complete">
            <div className="celebration">
              <span className="confetti">🎉</span>
              <span className="confetti">🎊</span>
              <span className="confetti">⭐</span>
            </div>
            <div className="step-icon big">
              {AVATARS.find(a => a.id === data.avatar)?.emoji || '🌟'}
            </div>
            <h2 className="step-title">
              Yay, {data.name}!
            </h2>
            <p className="step-subtitle">You're all ready to learn!</p>
            <button
              type="button"
              className="start-learning-button"
              onClick={handleComplete}
            >
              Let's Go!
            </button>
          </div>
        )

      default:
        return null
    }
  }

  return (
    <div className="onboarding">
      {/* Progress bar */}
      <div className="progress-container">
        <div className="progress-bar">
          <div
            className="progress-fill"
            style={{ width: `${((step + 1) / 5) * 100}%` }}
          />
        </div>
        <div className="progress-dots">
          {[0, 1, 2, 3, 4].map(i => (
            <div
              key={i}
              className={`progress-dot ${i <= step ? 'active' : ''} ${i === step ? 'current' : ''}`}
            />
          ))}
        </div>
      </div>

      {/* Back button */}
      {step < 4 && (
        <button
          type="button"
          className="back-button"
          onClick={prevStep}
          aria-label="Go back"
        >
          ← Back
        </button>
      )}

      {/* Encouragement popup */}
      {encouragement && (
        <div className={`encouragement ${isAnimating ? 'show' : ''}`}>
          <span className="encouragement-star">⭐</span>
          {encouragement}
          <span className="encouragement-star">⭐</span>
        </div>
      )}

      {/* Step content */}
      <div className="step-container">
        {renderStep()}
      </div>
    </div>
  )
}
