import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import VoiceParameterSliders, { VoiceSettings } from './VoiceParameterSliders'

describe('VoiceParameterSliders', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  describe('rendering', () => {
    it('renders the title and all sliders', () => {
      render(<VoiceParameterSliders />)

      expect(screen.getByText('Voice Settings')).toBeInTheDocument()
      expect(screen.getByText('Speed')).toBeInTheDocument()
      expect(screen.getByText('Stability')).toBeInTheDocument()
      expect(screen.getByText('Clarity')).toBeInTheDocument()
      expect(screen.getByText('Style')).toBeInTheDocument()
      expect(screen.getByText('Speaker Boost')).toBeInTheDocument()
    })

    it('renders with default values', () => {
      render(<VoiceParameterSliders />)

      expect(screen.getByText('1.0x')).toBeInTheDocument() // Speed default
      expect(screen.getByText('50%')).toBeInTheDocument() // Stability default
      expect(screen.getByText('75%')).toBeInTheDocument() // Clarity default
      expect(screen.getByText('0%')).toBeInTheDocument() // Style default
    })

    it('renders the speaker boost toggle as on by default', () => {
      render(<VoiceParameterSliders />)

      const toggle = screen.getByRole('button', { pressed: true })
      expect(toggle).toBeInTheDocument()
      expect(screen.getByText('On')).toBeInTheDocument()
    })

    it('renders the preview section', () => {
      render(<VoiceParameterSliders />)

      expect(screen.getByText('Test Voice')).toBeInTheDocument()
      expect(screen.getByRole('button', { name: /play preview/i })).toBeInTheDocument()
    })

    it('renders with initial settings', () => {
      const initialSettings: Partial<VoiceSettings> = {
        speed: 1.5,
        stability: 0.8,
        similarityBoost: 0.5,
        style: 0.3,
        useSpeakerBoost: false,
      }

      render(<VoiceParameterSliders initialSettings={initialSettings} />)

      expect(screen.getByText('1.5x')).toBeInTheDocument()
      expect(screen.getByText('80%')).toBeInTheDocument()
      expect(screen.getByText('50%')).toBeInTheDocument()
      expect(screen.getByText('30%')).toBeInTheDocument()
      expect(screen.getByText('Off')).toBeInTheDocument()
    })
  })

  describe('slider interactions', () => {
    it('calls onChange when speed slider is changed', async () => {
      const onChange = vi.fn()
      render(<VoiceParameterSliders onChange={onChange} />)

      const speedSlider = document.getElementById('slider-speed') as HTMLInputElement
      fireEvent.change(speedSlider, { target: { value: '1.5' } })

      expect(onChange).toHaveBeenCalledWith(
        expect.objectContaining({ speed: 1.5 })
      )
    })

    it('calls onChange when stability slider is changed', async () => {
      const onChange = vi.fn()
      render(<VoiceParameterSliders onChange={onChange} />)

      const stabilitySlider = document.getElementById('slider-stability') as HTMLInputElement
      fireEvent.change(stabilitySlider, { target: { value: '0.7' } })

      expect(onChange).toHaveBeenCalledWith(
        expect.objectContaining({ stability: 0.7 })
      )
    })

    it('calls onChange when clarity slider is changed', async () => {
      const onChange = vi.fn()
      render(<VoiceParameterSliders onChange={onChange} />)

      const claritySlider = document.getElementById('slider-similarityBoost') as HTMLInputElement
      fireEvent.change(claritySlider, { target: { value: '0.9' } })

      expect(onChange).toHaveBeenCalledWith(
        expect.objectContaining({ similarityBoost: 0.9 })
      )
    })

    it('calls onChange when style slider is changed', async () => {
      const onChange = vi.fn()
      render(<VoiceParameterSliders onChange={onChange} />)

      const styleSlider = document.getElementById('slider-style') as HTMLInputElement
      fireEvent.change(styleSlider, { target: { value: '0.5' } })

      expect(onChange).toHaveBeenCalledWith(
        expect.objectContaining({ style: 0.5 })
      )
    })
  })

  describe('speaker boost toggle', () => {
    it('toggles speaker boost off when clicked', async () => {
      const onChange = vi.fn()
      render(<VoiceParameterSliders onChange={onChange} />)

      const toggle = document.getElementById('toggle-speaker-boost') as HTMLButtonElement
      await userEvent.click(toggle)

      expect(onChange).toHaveBeenCalledWith(
        expect.objectContaining({ useSpeakerBoost: false })
      )
      expect(screen.getByText('Off')).toBeInTheDocument()
    })

    it('toggles speaker boost on when clicked again', async () => {
      const onChange = vi.fn()
      render(
        <VoiceParameterSliders
          initialSettings={{ useSpeakerBoost: false }}
          onChange={onChange}
        />
      )

      const toggle = document.getElementById('toggle-speaker-boost') as HTMLButtonElement
      await userEvent.click(toggle)

      expect(onChange).toHaveBeenCalledWith(
        expect.objectContaining({ useSpeakerBoost: true })
      )
    })
  })

  describe('reset functionality', () => {
    it('does not show reset button when settings are default', () => {
      render(<VoiceParameterSliders />)

      expect(screen.queryByText(/reset/i)).not.toBeInTheDocument()
    })

    it('shows reset button when settings are changed', async () => {
      render(<VoiceParameterSliders />)

      const speedSlider = document.getElementById('slider-speed') as HTMLInputElement
      fireEvent.change(speedSlider, { target: { value: '1.5' } })

      expect(screen.getByText(/reset/i)).toBeInTheDocument()
    })

    it('resets all settings to defaults when reset is clicked', async () => {
      const onChange = vi.fn()
      render(
        <VoiceParameterSliders
          initialSettings={{ speed: 1.5, stability: 0.8 }}
          onChange={onChange}
        />
      )

      const resetButton = screen.getByText(/reset/i)
      await userEvent.click(resetButton)

      expect(onChange).toHaveBeenCalledWith({
        speed: 1.0,
        stability: 0.5,
        similarityBoost: 0.75,
        style: 0,
        useSpeakerBoost: true,
      })
    })
  })

  describe('tooltips', () => {
    it('shows tooltip when info button is clicked', async () => {
      render(<VoiceParameterSliders />)

      const infoButtons = screen.getAllByRole('button', { name: /info about/i })
      await userEvent.click(infoButtons[0]) // Speed tooltip

      expect(
        screen.getByText(/how fast the voice speaks/i)
      ).toBeInTheDocument()
    })

    it('hides tooltip when info button is clicked again', async () => {
      render(<VoiceParameterSliders />)

      const infoButtons = screen.getAllByRole('button', { name: /info about speed/i })
      await userEvent.click(infoButtons[0])
      await userEvent.click(infoButtons[0])

      expect(
        screen.queryByText(/how fast the voice speaks/i)
      ).not.toBeInTheDocument()
    })

    it('only shows one tooltip at a time', async () => {
      render(<VoiceParameterSliders />)

      const speedInfo = screen.getByRole('button', { name: /info about speed/i })
      const stabilityInfo = screen.getByRole('button', { name: /info about stability/i })

      await userEvent.click(speedInfo)
      expect(screen.getByText(/how fast the voice speaks/i)).toBeInTheDocument()

      await userEvent.click(stabilityInfo)
      expect(screen.queryByText(/how fast the voice speaks/i)).not.toBeInTheDocument()
      expect(screen.getByText(/how consistent the voice sounds/i)).toBeInTheDocument()
    })
  })

  describe('preview functionality', () => {
    it('disables play button when no voiceId is provided', () => {
      render(<VoiceParameterSliders />)

      const playButton = screen.getByRole('button', { name: /play preview/i })
      expect(playButton).toBeDisabled()
    })

    it('shows hint when no voice is selected', () => {
      render(<VoiceParameterSliders />)

      expect(screen.getByText(/select a voice above to preview/i)).toBeInTheDocument()
    })

    it('enables play button when voiceId is provided', () => {
      render(<VoiceParameterSliders voiceId="test-voice-id" />)

      const playButton = screen.getByRole('button', { name: /play preview/i })
      expect(playButton).not.toBeDisabled()
    })

    it('calls API when play is clicked', async () => {
      const mockFetch = vi.fn().mockResolvedValue({
        ok: true,
        blob: () => Promise.resolve(new Blob(['audio'], { type: 'audio/mpeg' })),
      })
      global.fetch = mockFetch

      // Mock Audio constructor
      const mockPlay = vi.fn().mockResolvedValue(undefined)
      const mockPause = vi.fn()
      let onendedCallback: (() => void) | null = null

      class MockAudio {
        playbackRate = 1
        onended: (() => void) | null = null
        onerror: (() => void) | null = null

        constructor() {
          // Store onended for later triggering
          setTimeout(() => {
            onendedCallback = this.onended
          }, 0)
        }

        play = mockPlay
        pause = mockPause
      }

      global.Audio = MockAudio as unknown as typeof Audio
      global.URL.createObjectURL = vi.fn(() => 'blob:test')
      global.URL.revokeObjectURL = vi.fn()

      render(<VoiceParameterSliders voiceId="test-voice-id" />)

      const playButton = screen.getByRole('button', { name: /play preview/i })
      await userEvent.click(playButton)

      await waitFor(() => {
        expect(mockFetch).toHaveBeenCalledWith('/api/voice/tts', expect.objectContaining({
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
        }))
      })
    })
  })

  describe('save functionality', () => {
    it('does not render save button when onSave is not provided', () => {
      render(<VoiceParameterSliders />)

      expect(screen.queryByText(/save settings/i)).not.toBeInTheDocument()
    })

    it('renders save button when onSave is provided', () => {
      render(<VoiceParameterSliders onSave={() => {}} />)

      expect(screen.getByText(/save settings/i)).toBeInTheDocument()
    })

    it('calls onSave with current settings when save is clicked', async () => {
      const onSave = vi.fn()
      render(
        <VoiceParameterSliders
          initialSettings={{ speed: 1.5 }}
          onSave={onSave}
        />
      )

      const saveButton = screen.getByText(/save settings/i)
      await userEvent.click(saveButton)

      expect(onSave).toHaveBeenCalledWith(
        expect.objectContaining({ speed: 1.5 })
      )
    })
  })

  describe('accessibility', () => {
    it('has accessible labels for all sliders', () => {
      render(<VoiceParameterSliders />)

      // Sliders have htmlFor/id associations
      expect(document.getElementById('slider-speed')).toBeInTheDocument()
      expect(document.getElementById('slider-stability')).toBeInTheDocument()
      expect(document.getElementById('slider-similarityBoost')).toBeInTheDocument()
      expect(document.getElementById('slider-style')).toBeInTheDocument()
      expect(document.getElementById('toggle-speaker-boost')).toBeInTheDocument()
    })

    it('has aria-pressed on the toggle button', () => {
      render(<VoiceParameterSliders />)

      const toggle = document.getElementById('toggle-speaker-boost')
      expect(toggle).toHaveAttribute('aria-pressed', 'true')
    })

    it('updates aria-pressed when toggle is clicked', async () => {
      render(<VoiceParameterSliders />)

      const toggle = document.getElementById('toggle-speaker-boost') as HTMLButtonElement
      await userEvent.click(toggle)

      expect(toggle).toHaveAttribute('aria-pressed', 'false')
    })
  })
})
