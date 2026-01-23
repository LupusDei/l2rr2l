import { render, screen } from '@testing-library/react'
import DropZone from './DropZone'

describe('DropZone', () => {
  const defaultProps = {
    index: 0,
    expectedLetter: 'a',
    currentLetter: null,
    isActive: false,
    onGetBounds: vi.fn(),
  }

  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renders placeholder number when empty', () => {
    render(<DropZone {...defaultProps} />)
    expect(screen.getByText('1')).toBeInTheDocument()
  })

  it('renders correct placeholder number based on index', () => {
    render(<DropZone {...defaultProps} index={2} />)
    expect(screen.getByText('3')).toBeInTheDocument()
  })

  it('renders placed letter in uppercase when filled', () => {
    render(<DropZone {...defaultProps} currentLetter="a" />)
    expect(screen.getByText('A')).toBeInTheDocument()
  })

  it('applies active class when isActive is true', () => {
    render(<DropZone {...defaultProps} isActive />)
    const zone = screen.getByText('1').closest('.drop-zone')
    expect(zone).toHaveClass('active')
  })

  it('applies filled class when currentLetter is set', () => {
    render(<DropZone {...defaultProps} currentLetter="a" />)
    const zone = screen.getByText('A').closest('.drop-zone')
    expect(zone).toHaveClass('filled')
  })

  it('applies correct class when letter matches expected', () => {
    render(<DropZone {...defaultProps} currentLetter="a" expectedLetter="a" />)
    const zone = screen.getByText('A').closest('.drop-zone')
    expect(zone).toHaveClass('correct')
  })

  it('does not apply correct class when letter does not match', () => {
    render(<DropZone {...defaultProps} currentLetter="b" expectedLetter="a" />)
    const zone = screen.getByText('B').closest('.drop-zone')
    expect(zone).not.toHaveClass('correct')
  })

  it('applies show-wrong class when showWrongAnimation is true', () => {
    render(<DropZone {...defaultProps} showWrongAnimation />)
    const zone = screen.getByText('1').closest('.drop-zone')
    expect(zone).toHaveClass('show-wrong')
  })

  it('shows star emoji when letter is correct', () => {
    render(<DropZone {...defaultProps} currentLetter="a" expectedLetter="a" />)
    expect(screen.getByText('⭐')).toBeInTheDocument()
  })

  it('does not show star when letter is incorrect', () => {
    render(<DropZone {...defaultProps} currentLetter="b" expectedLetter="a" />)
    expect(screen.queryByText('⭐')).not.toBeInTheDocument()
  })

  it('calls onGetBounds with index and bounds on mount', () => {
    render(<DropZone {...defaultProps} index={1} />)
    expect(defaultProps.onGetBounds).toHaveBeenCalledWith(
      1,
      expect.objectContaining({
        x: expect.any(Number),
        y: expect.any(Number),
        width: expect.any(Number),
        height: expect.any(Number),
      })
    )
  })

  it('applies data attributes for index and expected letter', () => {
    render(<DropZone {...defaultProps} index={2} expectedLetter="c" />)
    const zone = screen.getByText('3').closest('.drop-zone')
    expect(zone).toHaveAttribute('data-index', '2')
    expect(zone).toHaveAttribute('data-expected', 'c')
  })
})
