import { describe, it, expect, beforeEach, afterEach } from 'vitest'
import express from 'express'
import request from 'supertest'
import { db, initializeDb } from '../db/index.js'
import authRoutes from './auth.js'
import childrenRoutes from './children.js'
import voiceRoutes from './voice.js'

const app = express()
app.use(express.json())
app.use('/auth', authRoutes)
app.use('/children', childrenRoutes)
app.use('/api/voice', voiceRoutes)

describe('Voice Settings Routes', () => {
  let token: string
  let childId: string

  beforeEach(async () => {
    initializeDb()

    // Create a user and get token
    const userRes = await request(app)
      .post('/auth/register')
      .send({ email: 'test@example.com', password: 'password123', name: 'Test User' })
    token = userRes.body.token

    // Create a child
    const childRes = await request(app)
      .post('/children')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'Test Child', age: 6 })
    childId = childRes.body.child.id
  })

  afterEach(() => {
    db.exec('DELETE FROM voice_settings')
    db.exec('DELETE FROM children')
    db.exec('DELETE FROM users')
  })

  describe('GET /api/voice/settings/:childId', () => {
    it('should return default settings when none exist', async () => {
      const res = await request(app)
        .get(`/api/voice/settings/${childId}`)

      expect(res.status).toBe(200)
      expect(res.body).toEqual({
        voiceId: 'pMsXgVXv3BLzUgSXRplE',
        stability: 0.5,
        similarityBoost: 0.75,
        style: 0,
        speed: 1.0,
        useSpeakerBoost: true,
      })
    })

    it('should return saved settings when they exist', async () => {
      // First save some settings
      await request(app)
        .put(`/api/voice/settings/${childId}`)
        .send({
          voiceId: 'custom-voice-id',
          stability: 0.8,
          similarityBoost: 0.6,
          style: 0.3,
          speed: 1.5,
          useSpeakerBoost: false,
        })

      const res = await request(app)
        .get(`/api/voice/settings/${childId}`)

      expect(res.status).toBe(200)
      expect(res.body).toEqual({
        voiceId: 'custom-voice-id',
        stability: 0.8,
        similarityBoost: 0.6,
        style: 0.3,
        speed: 1.5,
        useSpeakerBoost: false,
      })
    })
  })

  describe('PUT /api/voice/settings/:childId', () => {
    it('should create settings for new child', async () => {
      const res = await request(app)
        .put(`/api/voice/settings/${childId}`)
        .send({
          voiceId: 'new-voice-id',
          stability: 0.7,
          similarityBoost: 0.8,
          style: 0.2,
          speed: 1.2,
          useSpeakerBoost: true,
        })

      expect(res.status).toBe(200)
      expect(res.body).toEqual({
        voiceId: 'new-voice-id',
        stability: 0.7,
        similarityBoost: 0.8,
        style: 0.2,
        speed: 1.2,
        useSpeakerBoost: true,
      })
    })

    it('should update existing settings', async () => {
      // Create initial settings
      await request(app)
        .put(`/api/voice/settings/${childId}`)
        .send({
          voiceId: 'initial-voice',
          stability: 0.5,
        })

      // Update settings
      const res = await request(app)
        .put(`/api/voice/settings/${childId}`)
        .send({
          stability: 0.9,
          speed: 1.8,
        })

      expect(res.status).toBe(200)
      expect(res.body.voiceId).toBe('initial-voice') // unchanged
      expect(res.body.stability).toBe(0.9) // updated
      expect(res.body.speed).toBe(1.8) // updated
    })

    it('should allow partial updates', async () => {
      // Create initial settings
      await request(app)
        .put(`/api/voice/settings/${childId}`)
        .send({
          voiceId: 'test-voice',
          stability: 0.5,
          similarityBoost: 0.75,
          style: 0,
          speed: 1.0,
          useSpeakerBoost: true,
        })

      // Update only speed
      const res = await request(app)
        .put(`/api/voice/settings/${childId}`)
        .send({ speed: 1.5 })

      expect(res.status).toBe(200)
      expect(res.body.voiceId).toBe('test-voice')
      expect(res.body.stability).toBe(0.5)
      expect(res.body.similarityBoost).toBe(0.75)
      expect(res.body.style).toBe(0)
      expect(res.body.speed).toBe(1.5)
      expect(res.body.useSpeakerBoost).toBe(true)
    })

    it('should reject invalid stability value', async () => {
      const res = await request(app)
        .put(`/api/voice/settings/${childId}`)
        .send({ stability: 1.5 })

      expect(res.status).toBe(400)
      expect(res.body.error).toBe('Invalid voice settings')
      expect(res.body.validationErrors).toContainEqual({
        field: 'stability',
        message: 'stability must be between 0 and 1',
      })
    })

    it('should reject invalid similarityBoost value', async () => {
      const res = await request(app)
        .put(`/api/voice/settings/${childId}`)
        .send({ similarityBoost: -0.5 })

      expect(res.status).toBe(400)
      expect(res.body.error).toBe('Invalid voice settings')
      expect(res.body.validationErrors).toContainEqual({
        field: 'similarityBoost',
        message: 'similarityBoost must be between 0 and 1',
      })
    })

    it('should reject invalid style value', async () => {
      const res = await request(app)
        .put(`/api/voice/settings/${childId}`)
        .send({ style: 2 })

      expect(res.status).toBe(400)
      expect(res.body.validationErrors).toContainEqual({
        field: 'style',
        message: 'style must be between 0 and 1',
      })
    })

    it('should reject invalid speed value', async () => {
      const res = await request(app)
        .put(`/api/voice/settings/${childId}`)
        .send({ speed: 3.0 })

      expect(res.status).toBe(400)
      expect(res.body.validationErrors).toContainEqual({
        field: 'speed',
        message: 'speed must be between 0.5 and 2.0',
      })
    })

    it('should reject speed below minimum', async () => {
      const res = await request(app)
        .put(`/api/voice/settings/${childId}`)
        .send({ speed: 0.3 })

      expect(res.status).toBe(400)
      expect(res.body.validationErrors).toContainEqual({
        field: 'speed',
        message: 'speed must be between 0.5 and 2.0',
      })
    })

    it('should report multiple validation errors', async () => {
      const res = await request(app)
        .put(`/api/voice/settings/${childId}`)
        .send({
          stability: -1,
          similarityBoost: 2,
          style: 5,
          speed: 10,
        })

      expect(res.status).toBe(400)
      expect(res.body.validationErrors).toHaveLength(4)
    })
  })
})
