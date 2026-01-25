import { useEffect, useState, useCallback } from 'react'
import './Confetti.css'

interface ConfettiPiece {
  id: number
  x: number
  color: string
  delay: number
  duration: number
  rotation: number
  size: number
}

interface ConfettiProps {
  active: boolean
  duration?: number
  pieceCount?: number
  onComplete?: () => void
}

const COLORS = [
  '#ff6b6b', // red
  '#feca57', // yellow
  '#48dbfb', // blue
  '#1dd1a1', // green
  '#ff9ff3', // pink
  '#54a0ff', // light blue
  '#5f27cd', // purple
  '#ff9f43', // orange
]

export default function Confetti({
  active,
  duration = 3000,
  pieceCount = 50,
  onComplete,
}: ConfettiProps) {
  const [pieces, setPieces] = useState<ConfettiPiece[]>([])

  const generatePieces = useCallback(() => {
    const newPieces: ConfettiPiece[] = []
    for (let i = 0; i < pieceCount; i++) {
      newPieces.push({
        id: i,
        x: Math.random() * 100,
        color: COLORS[Math.floor(Math.random() * COLORS.length)],
        delay: Math.random() * 0.5,
        duration: 2 + Math.random() * 2,
        rotation: Math.random() * 360,
        size: 8 + Math.random() * 8,
      })
    }
    return newPieces
  }, [pieceCount])

  useEffect(() => {
    if (active) {
      setPieces(generatePieces())

      const timer = setTimeout(() => {
        setPieces([])
        onComplete?.()
      }, duration)

      return () => clearTimeout(timer)
    } else {
      setPieces([])
    }
  }, [active, duration, generatePieces, onComplete])

  if (!active || pieces.length === 0) {
    return null
  }

  return (
    <div className="confetti-container" aria-hidden="true">
      {pieces.map((piece) => (
        <div
          key={piece.id}
          className="confetti-piece"
          style={{
            left: `${piece.x}%`,
            backgroundColor: piece.color,
            animationDelay: `${piece.delay}s`,
            animationDuration: `${piece.duration}s`,
            transform: `rotate(${piece.rotation}deg)`,
            width: `${piece.size}px`,
            height: `${piece.size}px`,
          }}
        />
      ))}
    </div>
  )
}
