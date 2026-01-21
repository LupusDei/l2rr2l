import { describe, it, expect, vi, beforeEach } from 'vitest'
import { VoiceService } from './voice.js'

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
})
