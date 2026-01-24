import './RhymeGame.css'

interface RhymeGameProps {
  onBack: () => void
}

export default function RhymeGame({ onBack }: RhymeGameProps) {
  return (
    <div className="rhyme-game">
      <header className="rhyme-header">
        <button className="back-button" onClick={onBack} type="button">
          &#8592; Back
        </button>
      </header>

      <div className="rhyme-content">
        <span className="rhyme-icon" aria-hidden="true">&#127925;</span>
        <h1 className="rhyme-title">Rhyme Time</h1>
        <p className="rhyme-description">
          Find words that rhyme!
        </p>
        <p className="coming-soon">Coming Soon!</p>
      </div>
    </div>
  )
}
