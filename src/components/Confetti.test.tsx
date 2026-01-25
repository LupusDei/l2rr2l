import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { render, screen, act } from '@testing-library/react'
import Confetti from './Confetti'

describe('Confetti', () => {
  beforeEach(() => {
    vi.useFakeTimers()
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it('renders nothing when not active', () => {
    const { container } = render(<Confetti active={false} />)
    expect(container.querySelector('.confetti-container')).toBeNull()
  })

  it('renders confetti pieces when active', () => {
    const { container } = render(<Confetti active={true} pieceCount={10} />)
    const pieces = container.querySelectorAll('.confetti-piece')
    expect(pieces.length).toBe(10)
  })

  it('uses default piece count of 50', () => {
    const { container } = render(<Confetti active={true} />)
    const pieces = container.querySelectorAll('.confetti-piece')
    expect(pieces.length).toBe(50)
  })

  it('removes confetti after duration', () => {
    const onComplete = vi.fn()
    const { container } = render(
      <Confetti active={true} duration={2000} onComplete={onComplete} />
    )

    expect(container.querySelector('.confetti-container')).not.toBeNull()

    act(() => {
      vi.advanceTimersByTime(2000)
    })

    expect(container.querySelector('.confetti-container')).toBeNull()
    expect(onComplete).toHaveBeenCalled()
  })

  it('clears confetti when active becomes false', () => {
    const { container, rerender } = render(<Confetti active={true} />)
    expect(container.querySelector('.confetti-container')).not.toBeNull()

    rerender(<Confetti active={false} />)
    expect(container.querySelector('.confetti-container')).toBeNull()
  })

  it('has aria-hidden on container for accessibility', () => {
    const { container } = render(<Confetti active={true} />)
    const confettiContainer = container.querySelector('.confetti-container')
    expect(confettiContainer).toHaveAttribute('aria-hidden', 'true')
  })

  it('applies styles to confetti pieces', () => {
    const { container } = render(<Confetti active={true} pieceCount={5} />)
    const pieces = container.querySelectorAll('.confetti-piece')

    pieces.forEach((piece) => {
      const style = (piece as HTMLElement).style
      // Each piece should have left position set
      expect(style.left).toMatch(/\d+(\.\d+)?%/)
      // Each piece should have a background color
      expect(style.backgroundColor).toBeTruthy()
    })
  })
})
