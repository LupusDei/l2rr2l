import { Router } from 'express'
import { randomUUID } from 'crypto'
import multer from 'multer'
import {
  getVoiceService,
  VoiceServiceUnavailableError,
  VoiceSettingsValidationFailedError,
} from '../services/voice.js'
import { db } from '../db/index.js'

const router = Router()

// Configure multer for audio file uploads (in-memory storage)
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB limit
  },
})

interface VoiceSettingsRow {
  id: string
  child_id: string
  voice_id: string
  stability: number
  similarity_boost: number
  style: number
  speed: number
  use_speaker_boost: number
  created_at: string
  updated_at: string
}

/**
 * Handle voice service errors and send appropriate responses
 */
function handleVoiceError(error: unknown, res: import('express').Response, action: string) {
  if (error instanceof VoiceServiceUnavailableError) {
    res.status(503).json({
      error: 'Voice service unavailable',
      message: 'Voice features are not configured. Please set ELEVENLABS_API_KEY.',
    })
    return
  }
  if (error instanceof VoiceSettingsValidationFailedError) {
    res.status(400).json({
      error: 'Invalid voice settings',
      validationErrors: error.errors,
    })
    return
  }
  console.error(`Failed to ${action}:`, error)
  res.status(500).json({ error: `Failed to ${action}` })
}

/**
 * GET /api/voice/voices
 * List all available voices
 */
router.get('/voices', async (_req, res) => {
  try {
    const voiceService = getVoiceService()
    const voices = await voiceService.listVoices()
    res.json({ voices })
  } catch (error) {
    handleVoiceError(error, res, 'list voices')
  }
})

/**
 * GET /api/voice/voices/:voiceId
 * Get a specific voice by ID
 */
router.get('/voices/:voiceId', async (req, res) => {
  try {
    const voiceService = getVoiceService()
    const voice = await voiceService.getVoice(req.params.voiceId)
    if (!voice) {
      res.status(404).json({ error: 'Voice not found' })
      return
    }
    res.json(voice)
  } catch (error) {
    handleVoiceError(error, res, 'get voice')
  }
})

/**
 * POST /api/voice/tts
 * Convert text to speech
 */
router.post('/tts', async (req, res) => {
  try {
    const { voiceId, text, modelId, voiceSettings, outputFormat } = req.body

    if (!text) {
      res.status(400).json({ error: 'text is required' })
      return
    }

    const voiceService = getVoiceService()
    const audioBuffer = await voiceService.textToSpeech({
      voiceId,
      text,
      modelId,
      voiceSettings,
      outputFormat,
    })

    res.set({
      'Content-Type': 'audio/mpeg',
      'Content-Length': audioBuffer.length,
    })
    res.send(audioBuffer)
  } catch (error) {
    handleVoiceError(error, res, 'convert text to speech')
  }
})

/**
 * POST /api/voice/tts/stream
 * Convert text to speech with streaming response
 */
router.post('/tts/stream', async (req, res) => {
  try {
    const { voiceId, text, modelId, voiceSettings, outputFormat } = req.body

    if (!text) {
      res.status(400).json({ error: 'text is required' })
      return
    }

    const voiceService = getVoiceService()
    const stream = await voiceService.textToSpeechStream({
      voiceId,
      text,
      modelId,
      voiceSettings,
      outputFormat,
    })

    res.set({
      'Content-Type': 'audio/mpeg',
      'Transfer-Encoding': 'chunked',
    })

    const reader = stream.getReader()
    const pump = async (): Promise<void> => {
      const { done, value } = await reader.read()
      if (done) {
        res.end()
        return
      }
      res.write(Buffer.from(value))
      return pump()
    }
    await pump()
  } catch (error) {
    handleVoiceError(error, res, 'stream text to speech')
  }
})

/**
 * DELETE /api/voice/voices/:voiceId
 * Delete a cloned voice
 */
router.delete('/voices/:voiceId', async (req, res) => {
  try {
    const voiceService = getVoiceService()
    const success = await voiceService.deleteVoice(req.params.voiceId)
    if (!success) {
      res.status(404).json({ error: 'Voice not found or could not be deleted' })
      return
    }
    res.json({ success: true })
  } catch (error) {
    handleVoiceError(error, res, 'delete voice')
  }
})

/**
 * GET /api/voice/settings/:childId
 * Get voice settings for a child (or defaults if not set)
 */
router.get('/settings/:childId', (req, res) => {
  try {
    const { childId } = req.params

    const row = db
      .prepare('SELECT * FROM voice_settings WHERE child_id = ?')
      .get(childId) as VoiceSettingsRow | undefined

    if (row) {
      res.json({
        voiceId: row.voice_id,
        stability: row.stability,
        similarityBoost: row.similarity_boost,
        style: row.style,
        speed: row.speed,
        useSpeakerBoost: row.use_speaker_boost === 1,
      })
    } else {
      // Return default settings
      res.json({
        voiceId: 'pMsXgVXv3BLzUgSXRplE',
        stability: 0.5,
        similarityBoost: 0.75,
        style: 0,
        speed: 1.0,
        useSpeakerBoost: true,
      })
    }
  } catch (error) {
    console.error('Failed to get voice settings:', error)
    res.status(500).json({ error: 'Failed to get voice settings' })
  }
})

/**
 * PUT /api/voice/settings/:childId
 * Save voice settings for a child
 */
router.put('/settings/:childId', (req, res) => {
  try {
    const { childId } = req.params
    const { voiceId, stability, similarityBoost, style, speed, useSpeakerBoost } = req.body

    // Validate settings
    const errors: Array<{ field: string; message: string }> = []

    if (stability !== undefined && (stability < 0 || stability > 1)) {
      errors.push({ field: 'stability', message: 'stability must be between 0 and 1' })
    }
    if (similarityBoost !== undefined && (similarityBoost < 0 || similarityBoost > 1)) {
      errors.push({ field: 'similarityBoost', message: 'similarityBoost must be between 0 and 1' })
    }
    if (style !== undefined && (style < 0 || style > 1)) {
      errors.push({ field: 'style', message: 'style must be between 0 and 1' })
    }
    if (speed !== undefined && (speed < 0.5 || speed > 2.0)) {
      errors.push({ field: 'speed', message: 'speed must be between 0.5 and 2.0' })
    }

    if (errors.length > 0) {
      res.status(400).json({ error: 'Invalid voice settings', validationErrors: errors })
      return
    }

    // Check if settings exist for this child
    const existing = db
      .prepare('SELECT id FROM voice_settings WHERE child_id = ?')
      .get(childId) as { id: string } | undefined

    if (existing) {
      // Update existing settings
      db.prepare(`
        UPDATE voice_settings SET
          voice_id = COALESCE(?, voice_id),
          stability = COALESCE(?, stability),
          similarity_boost = COALESCE(?, similarity_boost),
          style = COALESCE(?, style),
          speed = COALESCE(?, speed),
          use_speaker_boost = COALESCE(?, use_speaker_boost),
          updated_at = datetime('now')
        WHERE child_id = ?
      `).run(
        voiceId ?? null,
        stability ?? null,
        similarityBoost ?? null,
        style ?? null,
        speed ?? null,
        useSpeakerBoost !== undefined ? (useSpeakerBoost ? 1 : 0) : null,
        childId
      )
    } else {
      // Insert new settings
      db.prepare(`
        INSERT INTO voice_settings (id, child_id, voice_id, stability, similarity_boost, style, speed, use_speaker_boost)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      `).run(
        randomUUID(),
        childId,
        voiceId ?? 'pMsXgVXv3BLzUgSXRplE',
        stability ?? 0.5,
        similarityBoost ?? 0.75,
        style ?? 0,
        speed ?? 1.0,
        useSpeakerBoost !== undefined ? (useSpeakerBoost ? 1 : 0) : 1
      )
    }

    // Return the updated settings
    const row = db
      .prepare('SELECT * FROM voice_settings WHERE child_id = ?')
      .get(childId) as VoiceSettingsRow

    res.json({
      voiceId: row.voice_id,
      stability: row.stability,
      similarityBoost: row.similarity_boost,
      style: row.style,
      speed: row.speed,
      useSpeakerBoost: row.use_speaker_boost === 1,
    })
  } catch (error) {
    console.error('Failed to save voice settings:', error)
    res.status(500).json({ error: 'Failed to save voice settings' })
  }
})

/**
 * POST /api/voice/stt
 * Convert speech to text
 */
router.post('/stt', upload.single('audio'), async (req, res) => {
  try {
    if (!req.file) {
      res.status(400).json({ error: 'audio file is required' })
      return
    }

    const voiceService = getVoiceService()
    const result = await voiceService.speechToText({
      file: req.file.buffer as unknown as File,
      timestampsGranularity: 'word',
    })

    res.json({
      text: result.text,
      words: result.words,
      languageCode: result.languageCode,
      languageConfidence: result.languageConfidence,
    })
  } catch (error) {
    handleVoiceError(error, res, 'transcribe speech')
  }
})

/**
 * POST /api/voice/pronunciation-check
 * Check pronunciation against expected word
 */
router.post('/pronunciation-check', upload.single('audio'), async (req, res) => {
  try {
    if (!req.file) {
      res.status(400).json({ error: 'audio file is required' })
      return
    }

    const { expectedWord } = req.body
    if (!expectedWord) {
      res.status(400).json({ error: 'expectedWord is required' })
      return
    }

    const voiceService = getVoiceService()
    const result = await voiceService.speechToText({
      file: req.file.buffer as unknown as File,
      timestampsGranularity: 'word',
    })

    // Normalize both for comparison (lowercase, trim whitespace)
    const transcribedNormalized = result.text.toLowerCase().trim()
    const expectedNormalized = expectedWord.toLowerCase().trim()

    // Check for exact match or if transcription contains the expected word
    const isCorrect =
      transcribedNormalized === expectedNormalized ||
      transcribedNormalized.includes(expectedNormalized)

    // Calculate confidence based on word-level confidences
    const wordConfidences = result.words
      .filter((w) => w.type === 'word')
      .map((w) => w.confidence)
    const avgConfidence =
      wordConfidences.length > 0
        ? wordConfidences.reduce((a, b) => a + b, 0) / wordConfidences.length
        : 0

    res.json({
      isCorrect,
      transcribed: result.text,
      expected: expectedWord,
      confidence: avgConfidence,
      feedback: isCorrect
        ? getPositiveFeedback()
        : getEncouragingFeedback(expectedWord),
    })
  } catch (error) {
    handleVoiceError(error, res, 'check pronunciation')
  }
})

// Positive feedback messages for correct pronunciation
function getPositiveFeedback(): string {
  const messages = [
    'Great job!',
    'Perfect!',
    'You said it!',
    'Excellent!',
    'Wonderful!',
    'Amazing!',
  ]
  return messages[Math.floor(Math.random() * messages.length)]
}

// Encouraging feedback for incorrect pronunciation
function getEncouragingFeedback(word: string): string {
  const messages = [
    `Try again! Say "${word}"`,
    `Almost! Try saying "${word}" again`,
    `Good try! Can you say "${word}"?`,
    `Let's try "${word}" one more time!`,
  ]
  return messages[Math.floor(Math.random() * messages.length)]
}

export default router
