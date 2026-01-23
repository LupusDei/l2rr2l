import { useState, useRef, useEffect, useCallback } from 'react'
import './LetterTile.css'

export interface LetterTileProps {
  letter: string
  id: string
  onDragStart: (id: string, letter: string) => void
  onDragEnd: () => void
  disabled?: boolean
  placed?: boolean
}

export default function LetterTile({
  letter,
  id,
  onDragStart,
  onDragEnd,
  disabled = false,
  placed = false,
}: LetterTileProps) {
  const [isDragging, setIsDragging] = useState(false)
  const [position, setPosition] = useState({ x: 0, y: 0 })
  const startPosRef = useRef({ x: 0, y: 0 })
  const tileRef = useRef<HTMLDivElement>(null)

  // Handle mouse/touch start
  const handleStart = (clientX: number, clientY: number) => {
    if (disabled || placed) return
    setIsDragging(true)
    startPosRef.current = { x: clientX, y: clientY }
    setPosition({ x: 0, y: 0 })
    onDragStart(id, letter)
  }

  // Handle mouse/touch move - use useCallback with ref for startPos
  const handleMove = useCallback((clientX: number, clientY: number) => {
    setPosition({
      x: clientX - startPosRef.current.x,
      y: clientY - startPosRef.current.y,
    })
  }, [])

  // Handle mouse/touch end
  const handleEnd = useCallback(() => {
    setIsDragging(false)
    setPosition({ x: 0, y: 0 })
    onDragEnd()
  }, [onDragEnd])

  // Mouse events
  const handleMouseDown = (e: React.MouseEvent) => {
    e.preventDefault()
    handleStart(e.clientX, e.clientY)
  }

  // Touch events
  const handleTouchStart = (e: React.TouchEvent) => {
    const touch = e.touches[0]
    handleStart(touch.clientX, touch.clientY)
  }

  // Global move/end listeners when dragging
  useEffect(() => {
    if (!isDragging) return

    const handleMouseMove = (e: MouseEvent) => {
      handleMove(e.clientX, e.clientY)
    }

    const handleMouseUp = () => {
      handleEnd()
    }

    const handleTouchMove = (e: TouchEvent) => {
      const touch = e.touches[0]
      handleMove(touch.clientX, touch.clientY)
    }

    const handleTouchEnd = () => {
      handleEnd()
    }

    window.addEventListener('mousemove', handleMouseMove)
    window.addEventListener('mouseup', handleMouseUp)
    window.addEventListener('touchmove', handleTouchMove)
    window.addEventListener('touchend', handleTouchEnd)

    return () => {
      window.removeEventListener('mousemove', handleMouseMove)
      window.removeEventListener('mouseup', handleMouseUp)
      window.removeEventListener('touchmove', handleTouchMove)
      window.removeEventListener('touchend', handleTouchEnd)
    }
  }, [isDragging, handleMove, handleEnd])

  return (
    <div
      ref={tileRef}
      className={`letter-tile ${isDragging ? 'dragging' : ''} ${disabled ? 'disabled' : ''} ${placed ? 'placed' : ''}`}
      style={{
        transform: isDragging
          ? `translate(${position.x}px, ${position.y}px) scale(1.1)`
          : 'translate(0, 0) scale(1)',
        zIndex: isDragging ? 100 : 1,
      }}
      onMouseDown={handleMouseDown}
      onTouchStart={handleTouchStart}
      data-letter={letter}
      data-id={id}
    >
      {letter.toUpperCase()}
    </div>
  )
}
