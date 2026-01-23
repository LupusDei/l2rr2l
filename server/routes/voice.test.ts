import { describe, it, expect, vi, beforeEach } from 'vitest'
import express from 'express'
import request from 'supertest'
import voiceRoutes from './voice.js'

// Mock the voice service
vi.mock('../services/voice.js', () => ({
  getVoiceService: () => ({
    isAvailable: () => true,
    listVoices: vi.fn().mockResolvedValue([
      {
        voiceId: 'voice-1',
        name: 'Test Voice',
        category: 'generated',
      },
    ]),
    getVoice: vi.fn().mockResolvedValue({
      voiceId: 'voice-1',
      name: 'Test Voice',
      category: 'generated',
    }),
    textToSpeech: vi.fn().mockResolvedValue(Buffer.from([1, 2, 3])),
    speechToText: vi.fn().mockResolvedValue({
      text: 'cat',
      languageCode: 'eng',
      languageProbability: 0.98,
      words: [
        {
          text: 'cat',
          start: 0.0,
          end: 0.5,
          type: 'word',
          confidence: 0.95,
        },
      ],
    }),
  }),
  VoiceServiceUnavailableError: class extends Error {
    constructor() {
      super('Voice service unavailable')
      this.name = 'VoiceServiceUnavailableError'
    }
  },
  VoiceSettingsValidationFailedError: class extends Error {
    constructor(errors: unknown[]) {
      super('Validation failed')
      this.name = 'VoiceSettingsValidationFailedError'
      ;(this as { errors: unknown[] }).errors = errors
    }
  },
}))

const app = express()
app.use(express.json())
app.use('/voice', voiceRoutes)

describe('Voice Routes', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  describe('POST /voice/stt', () => {
    it('should transcribe audio to text', async () => {
      const audioBuffer = Buffer.from([1, 2, 3, 4])

      const res = await request(app)
        .post('/voice/stt')
        .attach('audio', audioBuffer, 'test.webm')

      expect(res.status).toBe(200)
      expect(res.body.text).toBe('cat')
      expect(res.body.languageCode).toBe('eng')
      expect(res.body.words).toBeDefined()
      expect(res.body.words).toHaveLength(1)
    })

    it('should return 400 when no audio file provided', async () => {
      const res = await request(app).post('/voice/stt')

      expect(res.status).toBe(400)
      expect(res.body.error).toBe('audio file is required')
    })
  })

  describe('POST /voice/pronunciation-check', () => {
    it('should return correct for matching pronunciation', async () => {
      const audioBuffer = Buffer.from([1, 2, 3, 4])

      const res = await request(app)
        .post('/voice/pronunciation-check')
        .attach('audio', audioBuffer, 'test.webm')
        .field('expectedWord', 'cat')

      expect(res.status).toBe(200)
      expect(res.body.isCorrect).toBe(true)
      expect(res.body.transcribed).toBe('cat')
      expect(res.body.expected).toBe('cat')
      expect(res.body.feedback).toBeDefined()
      expect(res.body.confidence).toBeGreaterThan(0)
    })

    it('should return incorrect for non-matching pronunciation', async () => {
      const audioBuffer = Buffer.from([1, 2, 3, 4])

      const res = await request(app)
        .post('/voice/pronunciation-check')
        .attach('audio', audioBuffer, 'test.webm')
        .field('expectedWord', 'dog')

      expect(res.status).toBe(200)
      expect(res.body.isCorrect).toBe(false)
      expect(res.body.expected).toBe('dog')
      expect(res.body.feedback).toContain('dog')
    })

    it('should return 400 when no audio file provided', async () => {
      const res = await request(app)
        .post('/voice/pronunciation-check')
        .field('expectedWord', 'cat')

      expect(res.status).toBe(400)
      expect(res.body.error).toBe('audio file is required')
    })

    it('should return 400 when no expected word provided', async () => {
      const audioBuffer = Buffer.from([1, 2, 3, 4])

      const res = await request(app)
        .post('/voice/pronunciation-check')
        .attach('audio', audioBuffer, 'test.webm')

      expect(res.status).toBe(400)
      expect(res.body.error).toBe('expectedWord is required')
    })
  })

  describe('GET /voice/voices', () => {
    it('should return list of voices', async () => {
      const res = await request(app).get('/voice/voices')

      expect(res.status).toBe(200)
      expect(res.body.voices).toBeDefined()
      expect(res.body.voices).toHaveLength(1)
      expect(res.body.voices[0].voiceId).toBe('voice-1')
    })
  })

  describe('POST /voice/tts', () => {
    it('should convert text to speech', async () => {
      const res = await request(app)
        .post('/voice/tts')
        .send({ text: 'Hello world' })

      expect(res.status).toBe(200)
      expect(res.headers['content-type']).toBe('audio/mpeg')
    })

    it('should return 400 when no text provided', async () => {
      const res = await request(app).post('/voice/tts').send({})

      expect(res.status).toBe(400)
      expect(res.body.error).toBe('text is required')
    })
  })
})
