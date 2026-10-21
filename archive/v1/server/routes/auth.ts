import { Router } from 'express'
import bcrypt from 'bcrypt'
import { randomUUID } from 'crypto'
import { db } from '../db/index.js'
import { generateToken, authMiddleware, AuthenticatedRequest } from '../middleware/auth.js'

const router = Router()

interface UserRow {
  id: string
  email: string
  password_hash: string
  name: string
  created_at: string
  updated_at: string
}

router.post('/register', async (req, res) => {
  const { email, password, name } = req.body

  if (!email || !password || !name) {
    res.status(400).json({ error: 'Email, password, and name are required' })
    return
  }

  try {
    const existing = db.prepare('SELECT id FROM users WHERE email = ?').get(email) as UserRow | undefined
    if (existing) {
      res.status(409).json({ error: 'Email already registered' })
      return
    }

    const id = randomUUID()
    const passwordHash = await bcrypt.hash(password, 10)

    db.prepare(
      'INSERT INTO users (id, email, password_hash, name) VALUES (?, ?, ?, ?)'
    ).run(id, email, passwordHash, name)

    const token = generateToken({ userId: id, email })

    res.status(201).json({
      user: { id, email, name },
      token
    })
  } catch (error) {
    console.error('Registration error:', error)
    res.status(500).json({ error: 'Registration failed' })
  }
})

router.post('/login', async (req, res) => {
  const { email, password } = req.body

  if (!email || !password) {
    res.status(400).json({ error: 'Email and password are required' })
    return
  }

  try {
    const user = db.prepare('SELECT * FROM users WHERE email = ?').get(email) as UserRow | undefined

    if (!user) {
      res.status(401).json({ error: 'Invalid credentials' })
      return
    }

    const validPassword = await bcrypt.compare(password, user.password_hash)
    if (!validPassword) {
      res.status(401).json({ error: 'Invalid credentials' })
      return
    }

    const token = generateToken({ userId: user.id, email: user.email })

    res.json({
      user: { id: user.id, email: user.email, name: user.name },
      token
    })
  } catch (error) {
    console.error('Login error:', error)
    res.status(500).json({ error: 'Login failed' })
  }
})

router.get('/me', authMiddleware, (req: AuthenticatedRequest, res) => {
  const user = db.prepare('SELECT id, email, name, created_at FROM users WHERE id = ?')
    .get(req.user!.userId) as Omit<UserRow, 'password_hash' | 'updated_at'> | undefined

  if (!user) {
    res.status(404).json({ error: 'User not found' })
    return
  }

  res.json({ user })
})

export default router
