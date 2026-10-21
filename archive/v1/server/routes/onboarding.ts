import { Router } from 'express'
import { randomUUID } from 'crypto'
import { db } from '../db/index.js'
import { authMiddleware, AuthenticatedRequest } from '../middleware/auth.js'

const router = Router()

interface OnboardingRow {
  id: string
  user_id: string
  completed: number
  step: number
  data: string | null
  created_at: string
  updated_at: string
}

router.use(authMiddleware)

router.get('/', (req: AuthenticatedRequest, res) => {
  const onboarding = db.prepare('SELECT * FROM onboarding WHERE user_id = ?')
    .get(req.user!.userId) as OnboardingRow | undefined

  if (!onboarding) {
    res.json({
      onboarding: {
        completed: false,
        step: 0,
        data: {}
      }
    })
    return
  }

  res.json({
    onboarding: {
      id: onboarding.id,
      completed: Boolean(onboarding.completed),
      step: onboarding.step,
      data: onboarding.data ? JSON.parse(onboarding.data) : {}
    }
  })
})

router.put('/', (req: AuthenticatedRequest, res) => {
  const { step, data, completed } = req.body

  const existing = db.prepare('SELECT * FROM onboarding WHERE user_id = ?')
    .get(req.user!.userId) as OnboardingRow | undefined

  if (!existing) {
    const id = randomUUID()
    db.prepare(`
      INSERT INTO onboarding (id, user_id, step, data, completed)
      VALUES (?, ?, ?, ?, ?)
    `).run(
      id,
      req.user!.userId,
      step ?? 0,
      data ? JSON.stringify(data) : null,
      completed ? 1 : 0
    )

    const onboarding = db.prepare('SELECT * FROM onboarding WHERE id = ?').get(id) as OnboardingRow
    res.json({
      onboarding: {
        id: onboarding.id,
        completed: Boolean(onboarding.completed),
        step: onboarding.step,
        data: onboarding.data ? JSON.parse(onboarding.data) : {}
      }
    })
    return
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
    db.prepare(`UPDATE onboarding SET ${updates.join(', ')} WHERE user_id = ?`)
      .run(...values, req.user!.userId)
  }

  const onboarding = db.prepare('SELECT * FROM onboarding WHERE user_id = ?')
    .get(req.user!.userId) as OnboardingRow

  res.json({
    onboarding: {
      id: onboarding.id,
      completed: Boolean(onboarding.completed),
      step: onboarding.step,
      data: onboarding.data ? JSON.parse(onboarding.data) : {}
    }
  })
})

router.post('/complete', (req: AuthenticatedRequest, res) => {
  const existing = db.prepare('SELECT id FROM onboarding WHERE user_id = ?')
    .get(req.user!.userId) as { id: string } | undefined

  if (!existing) {
    const id = randomUUID()
    db.prepare(`
      INSERT INTO onboarding (id, user_id, completed, step)
      VALUES (?, ?, 1, -1)
    `).run(id, req.user!.userId)
  } else {
    db.prepare(`
      UPDATE onboarding SET completed = 1, updated_at = datetime('now')
      WHERE user_id = ?
    `).run(req.user!.userId)
  }

  res.json({ completed: true })
})

export default router
