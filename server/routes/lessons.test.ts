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
    db.exec('DELETE FROM lesson_engagement')
    db.exec('DELETE FROM lesson_ratings')
    db.exec('DELETE FROM lessons')
  })

  describe('POST /lessons', () => {
    it('should create a lesson with all fields', async () => {
      const res = await request(app)
        .post('/lessons')
        .send({
          title: 'Introduction to Addition',
          subject: 'Math',
          description: 'Learn the basics of adding numbers',
          gradeLevel: '1st',
          difficulty: 'beginner',
          durationMinutes: 30,
          ageMin: 5,
          ageMax: 7,
          learningStyles: ['visual', 'kinesthetic'],
          interests: ['numbers', 'puzzles'],
          objectives: [{ description: 'Understand addition', measurable: true }],
          activities: [
            { order: 1, title: 'Counting blocks', instructions: 'Use blocks to count', duration_minutes: 10 }
          ],
          materials: ['blocks', 'worksheet'],
          assessmentCriteria: [
            { type: 'observation', description: 'Can add single digits', success_indicators: ['accurate', 'confident'] }
          ],
          source: 'curated',
          tags: ['math', 'addition', 'beginner']
        })

      expect(res.status).toBe(201)
      expect(res.body.lesson.title).toBe('Introduction to Addition')
      expect(res.body.lesson.subject).toBe('Math')
      expect(res.body.lesson.description).toBe('Learn the basics of adding numbers')
      expect(res.body.lesson.age_min).toBe(5)
      expect(res.body.lesson.age_max).toBe(7)
      expect(res.body.lesson.learning_styles).toEqual(['visual', 'kinesthetic'])
      expect(res.body.lesson.interests).toEqual(['numbers', 'puzzles'])
      expect(res.body.lesson.materials).toEqual(['blocks', 'worksheet'])
      expect(res.body.lesson.source).toBe('curated')
      expect(res.body.lesson.tags).toEqual(['math', 'addition', 'beginner'])
    })

    it('should create a lesson with minimal fields', async () => {
      const res = await request(app)
        .post('/lessons')
        .send({
          title: 'Simple Lesson',
          subject: 'Math'
        })

      expect(res.status).toBe(201)
      expect(res.body.lesson.title).toBe('Simple Lesson')
      expect(res.body.lesson.source).toBe('curated')
      expect(res.body.lesson.is_published).toBe(true)
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
      await request(app).post('/lessons').send({
        title: 'Math 1',
        subject: 'Math',
        gradeLevel: '1st',
        ageMin: 5,
        ageMax: 7,
        learningStyles: ['visual'],
        interests: ['numbers']
      })
      await request(app).post('/lessons').send({
        title: 'Math 2',
        subject: 'Math',
        gradeLevel: '2nd',
        ageMin: 6,
        ageMax: 8,
        learningStyles: ['auditory'],
        interests: ['puzzles']
      })
      await request(app).post('/lessons').send({
        title: 'Science 1',
        subject: 'Science',
        gradeLevel: '1st',
        ageMin: 5,
        ageMax: 7,
        learningStyles: ['kinesthetic'],
        interests: ['animals']
      })
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

    it('should filter by age range', async () => {
      const res = await request(app).get('/lessons?ageMin=6&ageMax=6')

      expect(res.status).toBe(200)
      expect(res.body.lessons).toHaveLength(3)
    })

    it('should filter by learning style', async () => {
      const res = await request(app).get('/lessons?learningStyles=visual')

      expect(res.status).toBe(200)
      expect(res.body.lessons).toHaveLength(1)
      expect(res.body.lessons[0].title).toBe('Math 1')
    })

    it('should filter by interests', async () => {
      const res = await request(app).get('/lessons?interests=animals')

      expect(res.status).toBe(200)
      expect(res.body.lessons).toHaveLength(1)
      expect(res.body.lessons[0].title).toBe('Science 1')
    })

    it('should search by query', async () => {
      const res = await request(app).get('/lessons?query=Science')

      expect(res.status).toBe(200)
      expect(res.body.lessons).toHaveLength(1)
      expect(res.body.lessons[0].subject).toBe('Science')
    })

    it('should search with partial word match', async () => {
      const res = await request(app).get('/lessons?query=Sci')

      expect(res.status).toBe(200)
      expect(res.body.lessons).toHaveLength(1)
      expect(res.body.lessons[0].subject).toBe('Science')
    })

    it('should search case-insensitively', async () => {
      const res = await request(app).get('/lessons?query=science')

      expect(res.status).toBe(200)
      expect(res.body.lessons).toHaveLength(1)
    })
  })

  describe('GET /lessons/search', () => {
    beforeEach(async () => {
      await request(app).post('/lessons').send({
        title: 'Introduction to Fractions',
        subject: 'Math',
        description: 'Learn how fractions work with visual examples'
      })
      await request(app).post('/lessons').send({
        title: 'Basic Addition',
        subject: 'Math',
        description: 'Adding numbers together'
      })
      await request(app).post('/lessons').send({
        title: 'Dinosaur Facts',
        subject: 'Science',
        description: 'Explore the prehistoric world of dinosaurs'
      })
    })

    it('should require a search query', async () => {
      const res = await request(app).get('/lessons/search')

      expect(res.status).toBe(400)
      expect(res.body.error).toContain('required')
    })

    it('should return matching lessons ranked by relevance', async () => {
      const res = await request(app).get('/lessons/search?q=fractions')

      expect(res.status).toBe(200)
      expect(res.body.lessons).toHaveLength(1)
      expect(res.body.lessons[0].title).toBe('Introduction to Fractions')
    })

    it('should search across title and description', async () => {
      const res = await request(app).get('/lessons/search?q=prehistoric')

      expect(res.status).toBe(200)
      expect(res.body.lessons).toHaveLength(1)
      expect(res.body.lessons[0].title).toBe('Dinosaur Facts')
    })

    it('should support prefix matching', async () => {
      const res = await request(app).get('/lessons/search?q=dino')

      expect(res.status).toBe(200)
      expect(res.body.lessons).toHaveLength(1)
      expect(res.body.lessons[0].title).toBe('Dinosaur Facts')
    })

    it('should handle multi-word queries', async () => {
      const res = await request(app).get('/lessons/search?q=visual examples')

      expect(res.status).toBe(200)
      expect(res.body.lessons).toHaveLength(1)
      expect(res.body.lessons[0].title).toBe('Introduction to Fractions')
    })

    it('should return empty results for no matches', async () => {
      const res = await request(app).get('/lessons/search?q=zzzznonexistent')

      expect(res.status).toBe(200)
      expect(res.body.lessons).toHaveLength(0)
      expect(res.body.total).toBe(0)
    })

    it('should support pagination', async () => {
      const res = await request(app).get('/lessons/search?q=math&limit=1&offset=0')

      expect(res.status).toBe(200)
      expect(res.body.lessons).toHaveLength(1)
      expect(res.body.total).toBe(2)
      expect(res.body.limit).toBe(1)
      expect(res.body.offset).toBe(0)
    })
  })

  describe('GET /lessons/filters', () => {
    beforeEach(async () => {
      await request(app).post('/lessons').send({
        title: 'Math 1',
        subject: 'Math',
        gradeLevel: '1st',
        ageMin: 5,
        ageMax: 7
      })
      await request(app).post('/lessons').send({
        title: 'Science 1',
        subject: 'Science',
        gradeLevel: '2nd',
        ageMin: 6,
        ageMax: 10
      })
    })

    it('should return available filter options', async () => {
      const res = await request(app).get('/lessons/filters')

      expect(res.status).toBe(200)
      expect(res.body.subjects).toContain('Math')
      expect(res.body.subjects).toContain('Science')
      expect(res.body.gradeLevels).toContain('1st')
      expect(res.body.gradeLevels).toContain('2nd')
      expect(res.body.difficulties).toContain('beginner')
      expect(res.body.learningStyles).toContain('visual')
      expect(res.body.ageRange.min).toBe(5)
      expect(res.body.ageRange.max).toBe(10)
    })
  })

  describe('GET /lessons/:id', () => {
    let lessonId: string

    beforeEach(async () => {
      const res = await request(app)
        .post('/lessons')
        .send({
          title: 'Test Lesson',
          subject: 'Math',
          learningStyles: ['visual'],
          activities: [{ order: 1, title: 'Activity 1', instructions: 'Do something' }]
        })
      lessonId = res.body.lesson.id
    })

    it('should get a lesson by id', async () => {
      const res = await request(app).get(`/lessons/${lessonId}`)

      expect(res.status).toBe(200)
      expect(res.body.lesson.title).toBe('Test Lesson')
      expect(res.body.lesson.learning_styles).toEqual(['visual'])
      expect(res.body.lesson.activities).toHaveLength(1)
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

      const authRes = await request(app)
        .post('/auth/register')
        .send({ email: 'parent@example.com', password: 'password123', name: 'Parent User' })
      token = authRes.body.token
      const userId = authRes.body.user.id

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

  describe('PUT /lessons/:id', () => {
    let lessonId: string

    beforeEach(async () => {
      const res = await request(app)
        .post('/lessons')
        .send({ title: 'Original', subject: 'Math' })
      lessonId = res.body.lesson.id
    })

    it('should update lesson fields', async () => {
      const res = await request(app)
        .put(`/lessons/${lessonId}`)
        .send({
          title: 'Updated',
          learningStyles: ['auditory', 'kinesthetic'],
          ageMin: 6,
          ageMax: 9
        })

      expect(res.status).toBe(200)
      expect(res.body.lesson.title).toBe('Updated')
      expect(res.body.lesson.learning_styles).toEqual(['auditory', 'kinesthetic'])
      expect(res.body.lesson.age_min).toBe(6)
      expect(res.body.lesson.age_max).toBe(9)
    })
  })

  describe('DELETE /lessons/:id', () => {
    let lessonId: string

    beforeEach(async () => {
      const res = await request(app)
        .post('/lessons')
        .send({ title: 'To Delete', subject: 'Math' })
      lessonId = res.body.lesson.id
    })

    it('should delete a lesson', async () => {
      const res = await request(app).delete(`/lessons/${lessonId}`)

      expect(res.status).toBe(204)

      const getRes = await request(app).get(`/lessons/${lessonId}`)
      expect(getRes.status).toBe(404)
    })
  })
})
