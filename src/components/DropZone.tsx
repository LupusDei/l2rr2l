import { useRef, useEffect } from 'react'
import './DropZone.css'

export interface DropZoneProps {
  index: number
  expectedLetter: string
  currentLetter: string | null
  isActive: boolean
  onGetBounds: (index: number, bounds: DOMRect) => void
  showWrongAnimation?: boolean
}

export default function DropZone({
  index,
  expectedLetter,
  currentLetter,
  isActive,
  onGetBounds,
  showWrongAnimation = false,
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
        ${showWrongAnimation ? 'show-wrong' : ''}`}
      data-index={index}
      data-expected={expectedLetter}
    >
      {currentLetter ? (
        // Key forces re-mount to trigger CSS animation
        <span key={currentLetter} className="placed-letter animate-in">
          {currentLetter.toUpperCase()}
        </span>
      ) : (
        <span className="placeholder-number">{index + 1}</span>
      )}
      {isCorrect && currentLetter && (
        <span key={`star-${currentLetter}`} className="correct-star">⭐</span>
      )}
    </div>
  )
}
