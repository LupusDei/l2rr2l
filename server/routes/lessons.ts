import { Router, Request, Response } from 'express'
import { randomUUID } from 'crypto'
import { db } from '../db/index.js'
import { optionalAuthMiddleware, authMiddleware, AuthenticatedRequest } from '../middleware/auth.js'
import { generateLesson, getSupportedSubjects, AIProvider, ChildProfile } from '../services/ai.js'

const router = Router()

interface LessonRow {
  id: string
  title: string
  subject: string
  grade_level: string | null
  difficulty: string | null
  duration_minutes: number | null
  content: string | null
  objectives: string | null
  created_at: string
  updated_at: string
}

router.use(optionalAuthMiddleware)

router.get('/', (req: Request, res: Response) => {
  const { subject, gradeLevel, difficulty, limit = '20', offset = '0' } = req.query

  let query = 'SELECT * FROM lessons WHERE 1=1'
  const params: (string | number)[] = []

  if (subject) {
    query += ' AND subject = ?'
    params.push(subject as string)
  }
  if (gradeLevel) {
    query += ' AND grade_level = ?'
    params.push(gradeLevel as string)
  }
  if (difficulty) {
    query += ' AND difficulty = ?'
    params.push(difficulty as string)
  }

  query += ' ORDER BY created_at DESC LIMIT ? OFFSET ?'
  params.push(parseInt(limit as string, 10), parseInt(offset as string, 10))

  const lessons = db.prepare(query).all(...params) as LessonRow[]

  const countQuery = query.replace(/SELECT \*/, 'SELECT COUNT(*) as count').replace(/ ORDER BY.+$/, '')
  const total = (db.prepare(countQuery).get(...params.slice(0, -2)) as { count: number }).count

  res.json({
    lessons: lessons.map(l => ({
      ...l,
      content: l.content ? JSON.parse(l.content) : null,
      objectives: l.objectives ? JSON.parse(l.objectives) : null
    })),
    total,
    limit: parseInt(limit as string, 10),
    offset: parseInt(offset as string, 10)
  })
})

router.get('/subjects', (_req: Request, res: Response) => {
  const subjects = db.prepare('SELECT DISTINCT subject FROM lessons ORDER BY subject')
    .all() as { subject: string }[]

  res.json({ subjects: subjects.map(s => s.subject) })
})

router.get('/supported-subjects', (_req: Request, res: Response) => {
  res.json({ subjects: getSupportedSubjects() })
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

  // Verify child belongs to user
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

    // Optionally save to database
    if (saveToLibrary) {
      db.prepare(`
        INSERT INTO lessons (id, title, subject, grade_level, difficulty, duration_minutes, content, objectives)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      `).run(
        lesson.id,
        lesson.title,
        lesson.subject,
        lesson.gradeLevel,
        lesson.difficulty,
        lesson.durationMinutes,
        JSON.stringify({
          activities: lesson.activities,
          materials: lesson.materials,
          assessmentCriteria: lesson.assessmentCriteria,
          source: lesson.source
        }),
        JSON.stringify(lesson.objectives)
      )
    }

    res.status(201).json({ lesson })
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Failed to generate lesson'
    res.status(500).json({ error: message })
  }
})

router.get('/:id', (req: Request, res: Response) => {
  const lesson = db.prepare('SELECT * FROM lessons WHERE id = ?')
    .get(req.params.id) as LessonRow | undefined

  if (!lesson) {
    res.status(404).json({ error: 'Lesson not found' })
    return
  }

  res.json({
    lesson: {
      ...lesson,
      content: lesson.content ? JSON.parse(lesson.content) : null,
      objectives: lesson.objectives ? JSON.parse(lesson.objectives) : null
    }
  })
})

router.get('/:id/recommendations', (req: AuthenticatedRequest, res: Response) => {
  const lesson = db.prepare('SELECT * FROM lessons WHERE id = ?')
    .get(req.params.id) as LessonRow | undefined

  if (!lesson) {
    res.status(404).json({ error: 'Lesson not found' })
    return
  }

  const recommendations = db.prepare(`
    SELECT * FROM lessons
    WHERE id != ? AND (subject = ? OR grade_level = ?)
    ORDER BY RANDOM()
    LIMIT 5
  `).all(req.params.id, lesson.subject, lesson.grade_level) as LessonRow[]

  res.json({
    recommendations: recommendations.map(l => ({
      ...l,
      content: l.content ? JSON.parse(l.content) : null,
      objectives: l.objectives ? JSON.parse(l.objectives) : null
    }))
  })
})

// Admin-only endpoints for managing lessons (no auth check for MVP, add later)
router.post('/', (req: Request, res: Response) => {
  const { title, subject, gradeLevel, difficulty, durationMinutes, content, objectives } = req.body

  if (!title || !subject) {
    res.status(400).json({ error: 'Title and subject are required' })
    return
  }

  const id = randomUUID()

  db.prepare(`
    INSERT INTO lessons (id, title, subject, grade_level, difficulty, duration_minutes, content, objectives)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
  `).run(
    id,
    title,
    subject,
    gradeLevel || null,
    difficulty || null,
    durationMinutes || null,
    content ? JSON.stringify(content) : null,
    objectives ? JSON.stringify(objectives) : null
  )

  const lesson = db.prepare('SELECT * FROM lessons WHERE id = ?').get(id) as LessonRow

  res.status(201).json({
    lesson: {
      ...lesson,
      content: lesson.content ? JSON.parse(lesson.content) : null,
      objectives: lesson.objectives ? JSON.parse(lesson.objectives) : null
    }
  })
})

router.put('/:id', (req: Request, res: Response) => {
  const { title, subject, gradeLevel, difficulty, durationMinutes, content, objectives } = req.body

  const existing = db.prepare('SELECT id FROM lessons WHERE id = ?')
    .get(req.params.id) as { id: string } | undefined

  if (!existing) {
    res.status(404).json({ error: 'Lesson not found' })
    return
  }

  const updates: string[] = []
  const values: (string | number | null)[] = []

  if (title !== undefined) {
    updates.push('title = ?')
    values.push(title)
  }
  if (subject !== undefined) {
    updates.push('subject = ?')
    values.push(subject)
  }
  if (gradeLevel !== undefined) {
    updates.push('grade_level = ?')
    values.push(gradeLevel)
  }
  if (difficulty !== undefined) {
    updates.push('difficulty = ?')
    values.push(difficulty)
  }
  if (durationMinutes !== undefined) {
    updates.push('duration_minutes = ?')
    values.push(durationMinutes)
  }
  if (content !== undefined) {
    updates.push('content = ?')
    values.push(JSON.stringify(content))
  }
  if (objectives !== undefined) {
    updates.push('objectives = ?')
    values.push(JSON.stringify(objectives))
  }

  if (updates.length > 0) {
    updates.push("updated_at = datetime('now')")
    db.prepare(`UPDATE lessons SET ${updates.join(', ')} WHERE id = ?`)
      .run(...values, req.params.id)
  }

  const lesson = db.prepare('SELECT * FROM lessons WHERE id = ?').get(req.params.id) as LessonRow

  res.json({
    lesson: {
      ...lesson,
      content: lesson.content ? JSON.parse(lesson.content) : null,
      objectives: lesson.objectives ? JSON.parse(lesson.objectives) : null
    }
  })
})

router.delete('/:id', (req: Request, res: Response) => {
  const result = db.prepare('DELETE FROM lessons WHERE id = ?').run(req.params.id)

  if (result.changes === 0) {
    res.status(404).json({ error: 'Lesson not found' })
    return
  }

  res.status(204).send()
})

export default router
