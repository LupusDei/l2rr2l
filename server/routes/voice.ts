import { Router } from 'express'
import {
  getVoiceService,
  VoiceServiceUnavailableError,
  VoiceSettingsValidationFailedError,
} from '../services/voice.js'

const router = Router()

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

export default router
