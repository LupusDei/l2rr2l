import { Router, Request, Response } from 'express'
import { randomUUID } from 'crypto'
import { db } from '../db/index.js'
import { optionalAuthMiddleware, AuthenticatedRequest, authMiddleware } from '../middleware/auth.js'
import { generateLesson, getSupportedSubjects, AIProvider, ChildProfile } from '../services/ai.js'
import { matchLessonsForChild, getQuickRecommendations } from '../services/lessonMatcher.js'
import {
  LessonRow,
  CreateLessonInput,
  parseLesson,
  LessonDifficulty,
  LessonSource,
  LearningStyle
} from '../types/lesson.js'

const router = Router()

router.use(optionalAuthMiddleware)

router.get('/', (req: Request, res: Response) => {
  const {
    subject,
    gradeLevel,
    difficulty,
    ageMin,
    ageMax,
    learningStyles,
    interests,
    source,
    tags,
    query,
    limit = '20',
    offset = '0'
  } = req.query

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
    params.push(subject as string)
  }
  if (gradeLevel) {
    sql += ' AND l.grade_level = ?'
    params.push(gradeLevel as string)
  }
  if (difficulty) {
    sql += ' AND l.difficulty = ?'
    params.push(difficulty as string)
  }
  if (ageMin) {
    sql += ' AND (l.age_max IS NULL OR l.age_max >= ?)'
    params.push(parseInt(ageMin as string, 10))
  }
  if (ageMax) {
    sql += ' AND (l.age_min IS NULL OR l.age_min <= ?)'
    params.push(parseInt(ageMax as string, 10))
  }
  if (source) {
    sql += ' AND l.source = ?'
    params.push(source as string)
  }

  if (learningStyles) {
    const styles = Array.isArray(learningStyles) ? learningStyles : [learningStyles]
    const styleConditions = styles.map(() => "l.learning_styles LIKE ?").join(' OR ')
    sql += ` AND (${styleConditions})`
    styles.forEach(s => params.push(`%"${s}"%`))
  }

  if (interests) {
    const interestList = Array.isArray(interests) ? interests : [interests]
    const interestConditions = interestList.map(() => "l.interests LIKE ?").join(' OR ')
    sql += ` AND (${interestConditions})`
    interestList.forEach(i => params.push(`%"${i}"%`))
  }

  if (tags) {
    const tagList = Array.isArray(tags) ? tags : [tags]
    const tagConditions = tagList.map(() => "l.tags LIKE ?").join(' OR ')
    sql += ` AND (${tagConditions})`
    tagList.forEach(t => params.push(`%"${t}"%`))
  }

  if (query) {
    sql += ' AND (l.title LIKE ? OR l.description LIKE ? OR l.subject LIKE ?)'
    const searchTerm = `%${query}%`
    params.push(searchTerm, searchTerm, searchTerm)
  }

  sql += ' GROUP BY l.id ORDER BY l.created_at DESC LIMIT ? OFFSET ?'
  params.push(parseInt(limit as string, 10), parseInt(offset as string, 10))

  const lessons = db.prepare(sql).all(...params) as (LessonRow & {
    avg_rating: number
    rating_count: number
    total_completions: number
  })[]

  const countSql = sql
    .replace(/SELECT l\.\*[\s\S]*?FROM lessons l/, 'SELECT COUNT(DISTINCT l.id) as count FROM lessons l')
    .replace(/ GROUP BY[\s\S]*$/, '')
  const total = (db.prepare(countSql).get(...params.slice(0, -2)) as { count: number }).count

  res.json({
    lessons: lessons.map(l => ({
      ...parseLesson(l),
      avg_rating: l.avg_rating || null,
      rating_count: l.rating_count,
      total_completions: l.total_completions
    })),
    total,
    limit: parseInt(limit as string, 10),
    offset: parseInt(offset as string, 10)
  })
})

router.get('/subjects', (_req: Request, res: Response) => {
  const subjects = db.prepare('SELECT DISTINCT subject FROM lessons WHERE is_published = 1 ORDER BY subject')
    .all() as { subject: string }[]

  res.json({ subjects: subjects.map(s => s.subject) })
})

router.get('/supported-subjects', (_req: Request, res: Response) => {
  res.json({ subjects: getSupportedSubjects() })
})

router.get('/filters', (_req: Request, res: Response) => {
  const subjects = db.prepare('SELECT DISTINCT subject FROM lessons WHERE is_published = 1 ORDER BY subject')
    .all() as { subject: string }[]

  const gradeLevels = db.prepare('SELECT DISTINCT grade_level FROM lessons WHERE is_published = 1 AND grade_level IS NOT NULL ORDER BY grade_level')
    .all() as { grade_level: string }[]

  const difficulties: LessonDifficulty[] = ['beginner', 'easy', 'medium', 'hard', 'advanced']
  const sources: LessonSource[] = ['ai_generated', 'curated']
  const learningStylesList: LearningStyle[] = ['visual', 'auditory', 'kinesthetic']

  const ageRange = db.prepare(`
    SELECT MIN(age_min) as min_age, MAX(age_max) as max_age
    FROM lessons WHERE is_published = 1
  `).get() as { min_age: number | null; max_age: number | null }

  res.json({
    subjects: subjects.map(s => s.subject),
    gradeLevels: gradeLevels.map(g => g.grade_level),
    difficulties,
    sources,
    learningStyles: learningStylesList,
    ageRange: {
      min: ageRange.min_age ?? 3,
      max: ageRange.max_age ?? 12
    }
  })
})

interface ChildRow {
  id: string
  name: string
  age: number | null
  grade_level: string | null
  learning_style: string | null
  interests: string | null
}

router.post('/generate', authMiddleware, async (req: AuthenticatedRequest, res: Response) => {
  const { childId, subject, topic, preferredDuration, provider = 'grok', saveToLibrary = false } = req.body

  if (!childId || !subject) {
    res.status(400).json({ error: 'childId and subject are required' })
    return
  }

  const child = db.prepare('SELECT * FROM children WHERE id = ? AND user_id = ?')
    .get(childId, req.user!.userId) as ChildRow | undefined

  if (!child) {
    res.status(404).json({ error: 'Child not found' })
    return
  }

  const childProfile: ChildProfile = {
    name: child.name,
    age: child.age,
    gradeLevel: child.grade_level,
    learningStyle: child.learning_style,
    interests: child.interests ? JSON.parse(child.interests) : null
  }

  try {
    const lesson = await generateLesson(
      { childProfile, subject, topic, preferredDuration },
      provider as AIProvider
    )

    if (saveToLibrary) {
      db.prepare(`
        INSERT INTO lessons (
          id, title, subject, grade_level, difficulty, duration_minutes,
          objectives, activities, materials, assessment_criteria, source, is_published
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `).run(
        lesson.id,
        lesson.title,
        lesson.subject,
        lesson.gradeLevel,
        lesson.difficulty,
        lesson.durationMinutes,
        JSON.stringify(lesson.objectives.map((o: string) => ({ description: o }))),
        JSON.stringify(lesson.activities),
        JSON.stringify(lesson.materials),
        JSON.stringify(lesson.assessmentCriteria.map((c: string) => ({
          type: 'observation',
          description: c,
          success_indicators: []
        }))),
        'ai_generated',
        1
      )
    }

    res.status(201).json({ lesson })
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Failed to generate lesson'
    res.status(500).json({ error: message })
  }
})

// Personalized lesson matching for a child
router.get('/match/:childId', authMiddleware, (req: AuthenticatedRequest, res: Response) => {
  const { childId } = req.params
  const { limit, excludeCompleted, subject, minScore } = req.query

  // Verify child belongs to user
  const child = db.prepare('SELECT id FROM children WHERE id = ? AND user_id = ?')
    .get(childId, req.user!.userId) as { id: string } | undefined

  if (!child) {
    res.status(404).json({ error: 'Child not found' })
    return
  }

  try {
    const matches = matchLessonsForChild(childId, {
      limit: limit ? parseInt(limit as string, 10) : 20,
      excludeCompleted: excludeCompleted !== 'false',
      subjectFilter: subject as string | undefined,
      minScore: minScore ? parseInt(minScore as string, 10) : 0
    })

    res.json({
      matches,
      total: matches.length,
      childId
    })
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Failed to match lessons'
    res.status(500).json({ error: message })
  }
})

router.get('/:id', (req: Request, res: Response) => {
  const lesson = db.prepare(`
    SELECT l.*,
      COALESCE(AVG(r.rating), 0) as avg_rating,
      COUNT(DISTINCT r.id) as rating_count,
      COALESCE(SUM(e.completion_count), 0) as total_completions
    FROM lessons l
    LEFT JOIN lesson_ratings r ON l.id = r.lesson_id
    LEFT JOIN lesson_engagement e ON l.id = e.lesson_id
    WHERE l.id = ?
    GROUP BY l.id
  `).get(req.params.id) as (LessonRow & {
    avg_rating: number
    rating_count: number
    total_completions: number
  }) | undefined

  if (!lesson) {
    res.status(404).json({ error: 'Lesson not found' })
    return
  }

  res.json({
    lesson: {
      ...parseLesson(lesson),
      avg_rating: lesson.avg_rating || null,
      rating_count: lesson.rating_count,
      total_completions: lesson.total_completions
    }
  })
})

router.get('/:id/recommendations', (req: AuthenticatedRequest, res: Response) => {
  const { childId } = req.query
  const lessonId = req.params.id

  const lesson = db.prepare('SELECT * FROM lessons WHERE id = ?')
    .get(lessonId) as LessonRow | undefined

  if (!lesson) {
    res.status(404).json({ error: 'Lesson not found' })
    return
  }

  // Use smart matching when childId is provided
  if (childId) {
    const recommendations = getQuickRecommendations(childId as string, lessonId, 5)
    res.json({ recommendations })
    return
  }

  // Fallback to basic matching without child context
  const recommendations = db.prepare(`
    SELECT * FROM lessons
    WHERE id != ? AND is_published = 1 AND (subject = ? OR grade_level = ?)
    ORDER BY RANDOM()
    LIMIT 5
  `).all(lessonId, lesson.subject, lesson.grade_level) as LessonRow[]

  res.json({
    recommendations: recommendations.map(parseLesson)
  })
})

router.post('/', (req: Request, res: Response) => {
  const input: CreateLessonInput = req.body

  if (!input.title || !input.subject) {
    res.status(400).json({ error: 'Title and subject are required' })
    return
  }

  const id = randomUUID()

  db.prepare(`
    INSERT INTO lessons (
      id, title, subject, description, grade_level, difficulty,
      duration_minutes, age_min, age_max, learning_styles, interests,
      objectives, activities, materials, assessment_criteria,
      source, tags, is_published
    )
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `).run(
    id,
    input.title,
    input.subject,
    input.description || null,
    input.gradeLevel || null,
    input.difficulty || null,
    input.durationMinutes || null,
    input.ageMin || null,
    input.ageMax || null,
    input.learningStyles ? JSON.stringify(input.learningStyles) : null,
    input.interests ? JSON.stringify(input.interests) : null,
    input.objectives ? JSON.stringify(input.objectives) : null,
    input.activities ? JSON.stringify(input.activities) : null,
    input.materials ? JSON.stringify(input.materials) : null,
    input.assessmentCriteria ? JSON.stringify(input.assessmentCriteria) : null,
    input.source || 'curated',
    input.tags ? JSON.stringify(input.tags) : null,
    input.isPublished !== false ? 1 : 0
  )

  const lesson = db.prepare('SELECT * FROM lessons WHERE id = ?').get(id) as LessonRow

  res.status(201).json({ lesson: parseLesson(lesson) })
})

router.put('/:id', (req: Request, res: Response) => {
  const input: Partial<CreateLessonInput> = req.body

  const existing = db.prepare('SELECT id FROM lessons WHERE id = ?')
    .get(req.params.id) as { id: string } | undefined

  if (!existing) {
    res.status(404).json({ error: 'Lesson not found' })
    return
  }

  const updates: string[] = []
  const values: (string | number | null)[] = []

  if (input.title !== undefined) {
    updates.push('title = ?')
    values.push(input.title)
  }
  if (input.subject !== undefined) {
    updates.push('subject = ?')
    values.push(input.subject)
  }
  if (input.description !== undefined) {
    updates.push('description = ?')
    values.push(input.description)
  }
  if (input.gradeLevel !== undefined) {
    updates.push('grade_level = ?')
    values.push(input.gradeLevel)
  }
  if (input.difficulty !== undefined) {
    updates.push('difficulty = ?')
    values.push(input.difficulty)
  }
  if (input.durationMinutes !== undefined) {
    updates.push('duration_minutes = ?')
    values.push(input.durationMinutes)
  }
  if (input.ageMin !== undefined) {
    updates.push('age_min = ?')
    values.push(input.ageMin)
  }
  if (input.ageMax !== undefined) {
    updates.push('age_max = ?')
    values.push(input.ageMax)
  }
  if (input.learningStyles !== undefined) {
    updates.push('learning_styles = ?')
    values.push(JSON.stringify(input.learningStyles))
  }
  if (input.interests !== undefined) {
    updates.push('interests = ?')
    values.push(JSON.stringify(input.interests))
  }
  if (input.objectives !== undefined) {
    updates.push('objectives = ?')
    values.push(JSON.stringify(input.objectives))
  }
  if (input.activities !== undefined) {
    updates.push('activities = ?')
    values.push(JSON.stringify(input.activities))
  }
  if (input.materials !== undefined) {
    updates.push('materials = ?')
    values.push(JSON.stringify(input.materials))
  }
  if (input.assessmentCriteria !== undefined) {
    updates.push('assessment_criteria = ?')
    values.push(JSON.stringify(input.assessmentCriteria))
  }
  if (input.source !== undefined) {
    updates.push('source = ?')
    values.push(input.source)
  }
  if (input.tags !== undefined) {
    updates.push('tags = ?')
    values.push(JSON.stringify(input.tags))
  }
  if (input.isPublished !== undefined) {
    updates.push('is_published = ?')
    values.push(input.isPublished ? 1 : 0)
  }

  if (updates.length > 0) {
    updates.push("updated_at = datetime('now')")
    db.prepare(`UPDATE lessons SET ${updates.join(', ')} WHERE id = ?`)
      .run(...values, req.params.id)
  }

  const lesson = db.prepare('SELECT * FROM lessons WHERE id = ?').get(req.params.id) as LessonRow

  res.json({ lesson: parseLesson(lesson) })
})

router.delete('/:id', (req: Request, res: Response) => {
  const result = db.prepare('DELETE FROM lessons WHERE id = ?').run(req.params.id)

  if (result.changes === 0) {
    res.status(404).json({ error: 'Lesson not found' })
    return
  }

  res.status(204).send()
})

router.post('/:id/rate', authMiddleware, (req: AuthenticatedRequest, res: Response) => {
  const { rating, feedback, childId } = req.body
  const userId = req.user!.userId

  if (!rating || rating < 1 || rating > 5) {
    res.status(400).json({ error: 'Rating must be between 1 and 5' })
    return
  }

  const lesson = db.prepare('SELECT id FROM lessons WHERE id = ?')
    .get(req.params.id) as { id: string } | undefined

  if (!lesson) {
    res.status(404).json({ error: 'Lesson not found' })
    return
  }

  const id = randomUUID()

  db.prepare(`
    INSERT INTO lesson_ratings (id, lesson_id, user_id, child_id, rating, feedback)
    VALUES (?, ?, ?, ?, ?, ?)
    ON CONFLICT(lesson_id, user_id, child_id) DO UPDATE SET
      rating = excluded.rating,
      feedback = excluded.feedback
  `).run(id, req.params.id, userId, childId || null, rating, feedback || null)

  const lessonRating = db.prepare(`
    SELECT AVG(rating) as avg_rating, COUNT(*) as rating_count
    FROM lesson_ratings WHERE lesson_id = ?
  `).get(req.params.id) as { avg_rating: number; rating_count: number }

  res.json({
    success: true,
    avg_rating: lessonRating.avg_rating,
    rating_count: lessonRating.rating_count
  })
})

router.post('/:id/engagement', authMiddleware, (req: AuthenticatedRequest, res: Response) => {
  const { childId, action, timeSeconds } = req.body

  if (!childId || !action) {
    res.status(400).json({ error: 'childId and action are required' })
    return
  }

  const validActions = ['view', 'start', 'complete']
  if (!validActions.includes(action)) {
    res.status(400).json({ error: 'Invalid action' })
    return
  }

  const lesson = db.prepare('SELECT id FROM lessons WHERE id = ?')
    .get(req.params.id) as { id: string } | undefined

  if (!lesson) {
    res.status(404).json({ error: 'Lesson not found' })
    return
  }

  const existing = db.prepare(`
    SELECT * FROM lesson_engagement WHERE lesson_id = ? AND child_id = ?
  `).get(req.params.id, childId) as { id: string } | undefined

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
      db.prepare(sql).run(timeSeconds, req.params.id, childId)
    } else {
      db.prepare(sql).run(req.params.id, childId)
    }
  } else {
    const id = randomUUID()
    db.prepare(`
      INSERT INTO lesson_engagement (
        id, lesson_id, child_id, view_count, start_count, completion_count,
        total_time_seconds, last_accessed_at
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, datetime('now'))
    `).run(
      id,
      req.params.id,
      childId,
      action === 'view' ? 1 : 0,
      action === 'start' ? 1 : 0,
      action === 'complete' ? 1 : 0,
      timeSeconds || 0
    )
  }

  res.json({ success: true })
})

export default router
