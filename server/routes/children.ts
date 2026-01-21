import { Router } from 'express'
import { randomUUID } from 'crypto'
import { db } from '../db/index.js'
import { authMiddleware, AuthenticatedRequest } from '../middleware/auth.js'

const router = Router()

interface ChildRow {
  id: string
  user_id: string
  name: string
  age: number | null
  grade_level: string | null
  learning_style: string | null
  interests: string | null
  created_at: string
  updated_at: string
}

router.use(authMiddleware)

router.get('/', (req: AuthenticatedRequest, res) => {
  const children = db.prepare('SELECT * FROM children WHERE user_id = ?')
    .all(req.user!.userId) as ChildRow[]

  res.json({
    children: children.map(c => ({
      ...c,
      interests: c.interests ? JSON.parse(c.interests) : []
    }))
  })
})

router.post('/', (req: AuthenticatedRequest, res) => {
  const { name, age, gradeLevel, learningStyle, interests } = req.body

  if (!name) {
    res.status(400).json({ error: 'Name is required' })
    return
  }

  const id = randomUUID()
  const interestsJson = interests ? JSON.stringify(interests) : null

  db.prepare(`
    INSERT INTO children (id, user_id, name, age, grade_level, learning_style, interests)
    VALUES (?, ?, ?, ?, ?, ?, ?)
  `).run(id, req.user!.userId, name, age || null, gradeLevel || null, learningStyle || null, interestsJson)

  const child = db.prepare('SELECT * FROM children WHERE id = ?').get(id) as ChildRow

  res.status(201).json({
    child: {
      ...child,
      interests: child.interests ? JSON.parse(child.interests) : []
    }
  })
})

router.get('/:id', (req: AuthenticatedRequest, res) => {
  const child = db.prepare('SELECT * FROM children WHERE id = ? AND user_id = ?')
    .get(req.params.id, req.user!.userId) as ChildRow | undefined

  if (!child) {
    res.status(404).json({ error: 'Child not found' })
    return
  }

  res.json({
    child: {
      ...child,
      interests: child.interests ? JSON.parse(child.interests) : []
    }
  })
})

router.put('/:id', (req: AuthenticatedRequest, res) => {
  const { name, age, gradeLevel, learningStyle, interests } = req.body

  const existing = db.prepare('SELECT id FROM children WHERE id = ? AND user_id = ?')
    .get(req.params.id, req.user!.userId) as { id: string } | undefined

  if (!existing) {
    res.status(404).json({ error: 'Child not found' })
    return
  }

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
    db.prepare(`UPDATE children SET ${updates.join(', ')} WHERE id = ?`)
      .run(...values, req.params.id)
  }

  const child = db.prepare('SELECT * FROM children WHERE id = ?').get(req.params.id) as ChildRow

  res.json({
    child: {
      ...child,
      interests: child.interests ? JSON.parse(child.interests) : []
    }
  })
})

router.delete('/:id', (req: AuthenticatedRequest, res) => {
  const result = db.prepare('DELETE FROM children WHERE id = ? AND user_id = ?')
    .run(req.params.id, req.user!.userId)

  if (result.changes === 0) {
    res.status(404).json({ error: 'Child not found' })
    return
  }

  res.status(204).send()
})

export default router
