import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import VoiceSelector, { Voice } from './VoiceSelector'

const mockVoices: Voice[] = [
  {
    voiceId: 'voice-1',
    name: 'Friendly Voice',
    category: 'premade',
    description: 'A warm, friendly voice for children',
    previewUrl: 'https://example.com/preview1.mp3',
  },
  {
    voiceId: 'voice-2',
    name: 'Professional Voice',
    category: 'professional',
    description: 'Clear and professional',
    previewUrl: 'https://example.com/preview2.mp3',
  },
  {
    voiceId: 'voice-3',
    name: 'Adult Voice',
    category: 'cloned',
    description: 'A cloned adult voice',
    previewUrl: 'https://example.com/preview3.mp3',
  },
]

describe('VoiceSelector', () => {
  const defaultProps = {
    onVoiceSelect: vi.fn(),
  }

  beforeEach(() => {
    vi.clearAllMocks()
    global.fetch = vi.fn()
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('shows loading state while fetching voices', () => {
    ;(global.fetch as ReturnType<typeof vi.fn>).mockImplementation(() => new Promise(() => {}))

    render(<VoiceSelector {...defaultProps} />)
    expect(screen.getByText('Loading voices...')).toBeInTheDocument()
  })

  it('displays error state when fetch fails', async () => {
    ;(global.fetch as ReturnType<typeof vi.fn>).mockRejectedValue(new Error('Network error'))

    render(<VoiceSelector {...defaultProps} />)

    await waitFor(() => {
      expect(screen.getByText('Network error')).toBeInTheDocument()
    })
    expect(screen.getByText('Try Again')).toBeInTheDocument()
  })

  it('renders voice selector trigger after loading', async () => {
    ;(global.fetch as ReturnType<typeof vi.fn>).mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({ voices: mockVoices }),
    })

    render(<VoiceSelector {...defaultProps} />)

    await waitFor(() => {
      expect(screen.getByText('Select a voice...')).toBeInTheDocument()
    })
  })

  it('opens dropdown when clicking trigger', async () => {
    ;(global.fetch as ReturnType<typeof vi.fn>).mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({ voices: mockVoices }),
    })

    render(<VoiceSelector {...defaultProps} />)

    await waitFor(() => {
      expect(screen.getByText('Select a voice...')).toBeInTheDocument()
    })

    fireEvent.click(screen.getByRole('button', { expanded: false }))

    expect(screen.getByRole('listbox')).toBeInTheDocument()
  })

  it('displays voice options in dropdown', async () => {
    ;(global.fetch as ReturnType<typeof vi.fn>).mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({ voices: mockVoices }),
    })

    render(<VoiceSelector {...defaultProps} showChildFriendlyOnly={false} />)

    await waitFor(() => {
      expect(screen.getByText('Select a voice...')).toBeInTheDocument()
    })

    fireEvent.click(screen.getByRole('button', { expanded: false }))

    expect(screen.getByText('Friendly Voice')).toBeInTheDocument()
    expect(screen.getByText('Professional Voice')).toBeInTheDocument()
  })

  it('calls onVoiceSelect when selecting a voice', async () => {
    ;(global.fetch as ReturnType<typeof vi.fn>).mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({ voices: mockVoices }),
    })

    render(<VoiceSelector {...defaultProps} showChildFriendlyOnly={false} />)

    await waitFor(() => {
      expect(screen.getByText('Select a voice...')).toBeInTheDocument()
    })

    fireEvent.click(screen.getByRole('button', { expanded: false }))
    fireEvent.click(screen.getByText('Friendly Voice'))

    expect(defaultProps.onVoiceSelect).toHaveBeenCalledWith(mockVoices[0])
  })

  it('closes dropdown after selecting a voice', async () => {
    ;(global.fetch as ReturnType<typeof vi.fn>).mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({ voices: mockVoices }),
    })

    render(<VoiceSelector {...defaultProps} showChildFriendlyOnly={false} />)

    await waitFor(() => {
      expect(screen.getByText('Select a voice...')).toBeInTheDocument()
    })

    fireEvent.click(screen.getByRole('button', { expanded: false }))
    expect(screen.getByRole('listbox')).toBeInTheDocument()

    fireEvent.click(screen.getByText('Friendly Voice'))

    expect(screen.queryByRole('listbox')).not.toBeInTheDocument()
  })

  it('shows selected voice name in trigger', async () => {
    ;(global.fetch as ReturnType<typeof vi.fn>).mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({ voices: mockVoices }),
    })

    render(
      <VoiceSelector
        {...defaultProps}
        selectedVoiceId="voice-1"
        showChildFriendlyOnly={false}
      />
    )

    await waitFor(() => {
      expect(screen.getByText('Friendly Voice')).toBeInTheDocument()
    })
  })

  it('filters child-friendly voices by default', async () => {
    ;(global.fetch as ReturnType<typeof vi.fn>).mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({ voices: mockVoices }),
    })

    render(<VoiceSelector {...defaultProps} showChildFriendlyOnly={true} />)

    await waitFor(() => {
      expect(screen.getByText('Select a voice...')).toBeInTheDocument()
    })

    fireEvent.click(screen.getByRole('button', { expanded: false }))

    // Should show premade and professional (child-friendly)
    expect(screen.getByText('Friendly Voice')).toBeInTheDocument()
    expect(screen.getByText('Professional Voice')).toBeInTheDocument()
    // Should not show cloned (not child-friendly by default)
    expect(screen.queryByText('Adult Voice')).not.toBeInTheDocument()
  })

  it('shows all voices when filter is unchecked', async () => {
    ;(global.fetch as ReturnType<typeof vi.fn>).mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({ voices: mockVoices }),
    })

    render(<VoiceSelector {...defaultProps} showChildFriendlyOnly={true} />)

    await waitFor(() => {
      expect(screen.getByText('Select a voice...')).toBeInTheDocument()
    })

    fireEvent.click(screen.getByRole('button', { expanded: false }))
    fireEvent.click(screen.getByLabelText(/child-friendly/i))

    expect(screen.getByText('Friendly Voice')).toBeInTheDocument()
    expect(screen.getByText('Professional Voice')).toBeInTheDocument()
    expect(screen.getByText('Adult Voice')).toBeInTheDocument()
  })

  it('shows preview button for voices with previewUrl', async () => {
    ;(global.fetch as ReturnType<typeof vi.fn>).mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({ voices: mockVoices }),
    })

    render(<VoiceSelector {...defaultProps} showChildFriendlyOnly={false} />)

    await waitFor(() => {
      expect(screen.getByText('Select a voice...')).toBeInTheDocument()
    })

    fireEvent.click(screen.getByRole('button', { expanded: false }))

    const previewButtons = screen.getAllByLabelText('Play preview')
    expect(previewButtons).toHaveLength(3)
  })

  it('closes dropdown when clicking outside', async () => {
    ;(global.fetch as ReturnType<typeof vi.fn>).mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({ voices: mockVoices }),
    })

    render(<VoiceSelector {...defaultProps} />)

    await waitFor(() => {
      expect(screen.getByText('Select a voice...')).toBeInTheDocument()
    })

    fireEvent.click(screen.getByRole('button', { expanded: false }))
    expect(screen.getByRole('listbox')).toBeInTheDocument()

    fireEvent.mouseDown(document.body)

    expect(screen.queryByRole('listbox')).not.toBeInTheDocument()
  })

  it('shows empty state when no voices available', async () => {
    ;(global.fetch as ReturnType<typeof vi.fn>).mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({ voices: [] }),
    })

    render(<VoiceSelector {...defaultProps} />)

    await waitFor(() => {
      expect(screen.getByText('Select a voice...')).toBeInTheDocument()
    })

    fireEvent.click(screen.getByRole('button', { expanded: false }))

    expect(screen.getByText('No voices available')).toBeInTheDocument()
  })

  it('shows voice category as label', async () => {
    ;(global.fetch as ReturnType<typeof vi.fn>).mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({ voices: mockVoices }),
    })

    render(<VoiceSelector {...defaultProps} showChildFriendlyOnly={false} />)

    await waitFor(() => {
      expect(screen.getByText('Select a voice...')).toBeInTheDocument()
    })

    fireEvent.click(screen.getByRole('button', { expanded: false }))

    expect(screen.getAllByText('Standard').length).toBeGreaterThan(0)
    expect(screen.getAllByText('Professional').length).toBeGreaterThan(0)
  })

  it('handles API error response', async () => {
    ;(global.fetch as ReturnType<typeof vi.fn>).mockResolvedValue({
      ok: false,
      status: 500,
    })

    render(<VoiceSelector {...defaultProps} />)

    await waitFor(() => {
      expect(screen.getByText('Failed to load voices')).toBeInTheDocument()
    })
  })
})
