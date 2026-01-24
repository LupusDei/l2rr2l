import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { VoiceProvider, useVoice, type VoiceSettings } from './useVoice'

// Test component that exposes useVoice values
function TestConsumer() {
  const ctx = useVoice()
  return (
    <div>
      <span data-testid="voiceId">{ctx.settings.voiceId}</span>
      <span data-testid="stability">{ctx.settings.stability}</span>
      <span data-testid="similarityBoost">{ctx.settings.similarityBoost}</span>
      <span data-testid="enabled">{String(ctx.settings.enabled)}</span>
      <span data-testid="isSpeaking">{String(ctx.isSpeaking)}</span>
      <button onClick={() => ctx.speak('test phrase')}>Speak</button>
      <button onClick={() => ctx.updateSettings({ voiceId: 'new-voice-id' })}>
        Update Voice
      </button>
    </div>
  )
}

// Mock SpeechSynthesisUtterance class
class MockSpeechSynthesisUtterance {
  text = ''
  rate = 1
  pitch = 1
  volume = 1
  lang = ''
  onend: (() => void) | null = null
  onerror: (() => void) | null = null

  constructor(text?: string) {
    this.text = text || ''
  }
}

describe('useVoice', () => {
  const STORAGE_KEY = 'l2rr2l_voice_settings_dev-child-1'
  const DEFAULT_VOICE_ID = 'cgSgspJ2msm6clMCkdW9' // Jessica

  let localStorageMock: Record<string, string>

  beforeEach(() => {
    vi.clearAllMocks()
    vi.useFakeTimers({ shouldAdvanceTime: true })

    // Mock localStorage
    localStorageMock = {}
    Object.defineProperty(window, 'localStorage', {
      value: {
        getItem: vi.fn((key: string) => localStorageMock[key] || null),
        setItem: vi.fn((key: string, value: string) => {
          localStorageMock[key] = value
        }),
        removeItem: vi.fn((key: string) => {
          delete localStorageMock[key]
        }),
        clear: vi.fn(() => {
          localStorageMock = {}
        }),
      },
      writable: true,
    })

    // Mock fetch
    global.fetch = vi.fn()

    // Mock Web Speech API
    Object.defineProperty(window, 'speechSynthesis', {
      value: {
        speak: vi.fn(),
        cancel: vi.fn(),
        paused: false,
        resume: vi.fn(),
      },
      writable: true,
    })

    // Mock SpeechSynthesisUtterance as a class
    global.SpeechSynthesisUtterance = MockSpeechSynthesisUtterance as unknown as typeof SpeechSynthesisUtterance
  })

  afterEach(() => {
    vi.useRealTimers()
    vi.restoreAllMocks()
  })

  describe('VoiceProvider initialization', () => {
    it('uses default settings when localStorage is empty', () => {
      render(
        <VoiceProvider>
          <TestConsumer />
        </VoiceProvider>
      )

      expect(screen.getByTestId('voiceId').textContent).toBe(DEFAULT_VOICE_ID)
      expect(screen.getByTestId('stability').textContent).toBe('0.5')
      expect(screen.getByTestId('similarityBoost').textContent).toBe('0.75')
      expect(screen.getByTestId('enabled').textContent).toBe('true')
    })

    it('loads voice settings from localStorage on mount', () => {
      const savedSettings = {
        voiceId: 'custom-voice-id',
        stability: 0.8,
        similarityBoost: 0.9,
        enabled: true,
        encouragementEnabled: false,
      }
      localStorageMock[STORAGE_KEY] = JSON.stringify(savedSettings)

      render(
        <VoiceProvider>
          <TestConsumer />
        </VoiceProvider>
      )

      expect(screen.getByTestId('voiceId').textContent).toBe('custom-voice-id')
      expect(screen.getByTestId('stability').textContent).toBe('0.8')
      expect(screen.getByTestId('similarityBoost').textContent).toBe('0.9')
    })

    it('uses default values for missing fields in localStorage', () => {
      const partialSettings = {
        voiceId: 'partial-voice-id',
        // Missing stability, similarityBoost, etc.
      }
      localStorageMock[STORAGE_KEY] = JSON.stringify(partialSettings)

      render(
        <VoiceProvider>
          <TestConsumer />
        </VoiceProvider>
      )

      expect(screen.getByTestId('voiceId').textContent).toBe('partial-voice-id')
      expect(screen.getByTestId('stability').textContent).toBe('0.5') // Default
      expect(screen.getByTestId('similarityBoost').textContent).toBe('0.75') // Default
    })

    it('falls back to defaults when localStorage has invalid JSON', () => {
      localStorageMock[STORAGE_KEY] = 'not valid json'

      render(
        <VoiceProvider>
          <TestConsumer />
        </VoiceProvider>
      )

      expect(screen.getByTestId('voiceId').textContent).toBe(DEFAULT_VOICE_ID)
    })
  })

  describe('speak function', () => {
    it('calls TTS API with correct voiceId from settings', async () => {
      vi.useRealTimers() // Need real timers for this async test

      const mockFetch = vi.fn().mockResolvedValue({
        ok: true,
        blob: () => Promise.resolve(new Blob(['audio'], { type: 'audio/mpeg' })),
      })
      global.fetch = mockFetch

      // Mock Audio with proper class
      class MockAudio {
        src = ''
        playbackRate = 1
        onended: (() => void) | null = null
        onerror: (() => void) | null = null

        play() {
          // Trigger onended after a short delay
          setTimeout(() => {
            this.onended?.()
          }, 10)
          return Promise.resolve()
        }
        pause() {}
      }

      global.Audio = MockAudio as unknown as typeof Audio
      global.URL.createObjectURL = vi.fn(() => 'blob:test')
      global.URL.revokeObjectURL = vi.fn()

      const savedSettings = {
        voiceId: 'elevenlabs-voice-123',
        stability: 0.6,
        similarityBoost: 0.8,
      }
      localStorageMock[STORAGE_KEY] = JSON.stringify(savedSettings)

      render(
        <VoiceProvider>
          <TestConsumer />
        </VoiceProvider>
      )

      const speakButton = screen.getByText('Speak')
      await userEvent.click(speakButton)

      await waitFor(() => {
        expect(mockFetch).toHaveBeenCalledWith('/api/voice/tts', expect.objectContaining({
          method: 'POST',
        }))
      })

      // Verify the body contains correct settings
      const callBody = JSON.parse(mockFetch.mock.calls[0][1].body)
      expect(callBody.voiceId).toBe('elevenlabs-voice-123')
      expect(callBody.voiceSettings.stability).toBe(0.6)
      expect(callBody.voiceSettings.similarityBoost).toBe(0.8)
    })
  })

  describe('updateSettings', () => {
    it('updates settings in state', async () => {
      vi.useRealTimers()

      render(
        <VoiceProvider>
          <TestConsumer />
        </VoiceProvider>
      )

      expect(screen.getByTestId('voiceId').textContent).toBe(DEFAULT_VOICE_ID)

      const updateButton = screen.getByText('Update Voice')
      await userEvent.click(updateButton)

      expect(screen.getByTestId('voiceId').textContent).toBe('new-voice-id')
    })
  })

  describe('context requirement', () => {
    it('throws error when useVoice is used outside VoiceProvider', () => {
      // Suppress console.error for this test
      const consoleSpy = vi.spyOn(console, 'error').mockImplementation(() => {})

      expect(() => {
        render(<TestConsumer />)
      }).toThrow('useVoice must be used within a VoiceProvider')

      consoleSpy.mockRestore()
    })
  })
})

describe('Voice settings persistence flow', () => {
  const STORAGE_KEY = 'l2rr2l_voice_settings_dev-child-1'

  beforeEach(() => {
    vi.clearAllMocks()

    // Mock localStorage with stored settings
    const storedSettings = {
      voiceId: 'user-selected-voice',
      stability: 0.7,
      similarityBoost: 0.85,
      enabled: true,
      encouragementEnabled: true,
    }

    Object.defineProperty(window, 'localStorage', {
      value: {
        getItem: vi.fn((key: string) => {
          if (key === STORAGE_KEY) {
            return JSON.stringify(storedSettings)
          }
          return null
        }),
        setItem: vi.fn(),
        removeItem: vi.fn(),
        clear: vi.fn(),
      },
      writable: true,
    })

    Object.defineProperty(window, 'speechSynthesis', {
      value: {
        speak: vi.fn(),
        cancel: vi.fn(),
        paused: false,
        resume: vi.fn(),
      },
      writable: true,
    })

    global.SpeechSynthesisUtterance = MockSpeechSynthesisUtterance as unknown as typeof SpeechSynthesisUtterance
  })

  it('Settings saved in localStorage are loaded by VoiceProvider', () => {
    // This simulates the game loading after user leaves Settings
    render(
      <VoiceProvider>
        <TestConsumer />
      </VoiceProvider>
    )

    // Verify VoiceProvider loaded the settings
    expect(screen.getByTestId('voiceId').textContent).toBe('user-selected-voice')
    expect(screen.getByTestId('stability').textContent).toBe('0.7')
    expect(screen.getByTestId('similarityBoost').textContent).toBe('0.85')
  })

  it('localStorage.getItem is called with the correct key on mount', () => {
    render(
      <VoiceProvider>
        <TestConsumer />
      </VoiceProvider>
    )

    expect(window.localStorage.getItem).toHaveBeenCalledWith(STORAGE_KEY)
  })
})
