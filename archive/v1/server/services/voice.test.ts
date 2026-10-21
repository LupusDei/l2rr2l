import { describe, it, expect, vi, beforeEach } from 'vitest'
import {
  VoiceService,
  VoiceServiceUnavailableError,
  VoiceSettingsValidationFailedError,
  validateVoiceSettings,
  applyVoiceSettingsDefaults,
  VOICE_SETTINGS_DEFAULTS,
  VOICE_SETTINGS_RANGES,
  DEFAULT_VOICE_ID,
} from './voice.js'

// Mock the ElevenLabs client
vi.mock('@elevenlabs/elevenlabs-js', () => {
  class MockElevenLabsClient {
    textToSpeech = {
      convert: vi.fn().mockResolvedValue(
        new ReadableStream({
          start(controller) {
            controller.enqueue(new Uint8Array([1, 2, 3]))
            controller.close()
          },
        })
      ),
      stream: vi.fn().mockResolvedValue(
        new ReadableStream({
          start(controller) {
            controller.enqueue(new Uint8Array([1, 2, 3]))
            controller.close()
          },
        })
      ),
    }
    voices = {
      getAll: vi.fn().mockResolvedValue({
        voices: [
          {
            voiceId: 'voice-1',
            name: 'Test Voice',
            category: 'generated',
            description: 'A test voice',
            previewUrl: 'https://example.com/preview.mp3',
            labels: { accent: 'american' },
          },
        ],
      }),
      get: vi.fn().mockResolvedValue({
        voiceId: 'voice-1',
        name: 'Test Voice',
        category: 'generated',
        description: 'A test voice',
        previewUrl: 'https://example.com/preview.mp3',
        labels: { accent: 'american' },
      }),
      delete: vi.fn().mockResolvedValue({}),
      ivc: {
        create: vi.fn().mockResolvedValue({ voiceId: 'new-voice-id' }),
      },
    }
    speechToText = {
      convert: vi.fn().mockResolvedValue({
        languageCode: 'eng',
        languageProbability: 0.98,
        text: 'Hello world',
        words: [
          {
            text: 'Hello',
            start: 0.0,
            end: 0.5,
            type: 'word',
            logprob: -0.1,
          },
          {
            text: ' ',
            start: 0.5,
            end: 0.5,
            type: 'spacing',
            logprob: 0,
          },
          {
            text: 'world',
            start: 0.5,
            end: 1.0,
            type: 'word',
            logprob: -0.05,
          },
        ],
        transcriptionId: 'txn-123',
      }),
    }
  }

  return {
    ElevenLabsClient: MockElevenLabsClient,
  }
})

describe('VoiceService', () => {
  let voiceService: VoiceService

  beforeEach(() => {
    voiceService = new VoiceService('test-api-key')
  })

  describe('textToSpeech', () => {
    it('converts text to audio buffer', async () => {
      const result = await voiceService.textToSpeech({
        voiceId: 'voice-1',
        text: 'Hello world',
      })

      expect(result).toBeInstanceOf(Buffer)
      expect(result.length).toBeGreaterThan(0)
    })
  })

  describe('listVoices', () => {
    it('returns list of voices', async () => {
      const voices = await voiceService.listVoices()

      expect(voices).toHaveLength(1)
      expect(voices[0]).toEqual({
        voiceId: 'voice-1',
        name: 'Test Voice',
        category: 'generated',
        description: 'A test voice',
        previewUrl: 'https://example.com/preview.mp3',
        labels: { accent: 'american' },
      })
    })
  })

  describe('getVoice', () => {
    it('returns voice by ID', async () => {
      const voice = await voiceService.getVoice('voice-1')

      expect(voice).toEqual({
        voiceId: 'voice-1',
        name: 'Test Voice',
        category: 'generated',
        description: 'A test voice',
        previewUrl: 'https://example.com/preview.mp3',
        labels: { accent: 'american' },
      })
    })
  })

  describe('cloneVoice', () => {
    it('creates a cloned voice', async () => {
      const result = await voiceService.cloneVoice({
        name: 'My Clone',
        files: [],
      })

      expect(result).toEqual({ voiceId: 'new-voice-id' })
    })
  })

  describe('deleteVoice', () => {
    it('deletes a voice successfully', async () => {
      const result = await voiceService.deleteVoice('voice-1')

      expect(result).toBe(true)
    })
  })

  describe('speechToText', () => {
    it('transcribes audio to text', async () => {
      const audioBuffer = Buffer.from([1, 2, 3])
      const result = await voiceService.speechToText({
        file: audioBuffer as unknown as File,
      })

      expect(result.text).toBe('Hello world')
      expect(result.languageCode).toBe('eng')
      expect(result.languageConfidence).toBe(0.98)
      expect(result.transcriptionId).toBe('txn-123')
    })

    it('returns word-level timing information', async () => {
      const audioBuffer = Buffer.from([1, 2, 3])
      const result = await voiceService.speechToText({
        file: audioBuffer as unknown as File,
      })

      expect(result.words).toHaveLength(3)
      expect(result.words[0]).toMatchObject({
        text: 'Hello',
        start: 0.0,
        end: 0.5,
        type: 'word',
      })
      expect(result.words[0].confidence).toBeCloseTo(0.905, 2) // e^(-0.1)
    })

    it('accepts optional parameters', async () => {
      const audioBuffer = Buffer.from([1, 2, 3])
      const result = await voiceService.speechToText({
        file: audioBuffer as unknown as File,
        modelId: 'scribe_v1',
        languageCode: 'en',
        diarize: true,
        numSpeakers: 2,
        timestampsGranularity: 'character',
        tagAudioEvents: false,
      })

      expect(result.text).toBe('Hello world')
    })
  })

  describe('isAvailable', () => {
    it('returns true when API key is provided', () => {
      expect(voiceService.isAvailable()).toBe(true)
    })

    it('returns false when no API key is provided', () => {
      const originalEnv = process.env.ELEVENLABS_API_KEY
      delete process.env.ELEVENLABS_API_KEY
      const service = new VoiceService()
      expect(service.isAvailable()).toBe(false)
      process.env.ELEVENLABS_API_KEY = originalEnv
    })
  })

  describe('service unavailability', () => {
    it('throws VoiceServiceUnavailableError when API key is missing', async () => {
      const originalEnv = process.env.ELEVENLABS_API_KEY
      delete process.env.ELEVENLABS_API_KEY
      const service = new VoiceService()

      await expect(
        service.textToSpeech({ voiceId: 'test', text: 'hello' })
      ).rejects.toThrow(VoiceServiceUnavailableError)

      process.env.ELEVENLABS_API_KEY = originalEnv
    })

    it('throws VoiceServiceUnavailableError for speechToText when API key is missing', async () => {
      const originalEnv = process.env.ELEVENLABS_API_KEY
      delete process.env.ELEVENLABS_API_KEY
      const service = new VoiceService()

      await expect(
        service.speechToText({ file: Buffer.from([1, 2, 3]) as unknown as File })
      ).rejects.toThrow(VoiceServiceUnavailableError)

      process.env.ELEVENLABS_API_KEY = originalEnv
    })
  })

  describe('voice settings validation', () => {
    it('throws VoiceSettingsValidationFailedError for invalid settings', async () => {
      await expect(
        voiceService.textToSpeech({
          voiceId: 'test',
          text: 'hello',
          voiceSettings: { stability: 2 }, // Invalid: > 1
        })
      ).rejects.toThrow(VoiceSettingsValidationFailedError)
    })
  })
})

describe('validateVoiceSettings', () => {
  it('returns empty array for valid settings', () => {
    const errors = validateVoiceSettings({
      stability: 0.5,
      similarityBoost: 0.75,
      style: 0.3,
      speed: 1.0,
    })
    expect(errors).toEqual([])
  })

  it('returns empty array for undefined values', () => {
    const errors = validateVoiceSettings({})
    expect(errors).toEqual([])
  })

  it('returns errors for out-of-range stability', () => {
    const errors = validateVoiceSettings({ stability: 1.5 })
    expect(errors).toHaveLength(1)
    expect(errors[0].field).toBe('stability')
    expect(errors[0].value).toBe(1.5)
    expect(errors[0].min).toBe(0)
    expect(errors[0].max).toBe(1)
  })

  it('returns errors for negative values', () => {
    const errors = validateVoiceSettings({ style: -0.5 })
    expect(errors).toHaveLength(1)
    expect(errors[0].field).toBe('style')
  })

  it('returns errors for out-of-range speed', () => {
    const errors = validateVoiceSettings({ speed: 3.0 })
    expect(errors).toHaveLength(1)
    expect(errors[0].field).toBe('speed')
    expect(errors[0].min).toBe(0.5)
    expect(errors[0].max).toBe(2.0)
  })

  it('returns errors for speed below minimum', () => {
    const errors = validateVoiceSettings({ speed: 0.2 })
    expect(errors).toHaveLength(1)
    expect(errors[0].field).toBe('speed')
  })

  it('returns multiple errors for multiple invalid fields', () => {
    const errors = validateVoiceSettings({
      stability: -1,
      similarityBoost: 2,
      speed: 5,
    })
    expect(errors).toHaveLength(3)
  })

  it('accepts boundary values', () => {
    expect(validateVoiceSettings({ stability: 0 })).toEqual([])
    expect(validateVoiceSettings({ stability: 1 })).toEqual([])
    expect(validateVoiceSettings({ speed: 0.5 })).toEqual([])
    expect(validateVoiceSettings({ speed: 2.0 })).toEqual([])
  })
})

describe('applyVoiceSettingsDefaults', () => {
  it('returns all defaults when no settings provided', () => {
    const result = applyVoiceSettingsDefaults()
    expect(result).toEqual({
      stability: VOICE_SETTINGS_DEFAULTS.stability,
      similarityBoost: VOICE_SETTINGS_DEFAULTS.similarityBoost,
      style: VOICE_SETTINGS_DEFAULTS.style,
      speed: VOICE_SETTINGS_DEFAULTS.speed,
      useSpeakerBoost: VOICE_SETTINGS_DEFAULTS.useSpeakerBoost,
    })
  })

  it('returns all defaults when empty object provided', () => {
    const result = applyVoiceSettingsDefaults({})
    expect(result).toEqual({
      stability: 0.5,
      similarityBoost: 0.75,
      style: 0,
      speed: 1.0,
      useSpeakerBoost: true,
    })
  })

  it('preserves provided values and fills in defaults', () => {
    const result = applyVoiceSettingsDefaults({
      stability: 0.8,
      useSpeakerBoost: false,
    })
    expect(result).toEqual({
      stability: 0.8,
      similarityBoost: 0.75,
      style: 0,
      speed: 1.0,
      useSpeakerBoost: false,
    })
  })

  it('preserves zero values', () => {
    const result = applyVoiceSettingsDefaults({ style: 0, stability: 0 })
    expect(result.style).toBe(0)
    expect(result.stability).toBe(0)
  })
})

describe('constants', () => {
  it('exports DEFAULT_VOICE_ID', () => {
    expect(DEFAULT_VOICE_ID).toBeDefined()
    expect(typeof DEFAULT_VOICE_ID).toBe('string')
  })

  it('exports correct VOICE_SETTINGS_RANGES', () => {
    expect(VOICE_SETTINGS_RANGES.stability).toEqual({ min: 0, max: 1 })
    expect(VOICE_SETTINGS_RANGES.similarityBoost).toEqual({ min: 0, max: 1 })
    expect(VOICE_SETTINGS_RANGES.style).toEqual({ min: 0, max: 1 })
    expect(VOICE_SETTINGS_RANGES.speed).toEqual({ min: 0.5, max: 2.0 })
  })
})
