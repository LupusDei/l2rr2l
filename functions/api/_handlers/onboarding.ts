/**
 * Onboarding handler for Cloudflare Functions
 * Handles /api/onboarding/* routes
 */

import type { Env } from '../../types'
import { jsonResponse, errorResponse } from '../[[path]]'
import { requireAuth } from './utils/auth'

interface OnboardingRow {
  id: string
  user_id: string
  completed: number
  step: number
  data: string | null
  created_at: string
  updated_at: string
}

/**
 * Handle onboarding routes
 */
export async function handleOnboarding(
  request: Request,
  env: Env,
  pathSegments: string[]
): Promise<Response> {
  // All onboarding routes require auth
  const authResult = requireAuth(request, env)
  if ('error' in authResult) {
    return authResult.error
  }
  const userId = authResult.user.userId

  const action = pathSegments[0] || ''

  // GET /api/onboarding
  if (request.method === 'GET' && !action) {
    return await getOnboarding(env, userId)
  }

  // PUT /api/onboarding
  if (request.method === 'PUT' && !action) {
    return await updateOnboarding(request, env, userId)
  }

  // POST /api/onboarding/complete
  if (request.method === 'POST' && action === 'complete') {
    return await completeOnboarding(env, userId)
  }

  return errorResponse('Method not allowed', 405)
}

/**
 * GET /api/onboarding - get onboarding state
 */
async function getOnboarding(env: Env, userId: string): Promise<Response> {
  const onboarding = await env.DB.prepare(
    'SELECT * FROM onboarding WHERE user_id = ?'
  ).bind(userId).first<OnboardingRow>()

  if (!onboarding) {
    return jsonResponse({
      onboarding: {
        completed: false,
        step: 0,
        data: {},
      },
    })
  }

  return jsonResponse({
    onboarding: {
      id: onboarding.id,
      completed: Boolean(onboarding.completed),
      step: onboarding.step,
      data: onboarding.data ? JSON.parse(onboarding.data) : {},
    },
  })
}

/**
 * PUT /api/onboarding - update onboarding state
 */
async function updateOnboarding(
  request: Request,
  env: Env,
  userId: string
): Promise<Response> {
  const body = await request.json() as {
    step?: number
    data?: Record<string, unknown>
    completed?: boolean
  }

  const { step, data, completed } = body

  const existing = await env.DB.prepare(
    'SELECT * FROM onboarding WHERE user_id = ?'
  ).bind(userId).first<OnboardingRow>()

  if (!existing) {
    const id = crypto.randomUUID()
    await env.DB.prepare(`
      INSERT INTO onboarding (id, user_id, step, data, completed)
      VALUES (?, ?, ?, ?, ?)
    `).bind(
      id,
      userId,
      step ?? 0,
      data ? JSON.stringify(data) : null,
      completed ? 1 : 0
    ).run()

    const onboarding = await env.DB.prepare(
      'SELECT * FROM onboarding WHERE id = ?'
    ).bind(id).first<OnboardingRow>()

    return jsonResponse({
      onboarding: {
        id: onboarding!.id,
        completed: Boolean(onboarding!.completed),
        step: onboarding!.step,
        data: onboarding!.data ? JSON.parse(onboarding!.data) : {},
      },
    })
  }

  const updates: string[] = []
  const values: (string | number)[] = []

  if (step !== undefined) {
    updates.push('step = ?')
    values.push(step)
  }
  if (data !== undefined) {
    const existingData = existing.data ? JSON.parse(existing.data) : {}
    const mergedData = { ...existingData, ...data }
    updates.push('data = ?')
    values.push(JSON.stringify(mergedData))
  }
  if (completed !== undefined) {
    updates.push('completed = ?')
    values.push(completed ? 1 : 0)
  }

  if (updates.length > 0) {
    updates.push("updated_at = datetime('now')")
    const sql = `UPDATE onboarding SET ${updates.join(', ')} WHERE user_id = ?`

    let stmt = env.DB.prepare(sql)
    for (const val of [...values, userId]) {
      stmt = stmt.bind(val)
    }
    await stmt.run()
  }

  const onboarding = await env.DB.prepare(
    'SELECT * FROM onboarding WHERE user_id = ?'
  ).bind(userId).first<OnboardingRow>()

  return jsonResponse({
    onboarding: {
      id: onboarding!.id,
      completed: Boolean(onboarding!.completed),
      step: onboarding!.step,
      data: onboarding!.data ? JSON.parse(onboarding!.data) : {},
    },
  })
}

/**
 * POST /api/onboarding/complete - mark onboarding as complete
 */
async function completeOnboarding(env: Env, userId: string): Promise<Response> {
  const existing = await env.DB.prepare(
    'SELECT id FROM onboarding WHERE user_id = ?'
  ).bind(userId).first<{ id: string }>()

  if (!existing) {
    const id = crypto.randomUUID()
    await env.DB.prepare(`
      INSERT INTO onboarding (id, user_id, completed, step)
      VALUES (?, ?, 1, -1)
    `).bind(id, userId).run()
  } else {
    await env.DB.prepare(`
      UPDATE onboarding SET completed = 1, updated_at = datetime('now')
      WHERE user_id = ?
    `).bind(userId).run()
  }

  return jsonResponse({ completed: true })
}
