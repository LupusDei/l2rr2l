// Available voices API endpoint
// GET /api/voice/voices - Get list of available voices

interface Voice {
  voice_id: string
  name: string
  category: string
  description?: string
}

interface Env {
  ELEVENLABS_API_KEY?: string
}

// Default voices to return if ElevenLabs API is not configured
const DEFAULT_VOICES: Voice[] = [
  {
    voice_id: 'default',
    name: 'Browser Voice',
    category: 'default',
    description: 'Uses your browser\'s built-in text-to-speech'
  }
]

export const onRequestGet: PagesFunction<Env> = async (context) => {
  const apiKey = context.env.ELEVENLABS_API_KEY

  if (!apiKey) {
    // Return default browser voice option
    return Response.json({ voices: DEFAULT_VOICES })
  }

  try {
    const response = await fetch('https://api.elevenlabs.io/v1/voices', {
      headers: {
        'xi-api-key': apiKey,
      },
    })

    if (!response.ok) {
      console.error('ElevenLabs API error:', response.status)
      return Response.json({ voices: DEFAULT_VOICES })
    }

    const data = await response.json() as { voices: Voice[] }

    // Add browser default as first option
    const voices = [
      DEFAULT_VOICES[0],
      ...data.voices.map(v => ({
        voice_id: v.voice_id,
        name: v.name,
        category: v.category || 'custom',
        description: v.description
      }))
    ]

    return Response.json({ voices })
  } catch (error) {
    console.error('Error fetching voices:', error)
    return Response.json({ voices: DEFAULT_VOICES })
  }
}
