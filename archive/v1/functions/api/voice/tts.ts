// Text-to-Speech API endpoint
// POST /api/voice/tts - Convert text to speech
// Uses ElevenLabs SDK for better API handling and compatibility

import { ElevenLabsClient } from '@elevenlabs/elevenlabs-js'

interface TTSRequest {
  text: string
  voiceId?: string
  stability?: number
  similarityBoost?: number
  speed?: number
  // Also accept nested voiceSettings from frontend
  voiceSettings?: {
    stability?: number
    similarityBoost?: number
    style?: number
    useSpeakerBoost?: boolean
  }
}

interface Env {
  ELEVENLABS_API_KEY?: string
}

// Default voice ID (Rachel - clear, warm voice)
const DEFAULT_ELEVENLABS_VOICE = 'EXAVITQu4vr4xnSDxMaL'

/**
 * Convert a ReadableStream to ArrayBuffer
 */
async function streamToArrayBuffer(stream: ReadableStream<Uint8Array>): Promise<ArrayBuffer> {
  const reader = stream.getReader()
  const chunks: Uint8Array[] = []

  while (true) {
    const { done, value } = await reader.read()
    if (done) break
    if (value) chunks.push(value)
  }

  // Calculate total length
  const totalLength = chunks.reduce((sum, chunk) => sum + chunk.length, 0)
  const result = new Uint8Array(totalLength)

  // Copy chunks into result
  let offset = 0
  for (const chunk of chunks) {
    result.set(chunk, offset)
    offset += chunk.length
  }

  return result.buffer
}

export const onRequestPost: PagesFunction<Env> = async (context) => {
  const apiKey = context.env.ELEVENLABS_API_KEY

  if (!apiKey) {
    return Response.json(
      { error: 'TTS service not configured. Using browser speech synthesis.' },
      { status: 503 }
    )
  }

  try {
    const body = await context.request.json() as TTSRequest
    const { text, voiceId = 'default', voiceSettings } = body

    // Support both flat and nested parameters
    const stability = voiceSettings?.stability ?? body.stability ?? 0.5
    const similarityBoost = voiceSettings?.similarityBoost ?? body.similarityBoost ?? 0.75
    const style = voiceSettings?.style ?? 0
    const useSpeakerBoost = voiceSettings?.useSpeakerBoost ?? true

    console.log('TTS request:', { voiceId, textLength: text?.length, stability, similarityBoost })

    if (!text || typeof text !== 'string') {
      return Response.json({ error: 'Text is required' }, { status: 400 })
    }

    // If using default voice, tell frontend to use browser TTS
    if (voiceId === 'default') {
      return Response.json(
        { error: 'Using browser speech synthesis for default voice.' },
        { status: 503 }
      )
    }

    // Use the ElevenLabs SDK for better API handling
    const client = new ElevenLabsClient({ apiKey })
    const effectiveVoiceId = voiceId === 'default' ? DEFAULT_ELEVENLABS_VOICE : voiceId

    console.log('Calling ElevenLabs SDK with voiceId:', effectiveVoiceId)

    const audioStream = await client.textToSpeech.convert(effectiveVoiceId, {
      text,
      modelId: 'eleven_flash_v2_5',
      outputFormat: 'mp3_44100_128',
      voiceSettings: {
        stability,
        similarityBoost,
        style,
        useSpeakerBoost,
      },
    })

    // Convert stream to ArrayBuffer
    const audioBuffer = await streamToArrayBuffer(audioStream)

    return new Response(audioBuffer, {
      headers: {
        'Content-Type': 'audio/mpeg',
        'Cache-Control': 'public, max-age=3600',
      },
    })
  } catch (error) {
    console.error('TTS error:', error)

    // Parse ElevenLabs error for better messaging
    let userMessage = 'Voice service temporarily unavailable.'
    const errorMessage = error instanceof Error ? error.message : String(error)

    if (errorMessage.includes('detected_unusual_activity')) {
      userMessage = 'ElevenLabs rate limited. Please try again later or use browser voice.'
    } else if (errorMessage.includes('model_deprecated_free_tier')) {
      userMessage = 'Voice model not available on free tier.'
    } else if (errorMessage.includes('quota')) {
      userMessage = 'Voice quota exceeded. Please try again later.'
    }

    return Response.json(
      { error: userMessage, details: errorMessage.substring(0, 200) },
      { status: 503 }
    )
  }
}
