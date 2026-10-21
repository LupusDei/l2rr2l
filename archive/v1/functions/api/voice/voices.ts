// Available voices API endpoint
// GET /api/voice/voices - Get list of available voices
// Uses ElevenLabs SDK for better API handling

import { ElevenLabsClient } from '@elevenlabs/elevenlabs-js'

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
    const client = new ElevenLabsClient({ apiKey })
    const response = await client.voices.getAll()

    // Convert to frontend format with camelCase and include preview URLs
    const voices: Voice[] = [
      DEFAULT_VOICE,
      ...response.voices.map(v => ({
        voiceId: v.voiceId,
        name: v.name ?? 'Unknown',
        category: v.category || 'premade',
        description: v.description ?? undefined,
        previewUrl: v.previewUrl ?? undefined,
        labels: v.labels as Record<string, string> | undefined,
      }))
    ]

    return Response.json({ voices })
  } catch (error) {
    console.error('Error fetching voices:', error)
    return Response.json({ voices: [DEFAULT_VOICE] })
  }
}
