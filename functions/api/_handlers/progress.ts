/**
 * Progress handler for Cloudflare Functions
 * Handles /api/progress/* routes
 */

import type { Env } from '../../types'
import { jsonResponse, errorResponse } from '../[[path]]'
import { requireAuth } from './utils/auth'

interface ProgressRow {
  id: string
  child_id: string
  lesson_id: string
  status: string
  score: number | null
  time_spent: number
  started_at: string | null
  completed_at: string | null
  created_at: string
  updated_at: string
}

/**
 * Handle progress routes
 */
export async function handleProgress(
  request: Request,
  env: Env,
  pathSegments: string[]
): Promise<Response> {
  // All progress routes require auth
  const authResult = requireAuth(request, env)
  if ('error' in authResult) {
    return authResult.error
  }
  const userId = authResult.user.userId

  // Parse path: /api/progress/child/:childId/...
  if (pathSegments[0] !== 'child' || !pathSegments[1]) {
    return errorResponse('Invalid path', 400)
  }

  const childId = pathSegments[1]

  // Verify child ownership
  const child = await env.DB.prepare(
    'SELECT id FROM children WHERE id = ? AND user_id = ?'
  ).bind(childId, userId).first<{ id: string }>()

  if (!child) {
    return errorResponse('Child not found', 404)
  }

  // Route based on remaining path
  const remainingPath = pathSegments.slice(2)

  // GET /api/progress/child/:childId
  if (request.method === 'GET' && remainingPath.length === 0) {
    return await getChildProgress(env, childId)
  }

  // GET /api/progress/child/:childId/summary
  if (request.method === 'GET' && remainingPath[0] === 'summary') {
    return await getProgressSummary(env, childId)
  }

  // Routes with lessonId
  if (remainingPath[0] === 'lesson' && remainingPath[1]) {
    const lessonId = remainingPath[1]
    const action = remainingPath[2]

    // GET /api/progress/child/:childId/lesson/:lessonId
    if (request.method === 'GET' && !action) {
      return await getLessonProgress(env, childId, lessonId)
    }

    // POST /api/progress/child/:childId/lesson/:lessonId/start
    if (request.method === 'POST' && action === 'start') {
      return await startLesson(env, childId, lessonId)
    }

    // POST /api/progress/child/:childId/lesson/:lessonId/complete
    if (request.method === 'POST' && action === 'complete') {
      return await completeLesson(request, env, childId, lessonId)
    }

    // PUT /api/progress/child/:childId/lesson/:lessonId
    if (request.method === 'PUT' && !action) {
      return await updateProgress(request, env, childId, lessonId)
    }
  }

  return errorResponse('Method not allowed', 405)
}

/**
 * GET /api/progress/child/:childId - get all progress for a child
 */
async function getChildProgress(env: Env, childId: string): Promise<Response> {
  const result = await env.DB.prepare(`
    SELECT p.*, l.title as lesson_title, l.subject
    FROM progress p
    LEFT JOIN lessons l ON p.lesson_id = l.id
    WHERE p.child_id = ?
    ORDER BY p.updated_at DESC
  `).bind(childId).all<ProgressRow & { lesson_title?: string; subject?: string }>()

  return jsonResponse({ progress: result.results || [] })
}

/**
 * GET /api/progress/child/:childId/lesson/:lessonId - get progress for specific lesson
 */
async function getLessonProgress(
  env: Env,
  childId: string,
  lessonId: string
): Promise<Response> {
  const progress = await env.DB.prepare(
    'SELECT * FROM progress WHERE child_id = ? AND lesson_id = ?'
  ).bind(childId, lessonId).first<ProgressRow>()

  if (!progress) {
    return jsonResponse({
      progress: {
        childId,
        lessonId,
        status: 'not_started',
        score: null,
        timeSpent: 0,
      },
    })
  }

  return jsonResponse({ progress })
}

/**
 * POST /api/progress/child/:childId/lesson/:lessonId/start - start a lesson
 */
async function startLesson(
  env: Env,
  childId: string,
  lessonId: string
): Promise<Response> {
  const existing = await env.DB.prepare(
    'SELECT id FROM progress WHERE child_id = ? AND lesson_id = ?'
  ).bind(childId, lessonId).first<{ id: string }>()

  if (existing) {
    await env.DB.prepare(`
      UPDATE progress
      SET status = 'in_progress', started_at = COALESCE(started_at, datetime('now')), updated_at = datetime('now')
      WHERE id = ?
    `).bind(existing.id).run()
  } else {
    const id = crypto.randomUUID()
    await env.DB.prepare(`
      INSERT INTO progress (id, child_id, lesson_id, status, started_at)
      VALUES (?, ?, ?, 'in_progress', datetime('now'))
    `).bind(id, childId, lessonId).run()
  }

  const progress = await env.DB.prepare(
    'SELECT * FROM progress WHERE child_id = ? AND lesson_id = ?'
  ).bind(childId, lessonId).first<ProgressRow>()

  return jsonResponse({ progress })
}

/**
 * POST /api/progress/child/:childId/lesson/:lessonId/complete - complete a lesson
 */
async function completeLesson(
  request: Request,
  env: Env,
  childId: string,
  lessonId: string
): Promise<Response> {
  const body = await request.json() as { score?: number; timeSpent?: number }
  const { score, timeSpent } = body

  const existing = await env.DB.prepare(
    'SELECT id FROM progress WHERE child_id = ? AND lesson_id = ?'
  ).bind(childId, lessonId).first<{ id: string }>()

  if (existing) {
    await env.DB.prepare(`
      UPDATE progress
      SET status = 'completed',
          score = COALESCE(?, score),
          time_spent = COALESCE(?, time_spent),
          completed_at = datetime('now'),
          updated_at = datetime('now')
      WHERE id = ?
    `).bind(score ?? null, timeSpent ?? null, existing.id).run()
  } else {
    const id = crypto.randomUUID()
    await env.DB.prepare(`
      INSERT INTO progress (id, child_id, lesson_id, status, score, time_spent, started_at, completed_at)
      VALUES (?, ?, ?, 'completed', ?, ?, datetime('now'), datetime('now'))
    `).bind(id, childId, lessonId, score ?? null, timeSpent ?? 0).run()
  }

  const progress = await env.DB.prepare(
    'SELECT * FROM progress WHERE child_id = ? AND lesson_id = ?'
  ).bind(childId, lessonId).first<ProgressRow>()

  return jsonResponse({ progress })
}

/**
 * PUT /api/progress/child/:childId/lesson/:lessonId - update progress
 */
async function updateProgress(
  request: Request,
  env: Env,
  childId: string,
  lessonId: string
): Promise<Response> {
  const body = await request.json() as {
    status?: string
    score?: number
    timeSpent?: number
  }
  const { status, score, timeSpent } = body

  const existing = await env.DB.prepare(
    'SELECT id FROM progress WHERE child_id = ? AND lesson_id = ?'
  ).bind(childId, lessonId).first<{ id: string }>()

  if (!existing) {
    return errorResponse('Progress record not found', 404)
  }

  const updates: string[] = []
  const values: (string | number | null)[] = []

  if (status !== undefined) {
    updates.push('status = ?')
    values.push(status)
  }
  if (score !== undefined) {
    updates.push('score = ?')
    values.push(score)
  }
  if (timeSpent !== undefined) {
    updates.push('time_spent = ?')
    values.push(timeSpent)
  }

  if (updates.length > 0) {
    updates.push("updated_at = datetime('now')")
    const sql = `UPDATE progress SET ${updates.join(', ')} WHERE id = ?`

    let stmt = env.DB.prepare(sql)
    for (const val of [...values, existing.id]) {
      stmt = stmt.bind(val)
    }
    await stmt.run()
  }

  const progress = await env.DB.prepare(
    'SELECT * FROM progress WHERE id = ?'
  ).bind(existing.id).first<ProgressRow>()

  return jsonResponse({ progress })
}

/**
 * GET /api/progress/child/:childId/summary - get progress summary
 */
async function getProgressSummary(env: Env, childId: string): Promise<Response> {
  const stats = await env.DB.prepare(`
    SELECT
      COUNT(*) as total_lessons,
      SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed_lessons,
      SUM(CASE WHEN status = 'in_progress' THEN 1 ELSE 0 END) as in_progress_lessons,
      AVG(CASE WHEN score IS NOT NULL THEN score END) as average_score,
      SUM(time_spent) as total_time_spent
    FROM progress WHERE child_id = ?
  `).bind(childId).first<{
    total_lessons: number
    completed_lessons: number
    in_progress_lessons: number
    average_score: number | null
    total_time_spent: number
  }>()

  return jsonResponse({ summary: stats })
}
