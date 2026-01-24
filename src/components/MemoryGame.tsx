import './MemoryGame.css'

interface MemoryGameProps {
  onBack: () => void
}

export default function MemoryGame({ onBack }: MemoryGameProps) {
  return (
    <div className="memory-game">
      <header className="memory-header">
        <button
          className="back-button"
          type="button"
          onClick={onBack}
          aria-label="Go back to home"
        >
          <span aria-hidden="true">&larr;</span> Back
        </button>
        <h1 className="memory-title">Sight Word Memory</h1>
      </header>

      <main className="memory-content">
        <p className="coming-soon">Coming Soon!</p>
        <p className="coming-soon-desc">
          Match sight words to practice reading!
        </p>
      </main>
    </div>
  )
}
