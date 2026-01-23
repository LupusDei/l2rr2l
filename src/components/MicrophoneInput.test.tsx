import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import MicrophoneInput from './MicrophoneInput'

// Mock MediaRecorder
class MockMediaRecorder {
  state: 'inactive' | 'recording' | 'paused' = 'inactive'
  ondataavailable: ((event: { data: Blob }) => void) | null = null
  onstop: (() => void) | null = null
  mimeType = 'audio/webm'

  static isTypeSupported = vi.fn(() => true)

  constructor() {
    this.state = 'inactive'
  }

  start() {
    this.state = 'recording'
  }

  stop() {
    this.state = 'inactive'
    // Simulate data available event
    if (this.ondataavailable) {
      this.ondataavailable({ data: new Blob(['audio'], { type: 'audio/webm' }) })
    }
    // Simulate stop event
    if (this.onstop) {
      this.onstop()
    }
  }
}

// Mock AudioContext
class MockAudioContext {
  state: 'running' | 'suspended' | 'closed' = 'running'

  createMediaStreamSource() {
    return {
      connect: vi.fn(),
    }
  }

  createAnalyser() {
    return {
      fftSize: 256,
      frequencyBinCount: 128,
      getByteFrequencyData: vi.fn((array: Uint8Array) => {
        // Fill with some mock data
        for (let i = 0; i < array.length; i++) {
          array[i] = Math.random() * 255
        }
      }),
    }
  }

  close() {
    this.state = 'closed'
    return Promise.resolve()
  }
}

// Mock MediaStream
class MockMediaStream {
  tracks: { stop: () => void }[] = [{ stop: vi.fn() }]

  getTracks() {
    return this.tracks
  }
}

describe('MicrophoneInput', () => {
  const mockOnRecordingComplete = vi.fn()
  const mockOnRecordingStart = vi.fn()
  const mockOnRecordingStop = vi.fn()

  beforeEach(() => {
    vi.clearAllMocks()
    vi.useFakeTimers({ shouldAdvanceTime: true })

    // Set up globals
    global.MediaRecorder = MockMediaRecorder as unknown as typeof MediaRecorder
    global.AudioContext = MockAudioContext as unknown as typeof AudioContext

    // Mock getUserMedia
    Object.defineProperty(global.navigator, 'mediaDevices', {
      value: {
        getUserMedia: vi.fn().mockResolvedValue(new MockMediaStream()),
      },
      writable: true,
    })
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  describe('rendering', () => {
    it('renders the microphone button', () => {
      render(<MicrophoneInput onRecordingComplete={mockOnRecordingComplete} />)

      expect(screen.getByRole('button', { name: /start recording/i })).toBeInTheDocument()
    })

    it('shows "Tap to record" hint when idle', () => {
      render(<MicrophoneInput onRecordingComplete={mockOnRecordingComplete} />)

      expect(screen.getByText('Tap to record')).toBeInTheDocument()
    })

    it('applies disabled class when disabled prop is true', () => {
      const { container } = render(
        <MicrophoneInput onRecordingComplete={mockOnRecordingComplete} disabled />
      )

      expect(container.querySelector('.mic-input-disabled')).toBeInTheDocument()
    })

    it('disables the button when disabled prop is true', () => {
      render(<MicrophoneInput onRecordingComplete={mockOnRecordingComplete} disabled />)

      expect(screen.getByRole('button')).toBeDisabled()
    })
  })

  describe('recording flow', () => {
    it('requests microphone permission when clicked', async () => {
      const user = userEvent.setup({ advanceTimers: vi.advanceTimersByTime })
      render(<MicrophoneInput onRecordingComplete={mockOnRecordingComplete} />)

      const button = screen.getByRole('button', { name: /start recording/i })
      await user.click(button)

      expect(navigator.mediaDevices.getUserMedia).toHaveBeenCalledWith({
        audio: {
          echoCancellation: true,
          noiseSuppression: true,
          sampleRate: 44100,
        },
      })
    })

    it('shows "Requesting microphone..." while requesting permission', async () => {
      // Make getUserMedia hang
      const neverResolve = new Promise(() => {})
      vi.mocked(navigator.mediaDevices.getUserMedia).mockReturnValue(neverResolve as Promise<MediaStream>)

      const user = userEvent.setup({ advanceTimers: vi.advanceTimersByTime })
      render(<MicrophoneInput onRecordingComplete={mockOnRecordingComplete} />)

      const button = screen.getByRole('button', { name: /start recording/i })
      await user.click(button)

      expect(screen.getByText('Requesting microphone...')).toBeInTheDocument()
    })

    it('starts recording after permission is granted', async () => {
      const user = userEvent.setup({ advanceTimers: vi.advanceTimersByTime })
      render(
        <MicrophoneInput
          onRecordingComplete={mockOnRecordingComplete}
          onRecordingStart={mockOnRecordingStart}
        />
      )

      const button = screen.getByRole('button', { name: /start recording/i })
      await user.click(button)

      await waitFor(() => {
        expect(mockOnRecordingStart).toHaveBeenCalled()
      })
    })

    it('shows stop button while recording', async () => {
      const user = userEvent.setup({ advanceTimers: vi.advanceTimersByTime })
      render(<MicrophoneInput onRecordingComplete={mockOnRecordingComplete} />)

      await user.click(screen.getByRole('button', { name: /start recording/i }))

      await waitFor(() => {
        expect(screen.getByRole('button', { name: /stop recording/i })).toBeInTheDocument()
      })
    })

    it('shows recording time while recording', async () => {
      const user = userEvent.setup({ advanceTimers: vi.advanceTimersByTime })
      render(<MicrophoneInput onRecordingComplete={mockOnRecordingComplete} />)

      await user.click(screen.getByRole('button', { name: /start recording/i }))

      await waitFor(() => {
        expect(screen.getByText('0.0s')).toBeInTheDocument()
      })

      // Advance time
      vi.advanceTimersByTime(1000)

      await waitFor(() => {
        expect(screen.getByText('1.0s')).toBeInTheDocument()
      })
    })

    it('shows audio visualizer while recording', async () => {
      const user = userEvent.setup({ advanceTimers: vi.advanceTimersByTime })
      const { container } = render(<MicrophoneInput onRecordingComplete={mockOnRecordingComplete} />)

      await user.click(screen.getByRole('button', { name: /start recording/i }))

      await waitFor(() => {
        expect(container.querySelector('.mic-input-visualizer')).toBeInTheDocument()
      })
    })

    it('stops recording when stop button is clicked', async () => {
      const user = userEvent.setup({ advanceTimers: vi.advanceTimersByTime })
      render(
        <MicrophoneInput
          onRecordingComplete={mockOnRecordingComplete}
          onRecordingStop={mockOnRecordingStop}
        />
      )

      await user.click(screen.getByRole('button', { name: /start recording/i }))

      await waitFor(() => {
        expect(screen.getByRole('button', { name: /stop recording/i })).toBeInTheDocument()
      })

      await user.click(screen.getByRole('button', { name: /stop recording/i }))

      await waitFor(() => {
        expect(mockOnRecordingStop).toHaveBeenCalled()
      })
    })

    it('calls onRecordingComplete with audio blob when recording stops', async () => {
      const user = userEvent.setup({ advanceTimers: vi.advanceTimersByTime })
      render(<MicrophoneInput onRecordingComplete={mockOnRecordingComplete} />)

      await user.click(screen.getByRole('button', { name: /start recording/i }))

      await waitFor(() => {
        expect(screen.getByRole('button', { name: /stop recording/i })).toBeInTheDocument()
      })

      await user.click(screen.getByRole('button', { name: /stop recording/i }))

      await waitFor(() => {
        expect(mockOnRecordingComplete).toHaveBeenCalledWith(expect.any(Blob))
      })
    })

    it('shows "Recording complete!" after stopping', async () => {
      const user = userEvent.setup({ advanceTimers: vi.advanceTimersByTime })
      render(<MicrophoneInput onRecordingComplete={mockOnRecordingComplete} />)

      await user.click(screen.getByRole('button', { name: /start recording/i }))

      await waitFor(() => {
        expect(screen.getByRole('button', { name: /stop recording/i })).toBeInTheDocument()
      })

      await user.click(screen.getByRole('button', { name: /stop recording/i }))

      await waitFor(() => {
        expect(screen.getByText('Recording complete!')).toBeInTheDocument()
      })
    })
  })

  describe('error handling', () => {
    it('shows error when microphone permission is denied', async () => {
      const error = new Error('Permission denied')
      error.name = 'NotAllowedError'
      vi.mocked(navigator.mediaDevices.getUserMedia).mockRejectedValue(error)

      const user = userEvent.setup({ advanceTimers: vi.advanceTimersByTime })
      render(<MicrophoneInput onRecordingComplete={mockOnRecordingComplete} />)

      await user.click(screen.getByRole('button', { name: /start recording/i }))

      await waitFor(() => {
        expect(screen.getByText(/microphone access was denied/i)).toBeInTheDocument()
      })
    })

    it('shows error when no microphone is found', async () => {
      const error = new Error('No device found')
      error.name = 'NotFoundError'
      vi.mocked(navigator.mediaDevices.getUserMedia).mockRejectedValue(error)

      const user = userEvent.setup({ advanceTimers: vi.advanceTimersByTime })
      render(<MicrophoneInput onRecordingComplete={mockOnRecordingComplete} />)

      await user.click(screen.getByRole('button', { name: /start recording/i }))

      await waitFor(() => {
        expect(screen.getByText(/no microphone found/i)).toBeInTheDocument()
      })
    })

    it('shows generic error for other failures', async () => {
      vi.mocked(navigator.mediaDevices.getUserMedia).mockRejectedValue(new Error('Unknown error'))

      const user = userEvent.setup({ advanceTimers: vi.advanceTimersByTime })
      render(<MicrophoneInput onRecordingComplete={mockOnRecordingComplete} />)

      await user.click(screen.getByRole('button', { name: /start recording/i }))

      await waitFor(() => {
        expect(screen.getByText(/could not access microphone/i)).toBeInTheDocument()
      })
    })

    it('allows dismissing the error message', async () => {
      const error = new Error('Permission denied')
      error.name = 'NotAllowedError'
      vi.mocked(navigator.mediaDevices.getUserMedia).mockRejectedValue(error)

      const user = userEvent.setup({ advanceTimers: vi.advanceTimersByTime })
      render(<MicrophoneInput onRecordingComplete={mockOnRecordingComplete} />)

      await user.click(screen.getByRole('button', { name: /start recording/i }))

      await waitFor(() => {
        expect(screen.getByText(/microphone access was denied/i)).toBeInTheDocument()
      })

      await user.click(screen.getByRole('button', { name: /dismiss error/i }))

      expect(screen.queryByText(/microphone access was denied/i)).not.toBeInTheDocument()
    })
  })

  describe('max duration', () => {
    it('automatically stops recording after max duration', async () => {
      const user = userEvent.setup({ advanceTimers: vi.advanceTimersByTime })
      render(
        <MicrophoneInput
          onRecordingComplete={mockOnRecordingComplete}
          maxDuration={5000} // 5 seconds
        />
      )

      await user.click(screen.getByRole('button', { name: /start recording/i }))

      await waitFor(() => {
        expect(screen.getByRole('button', { name: /stop recording/i })).toBeInTheDocument()
      })

      // Advance past max duration
      vi.advanceTimersByTime(5100)

      await waitFor(() => {
        expect(mockOnRecordingComplete).toHaveBeenCalled()
      })
    })
  })

  describe('accessibility', () => {
    it('has proper aria-label on record button', () => {
      render(<MicrophoneInput onRecordingComplete={mockOnRecordingComplete} />)

      expect(screen.getByRole('button', { name: /start recording/i })).toBeInTheDocument()
    })

    it('has proper aria-label on stop button while recording', async () => {
      const user = userEvent.setup({ advanceTimers: vi.advanceTimersByTime })
      render(<MicrophoneInput onRecordingComplete={mockOnRecordingComplete} />)

      await user.click(screen.getByRole('button', { name: /start recording/i }))

      await waitFor(() => {
        expect(screen.getByRole('button', { name: /stop recording/i })).toBeInTheDocument()
      })
    })

    it('error message has role="alert"', async () => {
      const error = new Error('Permission denied')
      error.name = 'NotAllowedError'
      vi.mocked(navigator.mediaDevices.getUserMedia).mockRejectedValue(error)

      const user = userEvent.setup({ advanceTimers: vi.advanceTimersByTime })
      render(<MicrophoneInput onRecordingComplete={mockOnRecordingComplete} />)

      await user.click(screen.getByRole('button', { name: /start recording/i }))

      await waitFor(() => {
        expect(screen.getByRole('alert')).toBeInTheDocument()
      })
    })

    it('visualizer has aria-hidden', async () => {
      const user = userEvent.setup({ advanceTimers: vi.advanceTimersByTime })
      const { container } = render(<MicrophoneInput onRecordingComplete={mockOnRecordingComplete} />)

      await user.click(screen.getByRole('button', { name: /start recording/i }))

      await waitFor(() => {
        const visualizer = container.querySelector('.mic-input-visualizer')
        expect(visualizer).toHaveAttribute('aria-hidden', 'true')
      })
    })
  })
})
