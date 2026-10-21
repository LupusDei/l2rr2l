import { render, screen, fireEvent } from '@testing-library/react'
import LetterTile from './LetterTile'

describe('LetterTile', () => {
  const defaultProps = {
    letter: 'a',
    id: 'tile-1',
    onDragStart: vi.fn(),
    onDragEnd: vi.fn(),
  }

  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renders the letter in uppercase', () => {
    render(<LetterTile {...defaultProps} />)
    expect(screen.getByText('A')).toBeInTheDocument()
  })

  it('applies data attributes for letter and id', () => {
    render(<LetterTile {...defaultProps} />)
    const tile = screen.getByText('A')
    expect(tile).toHaveAttribute('data-letter', 'a')
    expect(tile).toHaveAttribute('data-id', 'tile-1')
  })

  it('calls onDragStart on mousedown', () => {
    render(<LetterTile {...defaultProps} />)
    const tile = screen.getByText('A')
    fireEvent.mouseDown(tile, { clientX: 100, clientY: 100 })
    expect(defaultProps.onDragStart).toHaveBeenCalledWith('tile-1', 'a')
  })

  it('calls onDragStart on touchstart', () => {
    render(<LetterTile {...defaultProps} />)
    const tile = screen.getByText('A')
    fireEvent.touchStart(tile, { touches: [{ clientX: 100, clientY: 100 }] })
    expect(defaultProps.onDragStart).toHaveBeenCalledWith('tile-1', 'a')
  })

  it('does not call onDragStart when disabled', () => {
    render(<LetterTile {...defaultProps} disabled />)
    const tile = screen.getByText('A')
    fireEvent.mouseDown(tile, { clientX: 100, clientY: 100 })
    expect(defaultProps.onDragStart).not.toHaveBeenCalled()
  })

  it('does not call onDragStart when placed', () => {
    render(<LetterTile {...defaultProps} placed />)
    const tile = screen.getByText('A')
    fireEvent.mouseDown(tile, { clientX: 100, clientY: 100 })
    expect(defaultProps.onDragStart).not.toHaveBeenCalled()
  })

  it('applies disabled class when disabled', () => {
    render(<LetterTile {...defaultProps} disabled />)
    const tile = screen.getByText('A')
    expect(tile).toHaveClass('disabled')
  })

  it('applies placed class when placed', () => {
    render(<LetterTile {...defaultProps} placed />)
    const tile = screen.getByText('A')
    expect(tile).toHaveClass('placed')
  })

  it('applies dragging class during drag', () => {
    render(<LetterTile {...defaultProps} />)
    const tile = screen.getByText('A')
    fireEvent.mouseDown(tile, { clientX: 100, clientY: 100 })
    expect(tile).toHaveClass('dragging')
  })

  it('calls onDragEnd on mouseup after drag', () => {
    render(<LetterTile {...defaultProps} />)
    const tile = screen.getByText('A')
    fireEvent.mouseDown(tile, { clientX: 100, clientY: 100 })
    fireEvent.mouseUp(window)
    expect(defaultProps.onDragEnd).toHaveBeenCalled()
  })

  it('calls onDragEnd on touchend after drag', () => {
    render(<LetterTile {...defaultProps} />)
    const tile = screen.getByText('A')
    fireEvent.touchStart(tile, { touches: [{ clientX: 100, clientY: 100 }] })
    fireEvent.touchEnd(window)
    expect(defaultProps.onDragEnd).toHaveBeenCalled()
  })

  it('updates transform during drag', () => {
    render(<LetterTile {...defaultProps} />)
    const tile = screen.getByText('A')
    fireEvent.mouseDown(tile, { clientX: 100, clientY: 100 })
    fireEvent.mouseMove(window, { clientX: 150, clientY: 120 })
    expect(tile.style.transform).toContain('translate(50px, 20px)')
  })

  it('resets transform after drag ends', () => {
    render(<LetterTile {...defaultProps} />)
    const tile = screen.getByText('A')
    fireEvent.mouseDown(tile, { clientX: 100, clientY: 100 })
    fireEvent.mouseMove(window, { clientX: 150, clientY: 120 })
    fireEvent.mouseUp(window)
    expect(tile.style.transform).toContain('translate(0, 0)')
  })

  it('has high z-index during drag', () => {
    render(<LetterTile {...defaultProps} />)
    const tile = screen.getByText('A')
    fireEvent.mouseDown(tile, { clientX: 100, clientY: 100 })
    expect(tile.style.zIndex).toBe('100')
  })

  it('has normal z-index when not dragging', () => {
    render(<LetterTile {...defaultProps} />)
    const tile = screen.getByText('A')
    expect(tile.style.zIndex).toBe('1')
  })

  it('calls onDrag with position during drag', () => {
    const onDrag = vi.fn()
    render(<LetterTile {...defaultProps} onDrag={onDrag} />)
    const tile = screen.getByText('A')
    fireEvent.mouseDown(tile, { clientX: 100, clientY: 100 })
    fireEvent.mouseMove(window, { clientX: 150, clientY: 120 })
    expect(onDrag).toHaveBeenCalledWith(150, 120)
  })

  it('calls onDrag multiple times during drag movement', () => {
    const onDrag = vi.fn()
    render(<LetterTile {...defaultProps} onDrag={onDrag} />)
    const tile = screen.getByText('A')
    fireEvent.mouseDown(tile, { clientX: 100, clientY: 100 })
    fireEvent.mouseMove(window, { clientX: 110, clientY: 110 })
    fireEvent.mouseMove(window, { clientX: 120, clientY: 120 })
    fireEvent.mouseMove(window, { clientX: 130, clientY: 130 })
    expect(onDrag).toHaveBeenCalledTimes(3)
  })
})
