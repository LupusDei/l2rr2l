import { describe, it, expect, beforeEach, afterEach } from 'vitest'
import express from 'express'
import request from 'supertest'
import { db, initializeDb, closeDb } from '../db/index.js'
import authRoutes from './auth.js'

const app = express()
app.use(express.json())
app.use('/auth', authRoutes)

describe('Auth Routes', () => {
  beforeEach(() => {
    initializeDb()
  })

  afterEach(() => {
    db.exec('DELETE FROM users')
  })

  describe('POST /auth/register', () => {
    it('should register a new user', async () => {
      const res = await request(app)
        .post('/auth/register')
        .send({ email: 'test@example.com', password: 'password123', name: 'Test User' })

      expect(res.status).toBe(201)
      expect(res.body.user.email).toBe('test@example.com')
      expect(res.body.user.name).toBe('Test User')
      expect(res.body.token).toBeDefined()
    })

    it('should reject duplicate email', async () => {
      await request(app)
        .post('/auth/register')
        .send({ email: 'test@example.com', password: 'password123', name: 'Test User' })

      const res = await request(app)
        .post('/auth/register')
        .send({ email: 'test@example.com', password: 'password456', name: 'Another User' })

      expect(res.status).toBe(409)
    })

    it('should reject missing fields', async () => {
      const res = await request(app)
        .post('/auth/register')
        .send({ email: 'test@example.com' })

      expect(res.status).toBe(400)
    })
  })

  describe('POST /auth/login', () => {
    beforeEach(async () => {
      await request(app)
        .post('/auth/register')
        .send({ email: 'test@example.com', password: 'password123', name: 'Test User' })
    })

    it('should login with valid credentials', async () => {
      const res = await request(app)
        .post('/auth/login')
        .send({ email: 'test@example.com', password: 'password123' })

      expect(res.status).toBe(200)
      expect(res.body.user.email).toBe('test@example.com')
      expect(res.body.token).toBeDefined()
    })

    it('should reject invalid password', async () => {
      const res = await request(app)
        .post('/auth/login')
        .send({ email: 'test@example.com', password: 'wrongpassword' })

      expect(res.status).toBe(401)
    })

    it('should reject non-existent email', async () => {
      const res = await request(app)
        .post('/auth/login')
        .send({ email: 'nonexistent@example.com', password: 'password123' })

      expect(res.status).toBe(401)
    })
  })

  describe('GET /auth/me', () => {
    it('should return user info with valid token', async () => {
      const registerRes = await request(app)
        .post('/auth/register')
        .send({ email: 'test@example.com', password: 'password123', name: 'Test User' })

      const res = await request(app)
        .get('/auth/me')
        .set('Authorization', `Bearer ${registerRes.body.token}`)

      expect(res.status).toBe(200)
      expect(res.body.user.email).toBe('test@example.com')
    })

    it('should reject without token', async () => {
      const res = await request(app).get('/auth/me')
      expect(res.status).toBe(401)
    })

    it('should reject with invalid token', async () => {
      const res = await request(app)
        .get('/auth/me')
        .set('Authorization', 'Bearer invalid-token')

      expect(res.status).toBe(401)
    })
  })
})
