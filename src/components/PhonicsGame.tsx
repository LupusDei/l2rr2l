import { VoiceProvider } from '../hooks/useVoice'
import './PhonicsGame.css'

interface PhonicsGameProps {
  onBack: () => void
}

export default function PhonicsGame({ onBack }: PhonicsGameProps) {
  return (
    <VoiceProvider>
      <div className="phonics-game">
        <header className="phonics-header">
          <button className="back-button" onClick={onBack} type="button">
            ← Back
          </button>
          <h1 className="phonics-title">Phonics Game</h1>
        </header>

        <main className="phonics-content">
          <div className="coming-soon">
            <span className="coming-soon-icon" aria-hidden="true">🔤</span>
            <h2>Coming Soon!</h2>
            <p>Match sounds with letters and learn to read!</p>
          </div>
        </main>
      </div>
    </VoiceProvider>
  )
}
