import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import MemoryCard from './MemoryCard'

describe('MemoryCard', () => {
  const defaultProps = {
    id: 'card-1',
    word: 'the',
    isFlipped: false,
    isMatched: false,
    onClick: vi.fn(),
    disabled: false,
  }

  it('renders with face-down state by default', () => {
    render(<MemoryCard {...defaultProps} />)

    const card = screen.getByTestId('memory-card-card-1')
    expect(card).not.toHaveClass('flipped')
    expect(card).not.toHaveClass('matched')
  })

  it('renders with flipped state when isFlipped is true', () => {
    render(<MemoryCard {...defaultProps} isFlipped={true} />)

    const card = screen.getByTestId('memory-card-card-1')
    expect(card).toHaveClass('flipped')
  })

  it('renders with matched state when isMatched is true', () => {
    render(<MemoryCard {...defaultProps} isMatched={true} />)

    const card = screen.getByTestId('memory-card-card-1')
    expect(card).toHaveClass('matched')
  })

  it('calls onClick when clicked and not disabled or flipped', () => {
    const onClick = vi.fn()
    render(<MemoryCard {...defaultProps} onClick={onClick} />)

    const card = screen.getByTestId('memory-card-card-1')
    fireEvent.click(card)

    expect(onClick).toHaveBeenCalledWith('card-1')
  })

  it('does not call onClick when disabled', () => {
    const onClick = vi.fn()
    render(<MemoryCard {...defaultProps} onClick={onClick} disabled={true} />)

    const card = screen.getByTestId('memory-card-card-1')
    fireEvent.click(card)

    expect(onClick).not.toHaveBeenCalled()
  })

  it('does not call onClick when already flipped', () => {
    const onClick = vi.fn()
    render(<MemoryCard {...defaultProps} onClick={onClick} isFlipped={true} />)

    const card = screen.getByTestId('memory-card-card-1')
    fireEvent.click(card)

    expect(onClick).not.toHaveBeenCalled()
  })

  it('does not call onClick when already matched', () => {
    const onClick = vi.fn()
    render(<MemoryCard {...defaultProps} onClick={onClick} isMatched={true} />)

    const card = screen.getByTestId('memory-card-card-1')
    fireEvent.click(card)

    expect(onClick).not.toHaveBeenCalled()
  })

  it('has proper accessibility attributes when face-down', () => {
    render(<MemoryCard {...defaultProps} />)

    const card = screen.getByTestId('memory-card-card-1')
    expect(card).toHaveAttribute('role', 'button')
    expect(card).toHaveAttribute('aria-label', 'Face-down card')
    expect(card).toHaveAttribute('aria-pressed', 'false')
  })

  it('has proper accessibility attributes when flipped', () => {
    render(<MemoryCard {...defaultProps} isFlipped={true} />)

    const card = screen.getByTestId('memory-card-card-1')
    expect(card).toHaveAttribute('aria-label', 'Card showing "the"')
    expect(card).toHaveAttribute('aria-pressed', 'true')
  })

  it('responds to keyboard Enter key', () => {
    const onClick = vi.fn()
    render(<MemoryCard {...defaultProps} onClick={onClick} />)

    const card = screen.getByTestId('memory-card-card-1')
    fireEvent.keyDown(card, { key: 'Enter' })

    expect(onClick).toHaveBeenCalledWith('card-1')
  })

  it('responds to keyboard Space key', () => {
    const onClick = vi.fn()
    render(<MemoryCard {...defaultProps} onClick={onClick} />)

    const card = screen.getByTestId('memory-card-card-1')
    fireEvent.keyDown(card, { key: ' ' })

    expect(onClick).toHaveBeenCalledWith('card-1')
  })

  it('has tabIndex 0 when interactive', () => {
    render(<MemoryCard {...defaultProps} />)

    const card = screen.getByTestId('memory-card-card-1')
    expect(card).toHaveAttribute('tabIndex', '0')
  })

  it('has tabIndex -1 when disabled', () => {
    render(<MemoryCard {...defaultProps} disabled={true} />)

    const card = screen.getByTestId('memory-card-card-1')
    expect(card).toHaveAttribute('tabIndex', '-1')
  })

  it('has tabIndex -1 when matched', () => {
    render(<MemoryCard {...defaultProps} isMatched={true} />)

    const card = screen.getByTestId('memory-card-card-1')
    expect(card).toHaveAttribute('tabIndex', '-1')
  })

  it('displays the word on the card back', () => {
    render(<MemoryCard {...defaultProps} word="look" />)

    expect(screen.getByText('look')).toBeInTheDocument()
  })

  it('displays ? symbol on the card front', () => {
    render(<MemoryCard {...defaultProps} />)

    expect(screen.getByText('?')).toBeInTheDocument()
  })
})
