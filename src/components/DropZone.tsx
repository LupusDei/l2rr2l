import { useRef, useEffect } from 'react'
import './DropZone.css'

export interface DropZoneProps {
  index: number
  expectedLetter: string
  currentLetter: string | null
  isActive: boolean
  onGetBounds: (index: number, bounds: DOMRect) => void
  showWrongAnimation?: boolean
  showCorrectAnimation?: boolean
}

// Generate sparkle positions for particle burst effect
function generateSparkles() {
  return Array.from({ length: 8 }).map((_, i) => {
    const angle = (i / 8) * Math.PI * 2
    return {
      id: i,
      emoji: ['✨', '⭐', '💫', '🌟'][i % 4],
      x: Math.cos(angle) * 50,
      y: Math.sin(angle) * 50,
      delay: i * 0.03,
    }
  })
}

const sparkles = generateSparkles()

export default function DropZone({
  index,
  expectedLetter,
  currentLetter,
  isActive,
  onGetBounds,
  showWrongAnimation = false,
  showCorrectAnimation = false,
}: DropZoneProps) {
  const zoneRef = useRef<HTMLDivElement>(null)

  // Report bounds to parent for hit testing
  useEffect(() => {
    if (zoneRef.current) {
      const updateBounds = () => {
        if (zoneRef.current) {
          onGetBounds(index, zoneRef.current.getBoundingClientRect())
        }
      }
      updateBounds()
      window.addEventListener('resize', updateBounds)
      return () => window.removeEventListener('resize', updateBounds)
    }
  }, [index, onGetBounds])

  const isFilled = currentLetter !== null
  const isCorrect = currentLetter === expectedLetter

  return (
    <div
      ref={zoneRef}
      className={`drop-zone
        ${isActive ? 'active' : ''}
        ${isFilled ? 'filled' : ''}
        ${isCorrect ? 'correct' : ''}
        ${showCorrectAnimation ? 'just-correct' : ''}
        ${showWrongAnimation ? 'show-wrong' : ''}`}
      data-index={index}
      data-expected={expectedLetter}
    >
      {/* Glow effect behind letter */}
      {showCorrectAnimation && (
        <div key={`glow-${currentLetter}`} className="correct-glow" />
      )}

      {currentLetter ? (
        // Key forces re-mount to trigger CSS animation
        <span key={currentLetter} className="placed-letter animate-in">
          {currentLetter.toUpperCase()}
        </span>
      ) : (
        <span className="placeholder-number">{index + 1}</span>
      )}

      {/* Sparkle particles burst */}
      {showCorrectAnimation && (
        <div key={`sparkles-${currentLetter}`} className="sparkle-container">
          {sparkles.map(({ id, emoji, x, y, delay }) => (
            <span
              key={id}
              className="sparkle"
              style={{
                '--x': `${x}px`,
                '--y': `${y}px`,
                animationDelay: `${delay}s`,
              } as React.CSSProperties}
            >
              {emoji}
            </span>
          ))}
        </div>
      )}

      {/* Star that appears on correct */}
      {isCorrect && currentLetter && (
        <span key={`star-${currentLetter}`} className="correct-star">⭐</span>
      )}
    </div>
  )
}
