import { Router } from 'express'
import { randomUUID } from 'crypto'
import { db } from '../db/index.js'
import { authMiddleware, AuthenticatedRequest } from '../middleware/auth.js'

const router = Router()

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

interface ChildRow {
  id: string
  user_id: string
}

router.use(authMiddleware)

function verifyChildOwnership(childId: string, userId: string): boolean {
  const child = db.prepare('SELECT id FROM children WHERE id = ? AND user_id = ?')
    .get(childId, userId) as ChildRow | undefined
  return !!child
}

router.get('/child/:childId', (req: AuthenticatedRequest, res) => {
  if (!verifyChildOwnership(req.params.childId, req.user!.userId)) {
    res.status(404).json({ error: 'Child not found' })
    return
  }

  const progress = db.prepare(`
    SELECT p.*, l.title as lesson_title, l.subject
    FROM progress p
    LEFT JOIN lessons l ON p.lesson_id = l.id
    WHERE p.child_id = ?
    ORDER BY p.updated_at DESC
  `).all(req.params.childId) as (ProgressRow & { lesson_title?: string; subject?: string })[]

  res.json({ progress })
})

router.get('/child/:childId/lesson/:lessonId', (req: AuthenticatedRequest, res) => {
  if (!verifyChildOwnership(req.params.childId, req.user!.userId)) {
    res.status(404).json({ error: 'Child not found' })
    return
  }

  const progress = db.prepare(`
    SELECT * FROM progress WHERE child_id = ? AND lesson_id = ?
  `).get(req.params.childId, req.params.lessonId) as ProgressRow | undefined

  if (!progress) {
    res.json({
      progress: {
        childId: req.params.childId,
        lessonId: req.params.lessonId,
        status: 'not_started',
        score: null,
        timeSpent: 0
      }
    })
    return
  }

  res.json({ progress })
})

router.post('/child/:childId/lesson/:lessonId/start', (req: AuthenticatedRequest, res) => {
  if (!verifyChildOwnership(req.params.childId, req.user!.userId)) {
    res.status(404).json({ error: 'Child not found' })
    return
  }

  const existing = db.prepare('SELECT id FROM progress WHERE child_id = ? AND lesson_id = ?')
    .get(req.params.childId, req.params.lessonId) as { id: string } | undefined

  if (existing) {
    db.prepare(`
      UPDATE progress
      SET status = 'in_progress', started_at = COALESCE(started_at, datetime('now')), updated_at = datetime('now')
      WHERE id = ?
    `).run(existing.id)
  } else {
    const id = randomUUID()
    db.prepare(`
      INSERT INTO progress (id, child_id, lesson_id, status, started_at)
      VALUES (?, ?, ?, 'in_progress', datetime('now'))
    `).run(id, req.params.childId, req.params.lessonId)
  }

  const progress = db.prepare('SELECT * FROM progress WHERE child_id = ? AND lesson_id = ?')
    .get(req.params.childId, req.params.lessonId) as ProgressRow

  res.json({ progress })
})

router.post('/child/:childId/lesson/:lessonId/complete', (req: AuthenticatedRequest, res) => {
  const { score, timeSpent } = req.body

  if (!verifyChildOwnership(req.params.childId, req.user!.userId)) {
    res.status(404).json({ error: 'Child not found' })
    return
  }

  const existing = db.prepare('SELECT id FROM progress WHERE child_id = ? AND lesson_id = ?')
    .get(req.params.childId, req.params.lessonId) as { id: string } | undefined

  if (existing) {
    db.prepare(`
      UPDATE progress
      SET status = 'completed',
          score = COALESCE(?, score),
          time_spent = COALESCE(?, time_spent),
          completed_at = datetime('now'),
          updated_at = datetime('now')
      WHERE id = ?
    `).run(score ?? null, timeSpent ?? null, existing.id)
  } else {
    const id = randomUUID()
    db.prepare(`
      INSERT INTO progress (id, child_id, lesson_id, status, score, time_spent, started_at, completed_at)
      VALUES (?, ?, ?, 'completed', ?, ?, datetime('now'), datetime('now'))
    `).run(id, req.params.childId, req.params.lessonId, score ?? null, timeSpent ?? 0)
  }

  const progress = db.prepare('SELECT * FROM progress WHERE child_id = ? AND lesson_id = ?')
    .get(req.params.childId, req.params.lessonId) as ProgressRow

  res.json({ progress })
})

router.put('/child/:childId/lesson/:lessonId', (req: AuthenticatedRequest, res) => {
  const { status, score, timeSpent } = req.body

  if (!verifyChildOwnership(req.params.childId, req.user!.userId)) {
    res.status(404).json({ error: 'Child not found' })
    return
  }

  const existing = db.prepare('SELECT id FROM progress WHERE child_id = ? AND lesson_id = ?')
    .get(req.params.childId, req.params.lessonId) as { id: string } | undefined

  if (!existing) {
    res.status(404).json({ error: 'Progress record not found' })
    return
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
    db.prepare(`UPDATE progress SET ${updates.join(', ')} WHERE id = ?`)
      .run(...values, existing.id)
  }

  const progress = db.prepare('SELECT * FROM progress WHERE id = ?').get(existing.id) as ProgressRow

  res.json({ progress })
})

router.get('/child/:childId/summary', (req: AuthenticatedRequest, res) => {
  if (!verifyChildOwnership(req.params.childId, req.user!.userId)) {
    res.status(404).json({ error: 'Child not found' })
    return
  }

  const stats = db.prepare(`
    SELECT
      COUNT(*) as total_lessons,
      SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed_lessons,
      SUM(CASE WHEN status = 'in_progress' THEN 1 ELSE 0 END) as in_progress_lessons,
      AVG(CASE WHEN score IS NOT NULL THEN score END) as average_score,
      SUM(time_spent) as total_time_spent
    FROM progress WHERE child_id = ?
  `).get(req.params.childId) as {
    total_lessons: number
    completed_lessons: number
    in_progress_lessons: number
    average_score: number | null
    total_time_spent: number
  }

  res.json({ summary: stats })
})

export default router
