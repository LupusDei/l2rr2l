import './WordBuilder.css'

interface WordBuilderProps {
  onBack: () => void
}

export default function WordBuilder({ onBack }: WordBuilderProps) {
  return (
    <div className="word-builder">
      <header className="word-builder-header">
        <button className="back-button" onClick={onBack} type="button">
          &#8592; Back
        </button>
        <h1 className="word-builder-title">Word Builder</h1>
      </header>

      <main className="word-builder-content">
        <div className="coming-soon">
          <span className="factory-icon" aria-hidden="true">&#127981;</span>
          <h2>Word Factory Coming Soon!</h2>
          <p>Build words by combining letters and word endings.</p>
        </div>
      </main>
    </div>
  )
}
