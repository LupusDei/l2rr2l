// Voice settings API endpoint
// GET /api/voice/settings/:childId - Get voice settings for a child
// PUT /api/voice/settings/:childId - Update voice settings for a child

interface VoiceSettings {
  enabled: boolean
  voiceId: string
  stability: number
  similarityBoost: number
  speed: number
  encouragementEnabled: boolean
}

interface Env {
  l2rr2l: D1Database
}

const DEFAULT_SETTINGS: VoiceSettings = {
  enabled: true,
  voiceId: 'default',
  stability: 0.5,
  similarityBoost: 0.75,
  speed: 1.0,
  encouragementEnabled: true,
}

export const onRequestGet: PagesFunction<Env> = async (context) => {
  const childId = context.params.childId as string

  try {
    // Try to get from D1 if available
    if (context.env.l2rr2l) {
      const result = await context.env.l2rr2l
        .prepare('SELECT settings FROM voice_settings WHERE child_id = ?')
        .bind(childId)
        .first<{ settings: string }>()

      if (result) {
        return Response.json(JSON.parse(result.settings))
      }
    }
  } catch {
    // D1 not available or table doesn't exist, use defaults
    console.log('D1 not available, using default settings')
  }

  // Return default settings
  return Response.json(DEFAULT_SETTINGS)
}

export const onRequestPut: PagesFunction<Env> = async (context) => {
  const childId = context.params.childId as string

  try {
    const settings = await context.request.json() as VoiceSettings

    // Validate settings
    if (typeof settings.enabled !== 'boolean') {
      return Response.json({ error: 'Invalid enabled value' }, { status: 400 })
    }

    // Try to save to D1 if available
    if (context.env.l2rr2l) {
      try {
        await context.env.l2rr2l
          .prepare(`
            INSERT INTO voice_settings (child_id, settings, updated_at)
            VALUES (?, ?, datetime('now'))
            ON CONFLICT(child_id) DO UPDATE SET
              settings = excluded.settings,
              updated_at = excluded.updated_at
          `)
          .bind(childId, JSON.stringify(settings))
          .run()
      } catch {
        // Table might not exist, that's okay for now
        console.log('Could not save to D1, settings will not persist')
      }
    }

    return Response.json({ success: true, settings })
  } catch (error) {
    console.error('Error saving settings:', error)
    return Response.json(
      { error: 'Failed to save settings' },
      { status: 500 }
    )
  }
}
