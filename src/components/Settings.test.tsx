import { describe, it, expect, beforeEach, vi } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import Settings from './Settings'

describe('Settings', () => {
  const mockOnBack = vi.fn()
  const mockOnSettingsChange = vi.fn()

  beforeEach(() => {
    vi.clearAllMocks()

    // Mock localStorage
    const localStorageMock = {
      getItem: vi.fn(),
      setItem: vi.fn(),
      removeItem: vi.fn(),
      clear: vi.fn(),
    }
    Object.defineProperty(window, 'localStorage', { value: localStorageMock })

    // Mock fetch for loading settings
    global.fetch = vi.fn().mockImplementation((url: string) => {
      if (url.includes('/api/voice/settings/')) {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve({
            voiceId: 'test-voice-id',
            stability: 0.5,
            similarityBoost: 0.75,
            style: 0,
            speed: 1.0,
            useSpeakerBoost: true,
          }),
        })
      }
      if (url.includes('/api/voice/voices')) {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve({
            voices: [
              { voiceId: 'test-voice-id', name: 'Test Voice', category: 'premade' },
              { voiceId: 'voice-2', name: 'Voice 2', category: 'premade' },
            ],
          }),
        })
      }
      return Promise.reject(new Error('Unknown URL'))
    })
  })

  it('should render loading state initially', () => {
    render(<Settings childId="test-child" onBack={mockOnBack} />)

    expect(screen.getByText('Loading settings...')).toBeInTheDocument()
  })

  it('should render settings after loading', async () => {
    render(<Settings childId="test-child" onBack={mockOnBack} />)

    // Wait for the main Settings title to appear (in h1)
    await waitFor(() => {
      expect(screen.getByRole('heading', { level: 1, name: 'Settings' })).toBeInTheDocument()
    })

    // Also verify the section description is there
    expect(screen.getByText(/Choose a voice and adjust/)).toBeInTheDocument()
  })

  it('should call onBack when back button is clicked', async () => {
    render(<Settings childId="test-child" onBack={mockOnBack} />)

    // Wait for loading to finish
    await waitFor(() => {
      expect(screen.getByRole('heading', { level: 1, name: 'Settings' })).toBeInTheDocument()
    })

    const backButton = screen.getByRole('button', { name: /back/i })
    await userEvent.click(backButton)

    expect(mockOnBack).toHaveBeenCalledTimes(1)
  })

  it('should fall back to default settings when fetch fails', async () => {
    global.fetch = vi.fn().mockRejectedValue(new Error('Network error'))

    render(<Settings childId="test-child" onBack={mockOnBack} />)

    // Should render settings with defaults (not error state)
    await waitFor(() => {
      expect(screen.getByRole('heading', { level: 1, name: 'Settings' })).toBeInTheDocument()
    })

    // Voice settings section should be rendered
    expect(screen.getByText(/Choose a voice and adjust/)).toBeInTheDocument()
  })

  it('should render voice settings section after loading', async () => {
    render(
      <Settings
        childId="test-child"
        onBack={mockOnBack}
        onSettingsChange={mockOnSettingsChange}
      />
    )

    // Wait for the h2 "Voice Settings" heading which only appears after loading
    await waitFor(() => {
      expect(screen.getByRole('heading', { level: 2 })).toBeInTheDocument()
    })

    // Check that VoiceParameterSliders is rendered (it has "Speed" slider by id)
    expect(document.getElementById('slider-speed')).toBeInTheDocument()
  })
})
