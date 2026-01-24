import './MemoryCard.css'

export interface MemoryCardProps {
  id: string
  word: string
  isFlipped: boolean
  isMatched: boolean
  onClick: (id: string) => void
  disabled: boolean
}

export default function MemoryCard({
  id,
  word,
  isFlipped,
  isMatched,
  onClick,
  disabled,
}: MemoryCardProps) {
  const handleClick = () => {
    if (!disabled && !isFlipped && !isMatched) {
      onClick(id)
    }
  }

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault()
      handleClick()
    }
  }

  return (
    <div
      className={`memory-card ${isFlipped ? 'flipped' : ''} ${isMatched ? 'matched' : ''}`}
      onClick={handleClick}
      onKeyDown={handleKeyDown}
      role="button"
      tabIndex={disabled || isMatched ? -1 : 0}
      aria-label={isFlipped || isMatched ? `Card showing "${word}"` : 'Face-down card'}
      aria-pressed={isFlipped}
      data-testid={`memory-card-${id}`}
    >
      <div className="memory-card-inner">
        <div className="memory-card-front">
          <span className="memory-card-symbol" aria-hidden="true">?</span>
        </div>
        <div className="memory-card-back">
          <span className="memory-card-word">{word}</span>
        </div>
      </div>
    </div>
  )
}
