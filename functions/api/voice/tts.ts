// Text-to-Speech API endpoint
// POST /api/voice/tts - Convert text to speech

interface TTSRequest {
  text: string
  voiceId?: string
  stability?: number
  similarityBoost?: number
  speed?: number
}

interface Env {
  ELEVENLABS_API_KEY?: string
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
    const { text, voiceId = 'default', stability = 0.5, similarityBoost = 0.75, speed = 1.0 } = body

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

    const response = await fetch(
      `https://api.elevenlabs.io/v1/text-to-speech/${voiceId}`,
      {
        method: 'POST',
        headers: {
          'xi-api-key': apiKey,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          text,
          model_id: 'eleven_monolingual_v1',
          voice_settings: {
            stability,
            similarity_boost: similarityBoost,
            speed,
          },
        }),
      }
    )

    if (!response.ok) {
      const errorText = await response.text()
      console.error('ElevenLabs TTS error:', response.status, errorText)
      return Response.json(
        { error: 'TTS service error. Using browser speech synthesis.' },
        { status: 503 }
      )
    }

    // Return audio as binary
    const audioBuffer = await response.arrayBuffer()
    return new Response(audioBuffer, {
      headers: {
        'Content-Type': 'audio/mpeg',
        'Cache-Control': 'public, max-age=3600',
      },
    })
  } catch (error) {
    console.error('TTS error:', error)
    return Response.json(
      { error: 'TTS service unavailable. Using browser speech synthesis.' },
      { status: 503 }
    )
  }
}
