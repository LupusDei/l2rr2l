import { describe, it, expect, beforeEach, afterEach } from 'vitest'
import express from 'express'
import request from 'supertest'
import { db, initializeDb } from '../db/index.js'
import lessonsRoutes from './lessons.js'

const app = express()
app.use(express.json())
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
})
