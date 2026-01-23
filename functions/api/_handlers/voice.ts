/**
 * Voice handler for Cloudflare Functions
 * Handles /api/voice/* routes (except settings)
 */

import { ElevenLabsClient } from '@elevenlabs/elevenlabs-js'
import type { Env } from '../../types'
import { jsonResponse, errorResponse } from '../[[path]]'

// Default voice ID
const DEFAULT_VOICE_ID = 'EXAVITQu4vr4xnSDxMaL'

// Default voice settings
const DEFAULT_VOICE_SETTINGS = {
  stability: 0.5,
  similarityBoost: 0.75,
  style: 0,
  speed: 1.0,
  useSpeakerBoost: true,
}

interface VoiceSettings {
  stability?: number
  similarityBoost?: number
  style?: number
  speed?: number
  useSpeakerBoost?: boolean
}

/**
 * Get ElevenLabs client, or null if not configured
 */
function getClient(env: Env): ElevenLabsClient | null {
  if (!env.ELEVENLABS_API_KEY) {
    return null
  }
  return new ElevenLabsClient({ apiKey: env.ELEVENLABS_API_KEY })
}

/**
 * Return service unavailable error
 */
function serviceUnavailable(): Response {
  return jsonResponse(
    {
      error: 'Voice service unavailable',
      message: 'Voice features are not configured. Please set ELEVENLABS_API_KEY.',
    },
    503
  )
}

/**
 * Apply default values to voice settings
 */
function applyDefaults(settings?: VoiceSettings): Required<VoiceSettings> {
  return {
    stability: settings?.stability ?? DEFAULT_VOICE_SETTINGS.stability,
    similarityBoost: settings?.similarityBoost ?? DEFAULT_VOICE_SETTINGS.similarityBoost,
    style: settings?.style ?? DEFAULT_VOICE_SETTINGS.style,
    speed: settings?.speed ?? DEFAULT_VOICE_SETTINGS.speed,
    useSpeakerBoost: settings?.useSpeakerBoost ?? DEFAULT_VOICE_SETTINGS.useSpeakerBoost,
  }
}

/**
 * Handle voice routes
 */
export async function handleVoice(
  request: Request,
  env: Env,
  pathSegments: string[]
): Promise<Response> {
  const action = pathSegments[0] || ''

  switch (action) {
    case 'voices':
      if (pathSegments[1]) {
        // /api/voice/voices/:voiceId
        if (request.method === 'GET') {
          return await getVoice(env, pathSegments[1])
        }
        if (request.method === 'DELETE') {
          return await deleteVoice(env, pathSegments[1])
        }
      } else {
        // /api/voice/voices
        if (request.method === 'GET') {
          return await listVoices(env)
        }
      }
      break

    case 'tts':
      if (request.method === 'POST') {
        return await textToSpeech(request, env)
      }
      break

    case 'stt':
      if (request.method === 'POST') {
        return await speechToText(request, env)
      }
      break

    case 'pronunciation-check':
      if (request.method === 'POST') {
        return await pronunciationCheck(request, env)
      }
      break
  }

  return errorResponse('Method not allowed', 405)
}

/**
 * GET /api/voice/voices - list all available voices
 */
async function listVoices(env: Env): Promise<Response> {
  const client = getClient(env)
  if (!client) {
    return serviceUnavailable()
  }

  try {
    const response = await client.voices.getAll()

    const voices = response.voices.map((voice) => ({
      voiceId: voice.voiceId,
      name: voice.name ?? 'Unknown',
      category: voice.category,
      description: voice.description ?? undefined,
      previewUrl: voice.previewUrl ?? undefined,
      labels: voice.labels as Record<string, string> | undefined,
    }))

    return jsonResponse({ voices })
  } catch (error) {
    console.error('Failed to list voices:', error)
    return errorResponse('Failed to list voices', 500)
  }
}

/**
 * GET /api/voice/voices/:voiceId - get a specific voice
 */
async function getVoice(env: Env, voiceId: string): Promise<Response> {
  const client = getClient(env)
  if (!client) {
    return serviceUnavailable()
  }

  try {
    const voice = await client.voices.get(voiceId)

    return jsonResponse({
      voiceId: voice.voiceId,
      name: voice.name ?? 'Unknown',
      category: voice.category,
      description: voice.description ?? undefined,
      previewUrl: voice.previewUrl ?? undefined,
      labels: voice.labels as Record<string, string> | undefined,
    })
  } catch {
    return errorResponse('Voice not found', 404)
  }
}

/**
 * DELETE /api/voice/voices/:voiceId - delete a cloned voice
 */
async function deleteVoice(env: Env, voiceId: string): Promise<Response> {
  const client = getClient(env)
  if (!client) {
    return serviceUnavailable()
  }

  try {
    await client.voices.delete(voiceId)
    return jsonResponse({ success: true })
  } catch {
    return errorResponse('Voice not found or could not be deleted', 404)
  }
}

/**
 * POST /api/voice/tts - convert text to speech
 */
async function textToSpeech(request: Request, env: Env): Promise<Response> {
  const client = getClient(env)
  if (!client) {
    return serviceUnavailable()
  }

  try {
    const body = await request.json() as {
      voiceId?: string
      text?: string
      modelId?: string
      voiceSettings?: VoiceSettings
      outputFormat?: string
    }

    const { voiceId, text, modelId, voiceSettings, outputFormat } = body

    if (!text) {
      return errorResponse('text is required', 400)
    }

    const settings = applyDefaults(voiceSettings)

    const response = await client.textToSpeech.convert(voiceId || DEFAULT_VOICE_ID, {
      text,
      modelId: modelId || 'eleven_multilingual_v2',
      outputFormat: (outputFormat || 'mp3_44100_128') as 'mp3_44100_128',
      voiceSettings: {
        stability: settings.stability,
        similarityBoost: settings.similarityBoost,
        style: settings.style,
        useSpeakerBoost: settings.useSpeakerBoost,
      },
    })

    // Convert ReadableStream to ArrayBuffer
    const reader = response.getReader()
    const chunks: Uint8Array[] = []
    while (true) {
      const { done, value } = await reader.read()
      if (done) break
      if (value) chunks.push(value)
    }
    const audioBuffer = new Uint8Array(
      chunks.reduce((acc, chunk) => acc + chunk.length, 0)
    )
    let offset = 0
    for (const chunk of chunks) {
      audioBuffer.set(chunk, offset)
      offset += chunk.length
    }

    return new Response(audioBuffer, {
      headers: {
        'Content-Type': 'audio/mpeg',
        'Content-Length': audioBuffer.length.toString(),
      },
    })
  } catch (error) {
    console.error('Failed to convert text to speech:', error)
    return errorResponse('Failed to convert text to speech', 500)
  }
}

/**
 * POST /api/voice/stt - convert speech to text
 */
async function speechToText(request: Request, env: Env): Promise<Response> {
  const client = getClient(env)
  if (!client) {
    return serviceUnavailable()
  }

  try {
    const formData = await request.formData()
    const audioFile = formData.get('audio') as File | null

    if (!audioFile) {
      return errorResponse('audio file is required', 400)
    }

    const response = await client.speechToText.convert({
      file: audioFile,
      modelId: 'scribe_v2',
      timestampsGranularity: 'word',
      tagAudioEvents: true,
    })

    // Handle the response - the API returns a union type
    // Cast to any to handle the complex union type from ElevenLabs SDK
    const resp = response as {
      transcripts?: Array<{
        text: string
        words: Array<{ text: string; start?: number; end?: number; type: string; speakerId?: string; logprob: number }>
        languageCode: string
        languageProbability: number
      }>
      text?: string
      words?: Array<{ text: string; start?: number; end?: number; type: string; speakerId?: string; logprob: number }>
      languageCode?: string
      languageProbability?: number
    }

    if (resp.transcripts) {
      // Multi-channel response - take the first transcript
      const firstTranscript = resp.transcripts[0]
      return jsonResponse({
        text: firstTranscript.text,
        words: firstTranscript.words.map((word) => ({
          text: word.text,
          start: word.start,
          end: word.end,
          type: word.type,
          speakerId: word.speakerId,
          confidence: Math.exp(word.logprob),
        })),
        languageCode: firstTranscript.languageCode,
        languageConfidence: firstTranscript.languageProbability,
      })
    }

    // Single-channel response
    return jsonResponse({
      text: resp.text || '',
      words: (resp.words || []).map((word) => ({
        text: word.text,
        start: word.start,
        end: word.end,
        type: word.type,
        speakerId: word.speakerId,
        confidence: Math.exp(word.logprob),
      })),
      languageCode: resp.languageCode || '',
      languageConfidence: resp.languageProbability || 0,
    })
  } catch (error) {
    console.error('Failed to transcribe speech:', error)
    return errorResponse('Failed to transcribe speech', 500)
  }
}

/**
 * POST /api/voice/pronunciation-check - check pronunciation against expected word
 */
async function pronunciationCheck(request: Request, env: Env): Promise<Response> {
  const client = getClient(env)
  if (!client) {
    return serviceUnavailable()
  }

  try {
    const formData = await request.formData()
    const audioFile = formData.get('audio') as File | null
    const expectedWord = formData.get('expectedWord') as string | null

    if (!audioFile) {
      return errorResponse('audio file is required', 400)
    }

    if (!expectedWord) {
      return errorResponse('expectedWord is required', 400)
    }

    const response = await client.speechToText.convert({
      file: audioFile,
      modelId: 'scribe_v2',
      timestampsGranularity: 'word',
      tagAudioEvents: true,
    })

    // Handle the response - cast to typed structure
    const resp = response as {
      transcripts?: Array<{
        text: string
        words: Array<{ text: string; type: string; logprob: number }>
      }>
      text?: string
      words?: Array<{ text: string; type: string; logprob: number }>
    }

    const text = resp.transcripts
      ? resp.transcripts[0].text
      : (resp.text || '')

    const words = resp.transcripts
      ? resp.transcripts[0].words
      : (resp.words || [])

    // Normalize both for comparison
    const transcribedNormalized = text.toLowerCase().trim()
    const expectedNormalized = expectedWord.toLowerCase().trim()

    // Check for exact match or if transcription contains the expected word
    const isCorrect =
      transcribedNormalized === expectedNormalized ||
      transcribedNormalized.includes(expectedNormalized)

    // Calculate confidence based on word-level confidences
    const wordConfidences = words
      .filter((w: { type: string }) => w.type === 'word')
      .map((w: { logprob: number }) => Math.exp(w.logprob))
    const avgConfidence =
      wordConfidences.length > 0
        ? wordConfidences.reduce((a: number, b: number) => a + b, 0) / wordConfidences.length
        : 0

    // Feedback messages
    const positiveFeedback = [
      'Great job!',
      'Perfect!',
      'You said it!',
      'Excellent!',
      'Wonderful!',
      'Amazing!',
    ]
    const encouragingFeedback = [
      `Try again! Say "${expectedWord}"`,
      `Almost! Try saying "${expectedWord}" again`,
      `Good try! Can you say "${expectedWord}"?`,
      `Let's try "${expectedWord}" one more time!`,
    ]

    const feedback = isCorrect
      ? positiveFeedback[Math.floor(Math.random() * positiveFeedback.length)]
      : encouragingFeedback[Math.floor(Math.random() * encouragingFeedback.length)]

    return jsonResponse({
      isCorrect,
      transcribed: text,
      expected: expectedWord,
      confidence: avgConfidence,
      feedback,
    })
  } catch (error) {
    console.error('Failed to check pronunciation:', error)
    return errorResponse('Failed to check pronunciation', 500)
  }
}
