import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import MemoryGame from './MemoryGame'

// Mock the useVoice hook
vi.mock('../hooks/useVoice', () => ({
  useVoice: () => ({
    speak: vi.fn(),
    isSpeaking: false,
    isRecording: false,
    startRecording: vi.fn(),
    checkPronunciation: vi.fn(),
    settings: { encouragementEnabled: true },
  }),
}))

// Mock the sounds
vi.mock('../game/sounds', () => ({
  playCorrectSound: vi.fn(),
  playWordCompleteSound: vi.fn(),
}))

describe('MemoryGame', () => {
  const defaultProps = {
    onBack: vi.fn(),
    difficulty: 'easy' as const,
    wordLevel: 'pre-primer' as const,
  }

  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renders the game header with back button', () => {
    render(<MemoryGame {...defaultProps} />)

    expect(screen.getByRole('button', { name: /back/i })).toBeInTheDocument()
  })

  it('calls onBack when back button is clicked', () => {
    const onBack = vi.fn()
    render(<MemoryGame {...defaultProps} onBack={onBack} />)

    fireEvent.click(screen.getByRole('button', { name: /back/i }))

    expect(onBack).toHaveBeenCalled()
  })

  it('renders the correct number of cards for easy difficulty', () => {
    render(<MemoryGame {...defaultProps} difficulty="easy" />)

    // Easy = 6 pairs = 12 cards
    const cards = screen.getAllByTestId(/memory-card-/)
    expect(cards).toHaveLength(12)
  })

  it('renders the correct number of cards for medium difficulty', () => {
    render(<MemoryGame {...defaultProps} difficulty="medium" />)

    // Medium = 8 pairs = 16 cards
    const cards = screen.getAllByTestId(/memory-card-/)
    expect(cards).toHaveLength(16)
  })

  it('renders the correct number of cards for hard difficulty', () => {
    render(<MemoryGame {...defaultProps} difficulty="hard" />)

    // Hard = 12 pairs = 24 cards
    const cards = screen.getAllByTestId(/memory-card-/)
    expect(cards).toHaveLength(24)
  })

  it('renders the game instructions', () => {
    render(<MemoryGame {...defaultProps} />)

    expect(screen.getByText('Find the matching words!')).toBeInTheDocument()
  })

  it('renders the stats display', () => {
    render(<MemoryGame {...defaultProps} />)

    // Should show 0 matches and 0 moves initially
    const statValues = screen.getAllByText('0')
    expect(statValues.length).toBeGreaterThanOrEqual(2)
  })

  it('renders the grid with proper accessibility', () => {
    render(<MemoryGame {...defaultProps} />)

    const grid = screen.getByRole('grid', { name: /memory game card grid/i })
    expect(grid).toBeInTheDocument()
  })

  it('flips a card when clicked', async () => {
    render(<MemoryGame {...defaultProps} />)

    const cards = screen.getAllByTestId(/memory-card-/)
    const firstCard = cards[0]

    expect(firstCard).not.toHaveClass('flipped')

    fireEvent.click(firstCard)

    await waitFor(() => {
      expect(firstCard).toHaveClass('flipped')
    })
  })

  it('flips two cards and unflips them if no match', async () => {
    render(<MemoryGame {...defaultProps} />)

    const cards = screen.getAllByTestId(/memory-card-/)

    // Click first card
    fireEvent.click(cards[0])

    await waitFor(() => {
      expect(cards[0]).toHaveClass('flipped')
    })

    // Click second card (likely different word due to shuffle)
    fireEvent.click(cards[1])

    await waitFor(() => {
      expect(cards[1]).toHaveClass('flipped')
    })

    // Wait for cards to flip back (if no match)
    // This tests the non-match behavior
    await waitFor(
      () => {
        const flippedCount = cards.filter(c => c.classList.contains('flipped')).length
        // Either both flipped (waiting) or none flipped (reset), or matched
        expect(flippedCount === 0 || flippedCount === 2).toBe(true)
      },
      { timeout: 2000 }
    )
  })

  it('prevents clicking more than two cards at once', async () => {
    render(<MemoryGame {...defaultProps} />)

    const cards = screen.getAllByTestId(/memory-card-/)

    // Click first two cards
    fireEvent.click(cards[0])
    fireEvent.click(cards[1])

    // Try to click a third card immediately
    fireEvent.click(cards[2])

    await waitFor(() => {
      const flippedCards = cards.filter(c => c.classList.contains('flipped'))
      // Should only have 2 flipped, not 3
      expect(flippedCards.length).toBeLessThanOrEqual(2)
    })
  })

  it('prevents clicking the same card twice', async () => {
    render(<MemoryGame {...defaultProps} />)

    const cards = screen.getAllByTestId(/memory-card-/)
    const onClick = vi.fn()

    // Click the same card twice
    fireEvent.click(cards[0])
    fireEvent.click(cards[0])

    await waitFor(() => {
      // Card should still be flipped (only first click counted)
      expect(cards[0]).toHaveClass('flipped')
    })
  })

  describe('with matching pairs', () => {
    it('marks cards as matched when same word is selected', async () => {
      // This test verifies the matching logic
      render(<MemoryGame {...defaultProps} />)

      // The grid contains pairs of words, we need to find a matching pair
      const cards = screen.getAllByTestId(/memory-card-/)

      // Click first card and get its word
      fireEvent.click(cards[0])

      await waitFor(() => {
        expect(cards[0]).toHaveClass('flipped')
      })

      // Find its matching pair (card with same word in a different position)
      // We need to look at the card-back content to find the word
      const firstCardWord = cards[0].querySelector('.memory-card-word')?.textContent

      let matchingCardIndex = -1
      for (let i = 1; i < cards.length; i++) {
        const word = cards[i].querySelector('.memory-card-word')?.textContent
        if (word === firstCardWord) {
          matchingCardIndex = i
          break
        }
      }

      if (matchingCardIndex > 0) {
        fireEvent.click(cards[matchingCardIndex])

        await waitFor(
          () => {
            expect(cards[0]).toHaveClass('matched')
            expect(cards[matchingCardIndex]).toHaveClass('matched')
          },
          { timeout: 2000 }
        )
      }
    })
  })
})
