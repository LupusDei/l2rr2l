import { describe, it, expect, beforeEach, afterEach } from 'vitest'
import express from 'express'
import request from 'supertest'
import { db, initializeDb } from '../db/index.js'
import authRoutes from './auth.js'
import childrenRoutes from './children.js'

const app = express()
app.use(express.json())
app.use('/auth', authRoutes)
app.use('/children', childrenRoutes)

describe('Children Routes', () => {
  let token: string

  beforeEach(async () => {
    initializeDb()
    const res = await request(app)
      .post('/auth/register')
      .send({ email: 'parent@example.com', password: 'password123', name: 'Parent User' })
    token = res.body.token
  })

  afterEach(() => {
    db.exec('DELETE FROM children')
    db.exec('DELETE FROM users')
  })

  describe('POST /children', () => {
    it('should create a child profile', async () => {
      const res = await request(app)
        .post('/children')
        .set('Authorization', `Bearer ${token}`)
        .send({
          name: 'Child Name',
          age: 8,
          gradeLevel: '3rd',
          learningStyle: 'visual',
          interests: ['math', 'science']
        })

      expect(res.status).toBe(201)
      expect(res.body.child.name).toBe('Child Name')
      expect(res.body.child.age).toBe(8)
      expect(res.body.child.interests).toEqual(['math', 'science'])
    })

    it('should reject without auth', async () => {
      const res = await request(app)
        .post('/children')
        .send({ name: 'Child Name' })

      expect(res.status).toBe(401)
    })
  })

  describe('GET /children', () => {
    beforeEach(async () => {
      await request(app)
        .post('/children')
        .set('Authorization', `Bearer ${token}`)
        .send({ name: 'Child 1', age: 7 })

      await request(app)
        .post('/children')
        .set('Authorization', `Bearer ${token}`)
        .send({ name: 'Child 2', age: 10 })
    })

    it('should list all children for user', async () => {
      const res = await request(app)
        .get('/children')
        .set('Authorization', `Bearer ${token}`)

      expect(res.status).toBe(200)
      expect(res.body.children).toHaveLength(2)
    })
  })

  describe('PUT /children/:id', () => {
    let childId: string

    beforeEach(async () => {
      const res = await request(app)
        .post('/children')
        .set('Authorization', `Bearer ${token}`)
        .send({ name: 'Original Name', age: 8 })
      childId = res.body.child.id
    })

    it('should update child profile', async () => {
      const res = await request(app)
        .put(`/children/${childId}`)
        .set('Authorization', `Bearer ${token}`)
        .send({ name: 'Updated Name', age: 9 })

      expect(res.status).toBe(200)
      expect(res.body.child.name).toBe('Updated Name')
      expect(res.body.child.age).toBe(9)
    })
  })

  describe('DELETE /children/:id', () => {
    let childId: string

    beforeEach(async () => {
      const res = await request(app)
        .post('/children')
        .set('Authorization', `Bearer ${token}`)
        .send({ name: 'Child to Delete' })
      childId = res.body.child.id
    })

    it('should delete child profile', async () => {
      const res = await request(app)
        .delete(`/children/${childId}`)
        .set('Authorization', `Bearer ${token}`)

      expect(res.status).toBe(204)

      const getRes = await request(app)
        .get(`/children/${childId}`)
        .set('Authorization', `Bearer ${token}`)

      expect(getRes.status).toBe(404)
    })
  })
})
