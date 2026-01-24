// Available voices API endpoint
// GET /api/voice/voices - Get list of available voices

// ElevenLabs API response format
interface ElevenLabsVoice {
  voice_id: string
  name: string
  category?: string
  description?: string
  preview_url?: string
  labels?: Record<string, string>
}

// Frontend format (camelCase)
interface Voice {
  voiceId: string
  name: string
  category: string
  description?: string
  previewUrl?: string
  labels?: Record<string, string>
}

interface Env {
  ELEVENLABS_API_KEY?: string
}

// Default voice when ElevenLabs not configured
const DEFAULT_VOICE: Voice = {
  voiceId: 'default',
  name: 'Browser Voice',
  category: 'default',
  description: 'Uses your browser\'s built-in text-to-speech'
}

export const onRequestGet: PagesFunction<Env> = async (context) => {
  const apiKey = context.env.ELEVENLABS_API_KEY

  if (!apiKey) {
    // Return default browser voice option
    return Response.json({ voices: [DEFAULT_VOICE] })
  }

  try {
    const response = await fetch('https://api.elevenlabs.io/v1/voices', {
      headers: {
        'xi-api-key': apiKey,
      },
    })

    if (!response.ok) {
      console.error('ElevenLabs API error:', response.status)
      return Response.json({ voices: [DEFAULT_VOICE] })
    }

    const data = await response.json() as { voices: ElevenLabsVoice[] }

    // Convert to frontend format with camelCase and include preview URLs
    const voices: Voice[] = [
      DEFAULT_VOICE,
      ...data.voices.map(v => ({
        voiceId: v.voice_id,
        name: v.name,
        category: v.category || 'premade',
        description: v.description,
        previewUrl: v.preview_url,
        labels: v.labels
      }))
    ]

    return Response.json({ voices })
  } catch (error) {
    console.error('Error fetching voices:', error)
    return Response.json({ voices: [DEFAULT_VOICE] })
  }
}
