/**
 * Lessons handler for Cloudflare Functions
 * Handles /api/lessons/* routes
 *
 * Note: This is a simplified version that does not include:
 * - Full-text search (D1 doesn't support FTS5 virtual tables)
 * - AI generation (requires separate worker or external service)
 * - Advanced lesson matching (requires more complex queries)
 */

import type { Env } from '../../types'
import { jsonResponse, errorResponse } from '../[[path]]'
import { requireAuth } from './utils/auth'

interface LessonRow {
  id: string
  title: string
  subject: string
  description: string | null
  grade_level: string | null
  difficulty: string | null
  duration_minutes: number | null
  age_min: number | null
  age_max: number | null
  learning_styles: string | null
  interests: string | null
  objectives: string | null
  activities: string | null
  materials: string | null
  assessment_criteria: string | null
  source: string
  tags: string | null
  is_published: number
  created_at: string
  updated_at: string
}

type LessonDifficulty = 'beginner' | 'easy' | 'medium' | 'hard' | 'advanced'
type LessonSource = 'ai_generated' | 'curated'
type LearningStyle = 'visual' | 'auditory' | 'kinesthetic'

/**
 * Parse a lesson row, converting JSON fields
 */
function parseLesson(row: LessonRow) {
  return {
    id: row.id,
    title: row.title,
    subject: row.subject,
    description: row.description,
    gradeLevel: row.grade_level,
    difficulty: row.difficulty,
    durationMinutes: row.duration_minutes,
    ageMin: row.age_min,
    ageMax: row.age_max,
    learningStyles: row.learning_styles ? JSON.parse(row.learning_styles) : null,
    interests: row.interests ? JSON.parse(row.interests) : null,
    objectives: row.objectives ? JSON.parse(row.objectives) : null,
    activities: row.activities ? JSON.parse(row.activities) : null,
    materials: row.materials ? JSON.parse(row.materials) : null,
    assessmentCriteria: row.assessment_criteria ? JSON.parse(row.assessment_criteria) : null,
    source: row.source,
    tags: row.tags ? JSON.parse(row.tags) : null,
    isPublished: row.is_published === 1,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  }
}

/**
 * Handle lessons routes
 */
export async function handleLessons(
  request: Request,
  env: Env,
  pathSegments: string[]
): Promise<Response> {
  const action = pathSegments[0] || ''

  // Routes that don't require specific actions
  if (!action) {
    // GET /api/lessons
    if (request.method === 'GET') {
      return await listLessons(request, env)
    }
    // POST /api/lessons
    if (request.method === 'POST') {
      return await createLesson(request, env)
    }
  }

  // GET /api/lessons/subjects
  if (action === 'subjects' && request.method === 'GET') {
    return await getSubjects(env)
  }

  // GET /api/lessons/filters
  if (action === 'filters' && request.method === 'GET') {
    return await getFilters(env)
  }

  // GET /api/lessons/search
  if (action === 'search' && request.method === 'GET') {
    return await searchLessons(request, env)
  }

  // Routes with lessonId
  if (action && action !== 'subjects' && action !== 'filters' && action !== 'search' && action !== 'match') {
    const lessonId = action
    const subAction = pathSegments[1]

    // GET /api/lessons/:id
    if (request.method === 'GET' && !subAction) {
      return await getLesson(env, lessonId)
    }

    // PUT /api/lessons/:id
    if (request.method === 'PUT' && !subAction) {
      return await updateLesson(request, env, lessonId)
    }

    // DELETE /api/lessons/:id
    if (request.method === 'DELETE' && !subAction) {
      return await deleteLesson(env, lessonId)
    }

    // GET /api/lessons/:id/recommendations
    if (request.method === 'GET' && subAction === 'recommendations') {
      return await getRecommendations(request, env, lessonId)
    }

    // POST /api/lessons/:id/rate
    if (request.method === 'POST' && subAction === 'rate') {
      return await rateLesson(request, env, lessonId)
    }

    // POST /api/lessons/:id/engagement
    if (request.method === 'POST' && subAction === 'engagement') {
      return await trackEngagement(request, env, lessonId)
    }
  }

  return errorResponse('Method not allowed', 405)
}

/**
 * GET /api/lessons - list lessons with filters
 */
async function listLessons(request: Request, env: Env): Promise<Response> {
  const url = new URL(request.url)
  const subject = url.searchParams.get('subject')
  const gradeLevel = url.searchParams.get('gradeLevel')
  const difficulty = url.searchParams.get('difficulty')
  const source = url.searchParams.get('source')
  const limit = parseInt(url.searchParams.get('limit') || '20', 10)
  const offset = parseInt(url.searchParams.get('offset') || '0', 10)

  let sql = `
    SELECT l.*,
      COALESCE(AVG(r.rating), 0) as avg_rating,
      COUNT(DISTINCT r.id) as rating_count,
      COALESCE(SUM(e.completion_count), 0) as total_completions
    FROM lessons l
    LEFT JOIN lesson_ratings r ON l.id = r.lesson_id
    LEFT JOIN lesson_engagement e ON l.id = e.lesson_id
    WHERE l.is_published = 1
  `
  const params: (string | number)[] = []

  if (subject) {
    sql += ' AND l.subject = ?'
    params.push(subject)
  }
  if (gradeLevel) {
    sql += ' AND l.grade_level = ?'
    params.push(gradeLevel)
  }
  if (difficulty) {
    sql += ' AND l.difficulty = ?'
    params.push(difficulty)
  }
  if (source) {
    sql += ' AND l.source = ?'
    params.push(source)
  }

  sql += ' GROUP BY l.id ORDER BY l.created_at DESC LIMIT ? OFFSET ?'
  params.push(limit, offset)

  let stmt = env.DB.prepare(sql)
  for (const param of params) {
    stmt = stmt.bind(param)
  }

  const result = await stmt.all<LessonRow & {
    avg_rating: number
    rating_count: number
    total_completions: number
  }>()

  const lessons = (result.results || []).map((l) => ({
    ...parseLesson(l),
    avg_rating: l.avg_rating || null,
    rating_count: l.rating_count,
    total_completions: l.total_completions,
  }))

  // Get total count
  let countSql = 'SELECT COUNT(*) as count FROM lessons WHERE is_published = 1'
  const countParams: (string | number)[] = []
  if (subject) {
    countSql += ' AND subject = ?'
    countParams.push(subject)
  }
  if (gradeLevel) {
    countSql += ' AND grade_level = ?'
    countParams.push(gradeLevel)
  }
  if (difficulty) {
    countSql += ' AND difficulty = ?'
    countParams.push(difficulty)
  }
  if (source) {
    countSql += ' AND source = ?'
    countParams.push(source)
  }

  let countStmt = env.DB.prepare(countSql)
  for (const param of countParams) {
    countStmt = countStmt.bind(param)
  }
  const countResult = await countStmt.first<{ count: number }>()

  return jsonResponse({
    lessons,
    total: countResult?.count || 0,
    limit,
    offset,
  })
}

/**
 * GET /api/lessons/subjects - get distinct subjects
 */
async function getSubjects(env: Env): Promise<Response> {
  const result = await env.DB.prepare(
    'SELECT DISTINCT subject FROM lessons WHERE is_published = 1 ORDER BY subject'
  ).all<{ subject: string }>()

  const subjects = (result.results || []).map((s) => s.subject)
  return jsonResponse({ subjects })
}

/**
 * GET /api/lessons/filters - get available filter options
 */
async function getFilters(env: Env): Promise<Response> {
  const subjects = await env.DB.prepare(
    'SELECT DISTINCT subject FROM lessons WHERE is_published = 1 ORDER BY subject'
  ).all<{ subject: string }>()

  const gradeLevels = await env.DB.prepare(
    'SELECT DISTINCT grade_level FROM lessons WHERE is_published = 1 AND grade_level IS NOT NULL ORDER BY grade_level'
  ).all<{ grade_level: string }>()

  const ageRange = await env.DB.prepare(`
    SELECT MIN(age_min) as min_age, MAX(age_max) as max_age
    FROM lessons WHERE is_published = 1
  `).first<{ min_age: number | null; max_age: number | null }>()

  const difficulties: LessonDifficulty[] = ['beginner', 'easy', 'medium', 'hard', 'advanced']
  const sources: LessonSource[] = ['ai_generated', 'curated']
  const learningStyles: LearningStyle[] = ['visual', 'auditory', 'kinesthetic']

  return jsonResponse({
    subjects: (subjects.results || []).map((s) => s.subject),
    gradeLevels: (gradeLevels.results || []).map((g) => g.grade_level),
    difficulties,
    sources,
    learningStyles,
    ageRange: {
      min: ageRange?.min_age ?? 3,
      max: ageRange?.max_age ?? 12,
    },
  })
}

/**
 * GET /api/lessons/search - search lessons (basic LIKE search, no FTS)
 */
async function searchLessons(request: Request, env: Env): Promise<Response> {
  const url = new URL(request.url)
  const q = url.searchParams.get('q')
  const limit = parseInt(url.searchParams.get('limit') || '20', 10)
  const offset = parseInt(url.searchParams.get('offset') || '0', 10)

  if (!q || q.trim().length === 0) {
    return errorResponse('Search query is required', 400)
  }

  // Use LIKE for basic search (D1 doesn't support FTS5)
  const searchPattern = `%${q}%`

  const result = await env.DB.prepare(`
    SELECT l.*,
      COALESCE(AVG(r.rating), 0) as avg_rating,
      COUNT(DISTINCT r.id) as rating_count,
      COALESCE(SUM(e.completion_count), 0) as total_completions
    FROM lessons l
    LEFT JOIN lesson_ratings r ON l.id = r.lesson_id
    LEFT JOIN lesson_engagement e ON l.id = e.lesson_id
    WHERE l.is_published = 1
      AND (l.title LIKE ? OR l.description LIKE ? OR l.subject LIKE ? OR l.tags LIKE ?)
    GROUP BY l.id
    ORDER BY l.created_at DESC
    LIMIT ? OFFSET ?
  `).bind(searchPattern, searchPattern, searchPattern, searchPattern, limit, offset)
    .all<LessonRow & {
      avg_rating: number
      rating_count: number
      total_completions: number
    }>()

  const lessons = (result.results || []).map((l) => ({
    ...parseLesson(l),
    avg_rating: l.avg_rating || null,
    rating_count: l.rating_count,
    total_completions: l.total_completions,
  }))

  const countResult = await env.DB.prepare(`
    SELECT COUNT(*) as count FROM lessons
    WHERE is_published = 1
      AND (title LIKE ? OR description LIKE ? OR subject LIKE ? OR tags LIKE ?)
  `).bind(searchPattern, searchPattern, searchPattern, searchPattern)
    .first<{ count: number }>()

  return jsonResponse({
    lessons,
    total: countResult?.count || 0,
    limit,
    offset,
  })
}

/**
 * GET /api/lessons/:id - get a specific lesson
 */
async function getLesson(env: Env, lessonId: string): Promise<Response> {
  const lesson = await env.DB.prepare(`
    SELECT l.*,
      COALESCE(AVG(r.rating), 0) as avg_rating,
      COUNT(DISTINCT r.id) as rating_count,
      COALESCE(SUM(e.completion_count), 0) as total_completions
    FROM lessons l
    LEFT JOIN lesson_ratings r ON l.id = r.lesson_id
    LEFT JOIN lesson_engagement e ON l.id = e.lesson_id
    WHERE l.id = ?
    GROUP BY l.id
  `).bind(lessonId).first<LessonRow & {
    avg_rating: number
    rating_count: number
    total_completions: number
  }>()

  if (!lesson) {
    return errorResponse('Lesson not found', 404)
  }

  return jsonResponse({
    lesson: {
      ...parseLesson(lesson),
      avg_rating: lesson.avg_rating || null,
      rating_count: lesson.rating_count,
      total_completions: lesson.total_completions,
    },
  })
}

/**
 * POST /api/lessons - create a new lesson
 */
async function createLesson(request: Request, env: Env): Promise<Response> {
  const body = await request.json() as {
    title?: string
    subject?: string
    description?: string
    gradeLevel?: string
    difficulty?: string
    durationMinutes?: number
    ageMin?: number
    ageMax?: number
    learningStyles?: string[]
    interests?: string[]
    objectives?: unknown[]
    activities?: unknown[]
    materials?: unknown[]
    assessmentCriteria?: unknown[]
    source?: string
    tags?: string[]
    isPublished?: boolean
  }

  if (!body.title || !body.subject) {
    return errorResponse('Title and subject are required', 400)
  }

  const id = crypto.randomUUID()

  await env.DB.prepare(`
    INSERT INTO lessons (
      id, title, subject, description, grade_level, difficulty,
      duration_minutes, age_min, age_max, learning_styles, interests,
      objectives, activities, materials, assessment_criteria,
      source, tags, is_published
    )
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `).bind(
    id,
    body.title,
    body.subject,
    body.description || null,
    body.gradeLevel || null,
    body.difficulty || null,
    body.durationMinutes || null,
    body.ageMin || null,
    body.ageMax || null,
    body.learningStyles ? JSON.stringify(body.learningStyles) : null,
    body.interests ? JSON.stringify(body.interests) : null,
    body.objectives ? JSON.stringify(body.objectives) : null,
    body.activities ? JSON.stringify(body.activities) : null,
    body.materials ? JSON.stringify(body.materials) : null,
    body.assessmentCriteria ? JSON.stringify(body.assessmentCriteria) : null,
    body.source || 'curated',
    body.tags ? JSON.stringify(body.tags) : null,
    body.isPublished !== false ? 1 : 0
  ).run()

  const lesson = await env.DB.prepare(
    'SELECT * FROM lessons WHERE id = ?'
  ).bind(id).first<LessonRow>()

  return jsonResponse({ lesson: parseLesson(lesson!) }, 201)
}

/**
 * PUT /api/lessons/:id - update a lesson
 */
async function updateLesson(
  request: Request,
  env: Env,
  lessonId: string
): Promise<Response> {
  const existing = await env.DB.prepare(
    'SELECT id FROM lessons WHERE id = ?'
  ).bind(lessonId).first<{ id: string }>()

  if (!existing) {
    return errorResponse('Lesson not found', 404)
  }

  const body = await request.json() as Partial<{
    title: string
    subject: string
    description: string
    gradeLevel: string
    difficulty: string
    durationMinutes: number
    ageMin: number
    ageMax: number
    learningStyles: string[]
    interests: string[]
    objectives: unknown[]
    activities: unknown[]
    materials: unknown[]
    assessmentCriteria: unknown[]
    source: string
    tags: string[]
    isPublished: boolean
  }>

  const updates: string[] = []
  const values: (string | number | null)[] = []

  if (body.title !== undefined) {
    updates.push('title = ?')
    values.push(body.title)
  }
  if (body.subject !== undefined) {
    updates.push('subject = ?')
    values.push(body.subject)
  }
  if (body.description !== undefined) {
    updates.push('description = ?')
    values.push(body.description)
  }
  if (body.gradeLevel !== undefined) {
    updates.push('grade_level = ?')
    values.push(body.gradeLevel)
  }
  if (body.difficulty !== undefined) {
    updates.push('difficulty = ?')
    values.push(body.difficulty)
  }
  if (body.durationMinutes !== undefined) {
    updates.push('duration_minutes = ?')
    values.push(body.durationMinutes)
  }
  if (body.ageMin !== undefined) {
    updates.push('age_min = ?')
    values.push(body.ageMin)
  }
  if (body.ageMax !== undefined) {
    updates.push('age_max = ?')
    values.push(body.ageMax)
  }
  if (body.learningStyles !== undefined) {
    updates.push('learning_styles = ?')
    values.push(JSON.stringify(body.learningStyles))
  }
  if (body.interests !== undefined) {
    updates.push('interests = ?')
    values.push(JSON.stringify(body.interests))
  }
  if (body.objectives !== undefined) {
    updates.push('objectives = ?')
    values.push(JSON.stringify(body.objectives))
  }
  if (body.activities !== undefined) {
    updates.push('activities = ?')
    values.push(JSON.stringify(body.activities))
  }
  if (body.materials !== undefined) {
    updates.push('materials = ?')
    values.push(JSON.stringify(body.materials))
  }
  if (body.assessmentCriteria !== undefined) {
    updates.push('assessment_criteria = ?')
    values.push(JSON.stringify(body.assessmentCriteria))
  }
  if (body.source !== undefined) {
    updates.push('source = ?')
    values.push(body.source)
  }
  if (body.tags !== undefined) {
    updates.push('tags = ?')
    values.push(JSON.stringify(body.tags))
  }
  if (body.isPublished !== undefined) {
    updates.push('is_published = ?')
    values.push(body.isPublished ? 1 : 0)
  }

  if (updates.length > 0) {
    updates.push("updated_at = datetime('now')")
    const sql = `UPDATE lessons SET ${updates.join(', ')} WHERE id = ?`

    let stmt = env.DB.prepare(sql)
    for (const val of [...values, lessonId]) {
      stmt = stmt.bind(val)
    }
    await stmt.run()
  }

  const lesson = await env.DB.prepare(
    'SELECT * FROM lessons WHERE id = ?'
  ).bind(lessonId).first<LessonRow>()

  return jsonResponse({ lesson: parseLesson(lesson!) })
}

/**
 * DELETE /api/lessons/:id - delete a lesson
 */
async function deleteLesson(env: Env, lessonId: string): Promise<Response> {
  const result = await env.DB.prepare(
    'DELETE FROM lessons WHERE id = ?'
  ).bind(lessonId).run()

  if (result.meta?.changes === 0) {
    return errorResponse('Lesson not found', 404)
  }

  return new Response(null, { status: 204 })
}

/**
 * GET /api/lessons/:id/recommendations - get similar lessons
 */
async function getRecommendations(
  _request: Request,
  env: Env,
  lessonId: string
): Promise<Response> {
  const lesson = await env.DB.prepare(
    'SELECT * FROM lessons WHERE id = ?'
  ).bind(lessonId).first<LessonRow>()

  if (!lesson) {
    return errorResponse('Lesson not found', 404)
  }

  // Basic recommendations based on subject or grade level
  const recommendations = await env.DB.prepare(`
    SELECT * FROM lessons
    WHERE id != ? AND is_published = 1 AND (subject = ? OR grade_level = ?)
    ORDER BY RANDOM()
    LIMIT 5
  `).bind(lessonId, lesson.subject, lesson.grade_level)
    .all<LessonRow>()

  return jsonResponse({
    recommendations: (recommendations.results || []).map(parseLesson),
  })
}

/**
 * POST /api/lessons/:id/rate - rate a lesson
 */
async function rateLesson(
  request: Request,
  env: Env,
  lessonId: string
): Promise<Response> {
  const authResult = requireAuth(request, env)
  if ('error' in authResult) {
    return authResult.error
  }
  const userId = authResult.user.userId

  const body = await request.json() as {
    rating?: number
    feedback?: string
    childId?: string
  }

  const { rating, feedback, childId } = body

  if (!rating || rating < 1 || rating > 5) {
    return errorResponse('Rating must be between 1 and 5', 400)
  }

  const lesson = await env.DB.prepare(
    'SELECT id FROM lessons WHERE id = ?'
  ).bind(lessonId).first<{ id: string }>()

  if (!lesson) {
    return errorResponse('Lesson not found', 404)
  }

  const id = crypto.randomUUID()

  // Use INSERT OR REPLACE for upsert behavior
  await env.DB.prepare(`
    INSERT INTO lesson_ratings (id, lesson_id, user_id, child_id, rating, feedback)
    VALUES (?, ?, ?, ?, ?, ?)
    ON CONFLICT(lesson_id, user_id, child_id) DO UPDATE SET
      rating = excluded.rating,
      feedback = excluded.feedback
  `).bind(id, lessonId, userId, childId || null, rating, feedback || null).run()

  const stats = await env.DB.prepare(`
    SELECT AVG(rating) as avg_rating, COUNT(*) as rating_count
    FROM lesson_ratings WHERE lesson_id = ?
  `).bind(lessonId).first<{ avg_rating: number; rating_count: number }>()

  return jsonResponse({
    success: true,
    avg_rating: stats?.avg_rating || 0,
    rating_count: stats?.rating_count || 0,
  })
}

/**
 * POST /api/lessons/:id/engagement - track lesson engagement
 */
async function trackEngagement(
  request: Request,
  env: Env,
  lessonId: string
): Promise<Response> {
  const authResult = requireAuth(request, env)
  if ('error' in authResult) {
    return authResult.error
  }

  const body = await request.json() as {
    childId?: string
    action?: string
    timeSeconds?: number
  }

  const { childId, action, timeSeconds } = body

  if (!childId || !action) {
    return errorResponse('childId and action are required', 400)
  }

  const validActions = ['view', 'start', 'complete']
  if (!validActions.includes(action)) {
    return errorResponse('Invalid action', 400)
  }

  const lesson = await env.DB.prepare(
    'SELECT id FROM lessons WHERE id = ?'
  ).bind(lessonId).first<{ id: string }>()

  if (!lesson) {
    return errorResponse('Lesson not found', 404)
  }

  const existing = await env.DB.prepare(
    'SELECT * FROM lesson_engagement WHERE lesson_id = ? AND child_id = ?'
  ).bind(lessonId, childId).first<{ id: string }>()

  if (existing) {
    const updateField = action === 'view' ? 'view_count' : action === 'start' ? 'start_count' : 'completion_count'
    let sql = `
      UPDATE lesson_engagement
      SET ${updateField} = ${updateField} + 1,
          last_accessed_at = datetime('now'),
          updated_at = datetime('now')
    `
    if (timeSeconds) {
      sql += ', total_time_seconds = total_time_seconds + ?'
    }
    sql += ' WHERE lesson_id = ? AND child_id = ?'

    if (timeSeconds) {
      await env.DB.prepare(sql).bind(timeSeconds, lessonId, childId).run()
    } else {
      await env.DB.prepare(sql).bind(lessonId, childId).run()
    }
  } else {
    const id = crypto.randomUUID()
    await env.DB.prepare(`
      INSERT INTO lesson_engagement (
        id, lesson_id, child_id, view_count, start_count, completion_count,
        total_time_seconds, last_accessed_at
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, datetime('now'))
    `).bind(
      id,
      lessonId,
      childId,
      action === 'view' ? 1 : 0,
      action === 'start' ? 1 : 0,
      action === 'complete' ? 1 : 0,
      timeSeconds || 0
    ).run()
  }

  return jsonResponse({ success: true })
}
