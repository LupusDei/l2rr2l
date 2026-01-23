/**
 * Children handler for Cloudflare Functions
 * Handles /api/children/* routes
 */

import type { Env } from '../../types'
import { jsonResponse, errorResponse } from '../[[path]]'
import { requireAuth } from './utils/auth'

interface ChildRow {
  id: string
  user_id: string
  name: string
  age: number | null
  sex: string | null
  avatar: string | null
  grade_level: string | null
  learning_style: string | null
  interests: string | null
  created_at: string
  updated_at: string
}

/**
 * Parse a child row, converting JSON fields
 */
function parseChild(row: ChildRow) {
  return {
    ...row,
    interests: row.interests ? JSON.parse(row.interests) : [],
  }
}

/**
 * Handle children routes
 */
export async function handleChildren(
  request: Request,
  env: Env,
  pathSegments: string[]
): Promise<Response> {
  // All children routes require auth
  const authResult = requireAuth(request, env)
  if ('error' in authResult) {
    return authResult.error
  }
  const userId = authResult.user.userId

  const childId = pathSegments[0] || ''

  // GET /api/children - list children
  if (request.method === 'GET' && !childId) {
    return await listChildren(env, userId)
  }

  // POST /api/children - create child
  if (request.method === 'POST' && !childId) {
    return await createChild(request, env, userId)
  }

  // GET /api/children/:id - get child
  if (request.method === 'GET' && childId) {
    return await getChild(env, userId, childId)
  }

  // PUT /api/children/:id - update child
  if (request.method === 'PUT' && childId) {
    return await updateChild(request, env, userId, childId)
  }

  // DELETE /api/children/:id - delete child
  if (request.method === 'DELETE' && childId) {
    return await deleteChild(env, userId, childId)
  }

  return errorResponse('Method not allowed', 405)
}

/**
 * GET /api/children - list all children for user
 */
async function listChildren(env: Env, userId: string): Promise<Response> {
  const result = await env.DB.prepare(
    'SELECT * FROM children WHERE user_id = ?'
  ).bind(userId).all<ChildRow>()

  const children = (result.results || []).map(parseChild)
  return jsonResponse({ children })
}

/**
 * POST /api/children - create a new child
 */
async function createChild(
  request: Request,
  env: Env,
  userId: string
): Promise<Response> {
  const body = await request.json() as {
    name?: string
    age?: number
    sex?: string
    avatar?: string
    gradeLevel?: string
    learningStyle?: string
    interests?: string[]
  }

  const { name, age, sex, avatar, gradeLevel, learningStyle, interests } = body

  if (!name) {
    return errorResponse('Name is required', 400)
  }

  const id = crypto.randomUUID()
  const interestsJson = interests ? JSON.stringify(interests) : null

  await env.DB.prepare(`
    INSERT INTO children (id, user_id, name, age, sex, avatar, grade_level, learning_style, interests)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
  `).bind(
    id,
    userId,
    name,
    age || null,
    sex || null,
    avatar || null,
    gradeLevel || null,
    learningStyle || null,
    interestsJson
  ).run()

  const child = await env.DB.prepare(
    'SELECT * FROM children WHERE id = ?'
  ).bind(id).first<ChildRow>()

  return jsonResponse({ child: parseChild(child!) }, 201)
}

/**
 * GET /api/children/:id - get a specific child
 */
async function getChild(
  env: Env,
  userId: string,
  childId: string
): Promise<Response> {
  const child = await env.DB.prepare(
    'SELECT * FROM children WHERE id = ? AND user_id = ?'
  ).bind(childId, userId).first<ChildRow>()

  if (!child) {
    return errorResponse('Child not found', 404)
  }

  return jsonResponse({ child: parseChild(child) })
}

/**
 * PUT /api/children/:id - update a child
 */
async function updateChild(
  request: Request,
  env: Env,
  userId: string,
  childId: string
): Promise<Response> {
  // Verify child exists and belongs to user
  const existing = await env.DB.prepare(
    'SELECT id FROM children WHERE id = ? AND user_id = ?'
  ).bind(childId, userId).first<{ id: string }>()

  if (!existing) {
    return errorResponse('Child not found', 404)
  }

  const body = await request.json() as {
    name?: string
    age?: number
    sex?: string
    avatar?: string
    gradeLevel?: string
    learningStyle?: string
    interests?: string[]
  }

  const { name, age, sex, avatar, gradeLevel, learningStyle, interests } = body

  const updates: string[] = []
  const values: (string | number | null)[] = []

  if (name !== undefined) {
    updates.push('name = ?')
    values.push(name)
  }
  if (age !== undefined) {
    updates.push('age = ?')
    values.push(age)
  }
  if (sex !== undefined) {
    updates.push('sex = ?')
    values.push(sex)
  }
  if (avatar !== undefined) {
    updates.push('avatar = ?')
    values.push(avatar)
  }
  if (gradeLevel !== undefined) {
    updates.push('grade_level = ?')
    values.push(gradeLevel)
  }
  if (learningStyle !== undefined) {
    updates.push('learning_style = ?')
    values.push(learningStyle)
  }
  if (interests !== undefined) {
    updates.push('interests = ?')
    values.push(JSON.stringify(interests))
  }

  if (updates.length > 0) {
    updates.push("updated_at = datetime('now')")
    const sql = `UPDATE children SET ${updates.join(', ')} WHERE id = ?`

    // D1 requires explicit binding for each parameter
    let stmt = env.DB.prepare(sql)
    for (const val of [...values, childId]) {
      stmt = stmt.bind(val)
    }
    await stmt.run()
  }

  const child = await env.DB.prepare(
    'SELECT * FROM children WHERE id = ?'
  ).bind(childId).first<ChildRow>()

  return jsonResponse({ child: parseChild(child!) })
}

/**
 * DELETE /api/children/:id - delete a child
 */
async function deleteChild(
  env: Env,
  userId: string,
  childId: string
): Promise<Response> {
  const result = await env.DB.prepare(
    'DELETE FROM children WHERE id = ? AND user_id = ?'
  ).bind(childId, userId).run()

  if (result.meta?.changes === 0) {
    return errorResponse('Child not found', 404)
  }

  return new Response(null, { status: 204 })
}
