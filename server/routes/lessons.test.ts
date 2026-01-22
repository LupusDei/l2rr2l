import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import express from 'express'
import request from 'supertest'
import { db, initializeDb } from '../db/index.js'
import lessonsRoutes from './lessons.js'
import authRoutes from './auth.js'

const app = express()
app.use(express.json())
app.use('/auth', authRoutes)
app.use('/lessons', lessonsRoutes)

describe('Lessons Routes', () => {
  beforeEach(() => {
    initializeDb()
  })

  afterEach(() => {
    db.exec('DELETE FROM lessons')
  })

  describe('POST /lessons', () => {
    it('should create a lesson', async () => {
      const res = await request(app)
        .post('/lessons')
        .send({
          title: 'Introduction to Addition',
          subject: 'Math',
          gradeLevel: '1st',
          difficulty: 'beginner',
          durationMinutes: 30,
          content: { sections: ['intro', 'practice', 'review'] },
          objectives: ['Understand addition', 'Add single digits']
        })

      expect(res.status).toBe(201)
      expect(res.body.lesson.title).toBe('Introduction to Addition')
      expect(res.body.lesson.subject).toBe('Math')
      expect(res.body.lesson.objectives).toEqual(['Understand addition', 'Add single digits'])
    })

    it('should reject missing required fields', async () => {
      const res = await request(app)
        .post('/lessons')
        .send({ title: 'No Subject' })

      expect(res.status).toBe(400)
    })
  })

  describe('GET /lessons', () => {
    beforeEach(async () => {
      await request(app).post('/lessons').send({ title: 'Math 1', subject: 'Math', gradeLevel: '1st' })
      await request(app).post('/lessons').send({ title: 'Math 2', subject: 'Math', gradeLevel: '2nd' })
      await request(app).post('/lessons').send({ title: 'Science 1', subject: 'Science', gradeLevel: '1st' })
    })

    it('should list all lessons', async () => {
      const res = await request(app).get('/lessons')

      expect(res.status).toBe(200)
      expect(res.body.lessons).toHaveLength(3)
      expect(res.body.total).toBe(3)
    })

    it('should filter by subject', async () => {
      const res = await request(app).get('/lessons?subject=Math')

      expect(res.status).toBe(200)
      expect(res.body.lessons).toHaveLength(2)
      expect(res.body.lessons.every((l: { subject: string }) => l.subject === 'Math')).toBe(true)
    })

    it('should filter by grade level', async () => {
      const res = await request(app).get('/lessons?gradeLevel=1st')

      expect(res.status).toBe(200)
      expect(res.body.lessons).toHaveLength(2)
    })
  })

  describe('GET /lessons/:id', () => {
    let lessonId: string

    beforeEach(async () => {
      const res = await request(app)
        .post('/lessons')
        .send({ title: 'Test Lesson', subject: 'Math' })
      lessonId = res.body.lesson.id
    })

    it('should get a lesson by id', async () => {
      const res = await request(app).get(`/lessons/${lessonId}`)

      expect(res.status).toBe(200)
      expect(res.body.lesson.title).toBe('Test Lesson')
    })

    it('should return 404 for non-existent lesson', async () => {
      const res = await request(app).get('/lessons/non-existent-id')

      expect(res.status).toBe(404)
    })
  })

  describe('GET /lessons/subjects', () => {
    beforeEach(async () => {
      await request(app).post('/lessons').send({ title: 'Math 1', subject: 'Math' })
      await request(app).post('/lessons').send({ title: 'Science 1', subject: 'Science' })
      await request(app).post('/lessons').send({ title: 'Math 2', subject: 'Math' })
    })

    it('should return unique subjects', async () => {
      const res = await request(app).get('/lessons/subjects')

      expect(res.status).toBe(200)
      expect(res.body.subjects).toContain('Math')
      expect(res.body.subjects).toContain('Science')
      expect(res.body.subjects).toHaveLength(2)
    })
  })

  describe('GET /lessons/supported-subjects', () => {
    it('should return supported subjects for AI generation', async () => {
      const res = await request(app).get('/lessons/supported-subjects')

      expect(res.status).toBe(200)
      expect(res.body.subjects).toContain('reading')
      expect(res.body.subjects).toContain('math')
      expect(res.body.subjects).toContain('science')
    })
  })

  describe('POST /lessons/generate', () => {
    let token: string
    let childId: string
    const originalFetch = global.fetch
    const originalEnv = process.env

    const mockLessonResponse = {
      title: 'Fun with Numbers',
      subject: 'math',
      gradeLevel: '1st grade',
      difficulty: 'easy',
      durationMinutes: 30,
      objectives: ['Count to 10', 'Recognize numbers'],
      activities: [{
        step: 1,
        title: 'Counting Game',
        instructions: 'Count objects together',
        durationMinutes: 10,
        type: 'practice'
      }],
      materials: ['Blocks'],
      assessmentCriteria: ['Can count to 10']
    }

    beforeEach(async () => {
      process.env = { ...originalEnv }
      process.env.XAI_API_KEY = 'test-key'

      // Mock fetch for AI API
      global.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: async () => ({
          choices: [{
            message: {
              content: JSON.stringify(mockLessonResponse)
            }
          }]
        })
      })

      // Register user and get token
      const authRes = await request(app)
        .post('/auth/register')
        .send({ email: 'parent@example.com', password: 'password123', name: 'Parent User' })
      token = authRes.body.token
      const userId = authRes.body.user.id

      // Create a child
      const childResult = db.prepare(`
        INSERT INTO children (id, user_id, name, age, grade_level, learning_style, interests)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      `).run('child-1', userId, 'Emma', 7, '1st grade', 'visual', JSON.stringify(['dinosaurs']))
      childId = 'child-1'
    })

    afterEach(() => {
      global.fetch = originalFetch
      process.env = originalEnv
      db.exec('DELETE FROM children')
      db.exec('DELETE FROM users')
    })

    it('should require authentication', async () => {
      const res = await request(app)
        .post('/lessons/generate')
        .send({ childId: 'child-1', subject: 'math' })

      expect(res.status).toBe(401)
    })

    it('should require childId and subject', async () => {
      const res = await request(app)
        .post('/lessons/generate')
        .set('Authorization', `Bearer ${token}`)
        .send({ subject: 'math' })

      expect(res.status).toBe(400)
      expect(res.body.error).toContain('childId')
    })

    it('should reject if child not found', async () => {
      const res = await request(app)
        .post('/lessons/generate')
        .set('Authorization', `Bearer ${token}`)
        .send({ childId: 'non-existent', subject: 'math' })

      expect(res.status).toBe(404)
      expect(res.body.error).toBe('Child not found')
    })

    it('should generate a lesson for a child', async () => {
      const res = await request(app)
        .post('/lessons/generate')
        .set('Authorization', `Bearer ${token}`)
        .send({ childId, subject: 'math' })

      expect(res.status).toBe(201)
      expect(res.body.lesson.title).toBe('Fun with Numbers')
      expect(res.body.lesson.subject).toBe('math')
      expect(res.body.lesson.source).toBe('ai-generated')
      expect(res.body.lesson.objectives).toHaveLength(2)
      expect(res.body.lesson.activities).toHaveLength(1)
    })

    it('should save lesson to library when requested', async () => {
      const res = await request(app)
        .post('/lessons/generate')
        .set('Authorization', `Bearer ${token}`)
        .send({ childId, subject: 'math', saveToLibrary: true })

      expect(res.status).toBe(201)

      // Verify it was saved
      const savedLesson = db.prepare('SELECT * FROM lessons WHERE id = ?')
        .get(res.body.lesson.id) as { title: string } | undefined

      expect(savedLesson).toBeDefined()
      expect(savedLesson?.title).toBe('Fun with Numbers')
    })

    it('should not save lesson to library by default', async () => {
      const initialCount = (db.prepare('SELECT COUNT(*) as count FROM lessons').get() as { count: number }).count

      await request(app)
        .post('/lessons/generate')
        .set('Authorization', `Bearer ${token}`)
        .send({ childId, subject: 'math' })

      const finalCount = (db.prepare('SELECT COUNT(*) as count FROM lessons').get() as { count: number }).count

      expect(finalCount).toBe(initialCount)
    })

    it('should pass topic and duration to AI', async () => {
      await request(app)
        .post('/lessons/generate')
        .set('Authorization', `Bearer ${token}`)
        .send({ childId, subject: 'math', topic: 'multiplication', preferredDuration: 45 })

      expect(global.fetch).toHaveBeenCalled()
      const fetchCall = (global.fetch as ReturnType<typeof vi.fn>).mock.calls[0]
      const body = JSON.parse(fetchCall[1].body)
      expect(body.messages[1].content).toContain('multiplication')
      expect(body.messages[1].content).toContain('45 minutes')
    })
  })
})
