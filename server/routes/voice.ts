import { Router } from 'express'
import { getVoiceService } from '../services/voice.js'

const router = Router()

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
    console.error('Failed to list voices:', error)
    res.status(500).json({ error: 'Failed to list voices' })
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
    console.error('Failed to get voice:', error)
    res.status(500).json({ error: 'Failed to get voice' })
  }
})

/**
 * POST /api/voice/tts
 * Convert text to speech
 */
router.post('/tts', async (req, res) => {
  try {
    const { voiceId, text, modelId, voiceSettings, outputFormat } = req.body

    if (!voiceId || !text) {
      res.status(400).json({ error: 'voiceId and text are required' })
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
    console.error('Failed to convert text to speech:', error)
    res.status(500).json({ error: 'Failed to convert text to speech' })
  }
})

/**
 * POST /api/voice/tts/stream
 * Convert text to speech with streaming response
 */
router.post('/tts/stream', async (req, res) => {
  try {
    const { voiceId, text, modelId, voiceSettings, outputFormat } = req.body

    if (!voiceId || !text) {
      res.status(400).json({ error: 'voiceId and text are required' })
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
    console.error('Failed to stream text to speech:', error)
    res.status(500).json({ error: 'Failed to stream text to speech' })
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
    console.error('Failed to delete voice:', error)
    res.status(500).json({ error: 'Failed to delete voice' })
  }
})

export default router
