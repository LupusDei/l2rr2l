/**
 * Voice settings handler for Cloudflare Functions
 * Handles /api/voice/settings/* routes
 */

import type { Env } from '../../types'
import { jsonResponse, errorResponse } from '../[[path]]'

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

// Default voice settings
const DEFAULT_SETTINGS = {
  voiceId: 'pMsXgVXv3BLzUgSXRplE',
  stability: 0.5,
  similarityBoost: 0.75,
  style: 0,
  speed: 1.0,
  useSpeakerBoost: true,
}

/**
 * Handle voice settings routes
 */
export async function handleVoiceSettings(
  request: Request,
  env: Env,
  pathSegments: string[]
): Promise<Response> {
  const childId = pathSegments[0]

  if (!childId) {
    return errorResponse('Child ID is required', 400)
  }

  // GET /api/voice/settings/:childId
  if (request.method === 'GET') {
    return await getVoiceSettings(env, childId)
  }

  // PUT /api/voice/settings/:childId
  if (request.method === 'PUT') {
    return await saveVoiceSettings(request, env, childId)
  }

  return errorResponse('Method not allowed', 405)
}

/**
 * GET /api/voice/settings/:childId
 * Get voice settings for a child (or defaults if not set)
 */
async function getVoiceSettings(env: Env, childId: string): Promise<Response> {
  const row = await env.DB.prepare(
    'SELECT * FROM voice_settings WHERE child_id = ?'
  ).bind(childId).first<VoiceSettingsRow>()

  if (row) {
    return jsonResponse({
      voiceId: row.voice_id,
      stability: row.stability,
      similarityBoost: row.similarity_boost,
      style: row.style,
      speed: row.speed,
      useSpeakerBoost: row.use_speaker_boost === 1,
    })
  }

  // Return default settings
  return jsonResponse(DEFAULT_SETTINGS)
}

/**
 * PUT /api/voice/settings/:childId
 * Save voice settings for a child
 */
async function saveVoiceSettings(
  request: Request,
  env: Env,
  childId: string
): Promise<Response> {
  const body = await request.json() as {
    voiceId?: string
    stability?: number
    similarityBoost?: number
    style?: number
    speed?: number
    useSpeakerBoost?: boolean
  }

  const { voiceId, stability, similarityBoost, style, speed, useSpeakerBoost } = body

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
    return jsonResponse({ error: 'Invalid voice settings', validationErrors: errors }, 400)
  }

  // Check if settings exist for this child
  const existing = await env.DB.prepare(
    'SELECT id FROM voice_settings WHERE child_id = ?'
  ).bind(childId).first<{ id: string }>()

  if (existing) {
    // Update existing settings
    await env.DB.prepare(`
      UPDATE voice_settings SET
        voice_id = COALESCE(?, voice_id),
        stability = COALESCE(?, stability),
        similarity_boost = COALESCE(?, similarity_boost),
        style = COALESCE(?, style),
        speed = COALESCE(?, speed),
        use_speaker_boost = COALESCE(?, use_speaker_boost),
        updated_at = datetime('now')
      WHERE child_id = ?
    `).bind(
      voiceId ?? null,
      stability ?? null,
      similarityBoost ?? null,
      style ?? null,
      speed ?? null,
      useSpeakerBoost !== undefined ? (useSpeakerBoost ? 1 : 0) : null,
      childId
    ).run()
  } else {
    // Insert new settings
    await env.DB.prepare(`
      INSERT INTO voice_settings (id, child_id, voice_id, stability, similarity_boost, style, speed, use_speaker_boost)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `).bind(
      crypto.randomUUID(),
      childId,
      voiceId ?? DEFAULT_SETTINGS.voiceId,
      stability ?? DEFAULT_SETTINGS.stability,
      similarityBoost ?? DEFAULT_SETTINGS.similarityBoost,
      style ?? DEFAULT_SETTINGS.style,
      speed ?? DEFAULT_SETTINGS.speed,
      useSpeakerBoost !== undefined ? (useSpeakerBoost ? 1 : 0) : 1
    ).run()
  }

  // Return the updated settings
  const row = await env.DB.prepare(
    'SELECT * FROM voice_settings WHERE child_id = ?'
  ).bind(childId).first<VoiceSettingsRow>()

  return jsonResponse({
    voiceId: row!.voice_id,
    stability: row!.stability,
    similarityBoost: row!.similarity_boost,
    style: row!.style,
    speed: row!.speed,
    useSpeakerBoost: row!.use_speaker_boost === 1,
  })
}
