import { describe, it, expect, vi, beforeEach } from 'vitest'
import { handleLessons } from './lessons'
import type { Env, D1Database } from '../../types'

// Mock D1 database
function createMockDB(): D1Database {
  const mockResults: Record<string, unknown[]> = {}
  const mockFirst: Record<string, unknown> = {}

  return {
    prepare: vi.fn((sql: string) => ({
      bind: vi.fn().mockReturnThis(),
      all: vi.fn().mockResolvedValue({
        results: mockResults[sql] || [],
        success: true,
      }),
      first: vi.fn().mockResolvedValue(mockFirst[sql] || null),
      run: vi.fn().mockResolvedValue({
        success: true,
        meta: { changes: 1, duration: 0, last_row_id: 0, served_by: 'test' }
      }),
      raw: vi.fn().mockResolvedValue([]),
    })),
    dump: vi.fn().mockResolvedValue(new ArrayBuffer(0)),
    batch: vi.fn().mockResolvedValue([]),
    exec: vi.fn().mockResolvedValue({ count: 0, duration: 0 }),
  } as unknown as D1Database
}

function createMockEnv(db = createMockDB()): Env {
  return {
    DB: db,
    ELEVENLABS_API_KEY: 'test-key',
    JWT_SECRET: 'test-secret',
    ENVIRONMENT: 'test',
  }
}

function createMockRequest(
  method: string,
  url: string,
  body?: unknown
): Request {
  const options: RequestInit = {
    method,
    headers: { 'Content-Type': 'application/json' },
  }
  if (body) {
    options.body = JSON.stringify(body)
  }
  return new Request(url, options)
}

describe('handleLessons', () => {
  let mockDB: D1Database & { prepare: ReturnType<typeof vi.fn> }
  let env: Env

  beforeEach(() => {
    vi.clearAllMocks()
    mockDB = createMockDB() as D1Database & { prepare: ReturnType<typeof vi.fn> }
    env = createMockEnv(mockDB)
  })

  describe('GET /api/lessons', () => {
    it('returns list of lessons', async () => {
      const request = createMockRequest('GET', 'http://localhost/api/lessons')

      const response = await handleLessons(request, env, [])

      expect(response.status).toBe(200)
      const data = await response.json()
      expect(data).toHaveProperty('lessons')
      expect(data).toHaveProperty('total')
      expect(data).toHaveProperty('limit')
      expect(data).toHaveProperty('offset')
    })

    it('filters by subject when provided', async () => {
      const request = createMockRequest(
        'GET',
        'http://localhost/api/lessons?subject=phonics'
      )

      await handleLessons(request, env, [])

      // Verify the SQL query included subject filter
      expect(mockDB.prepare).toHaveBeenCalled()
      const calls = mockDB.prepare.mock.calls
      const selectCall = calls.find((c: string[]) => c[0].includes('SELECT'))
      expect(selectCall?.[0]).toContain('subject = ?')
    })

    it('filters by difficulty when provided', async () => {
      const request = createMockRequest(
        'GET',
        'http://localhost/api/lessons?difficulty=beginner'
      )

      await handleLessons(request, env, [])

      expect(mockDB.prepare).toHaveBeenCalled()
      const calls = mockDB.prepare.mock.calls
      const selectCall = calls.find((c: string[]) => c[0].includes('SELECT'))
      expect(selectCall?.[0]).toContain('difficulty = ?')
    })

    it('applies pagination with limit and offset', async () => {
      const request = createMockRequest(
        'GET',
        'http://localhost/api/lessons?limit=10&offset=20'
      )

      const response = await handleLessons(request, env, [])
      const data = await response.json() as { limit: number; offset: number }

      expect(data.limit).toBe(10)
      expect(data.offset).toBe(20)
    })
  })

  describe('GET /api/lessons/:id', () => {
    it('returns 404 when lesson not found', async () => {
      const request = createMockRequest(
        'GET',
        'http://localhost/api/lessons/nonexistent'
      )

      const response = await handleLessons(request, env, ['nonexistent'])

      expect(response.status).toBe(404)
      const data = await response.json() as { error: string }
      expect(data.error).toBe('Lesson not found')
    })
  })

  describe('POST /api/lessons', () => {
    it('creates a new lesson with required fields', async () => {
      const request = createMockRequest(
        'POST',
        'http://localhost/api/lessons',
        { title: 'Test Lesson', subject: 'phonics' }
      )

      // Mock the SELECT after INSERT
      mockDB.prepare = vi.fn((sql: string) => ({
        bind: vi.fn().mockReturnThis(),
        all: vi.fn().mockResolvedValue({ results: [], success: true }),
        first: vi.fn().mockResolvedValue(
          sql.includes('SELECT') ? {
            id: 'test-id',
            title: 'Test Lesson',
            subject: 'phonics',
            description: null,
            source: 'curated',
            is_published: 1,
            created_at: '2026-01-24',
            updated_at: '2026-01-24',
          } : null
        ),
        run: vi.fn().mockResolvedValue({
          success: true,
          meta: { changes: 1, duration: 0, last_row_id: 0, served_by: 'test' }
        }),
        raw: vi.fn().mockResolvedValue([]),
      }))
      env = createMockEnv(mockDB)

      const response = await handleLessons(request, env, [])

      expect(response.status).toBe(201)
      const data = await response.json() as { lesson: { id: string; title: string; subject: string } }
      expect(data.lesson).toHaveProperty('id')
      expect(data.lesson.title).toBe('Test Lesson')
      expect(data.lesson.subject).toBe('phonics')
    })

    it('returns 400 when title is missing', async () => {
      const request = createMockRequest(
        'POST',
        'http://localhost/api/lessons',
        { subject: 'phonics' }
      )

      const response = await handleLessons(request, env, [])

      expect(response.status).toBe(400)
      const data = await response.json() as { error: string }
      expect(data.error).toContain('required')
    })

    it('returns 400 when subject is missing', async () => {
      const request = createMockRequest(
        'POST',
        'http://localhost/api/lessons',
        { title: 'Test Lesson' }
      )

      const response = await handleLessons(request, env, [])

      expect(response.status).toBe(400)
      const data = await response.json() as { error: string }
      expect(data.error).toContain('required')
    })
  })

  describe('PUT /api/lessons/:id', () => {
    it('returns 404 when lesson not found', async () => {
      const request = createMockRequest(
        'PUT',
        'http://localhost/api/lessons/nonexistent',
        { title: 'Updated Title' }
      )

      const response = await handleLessons(request, env, ['nonexistent'])

      expect(response.status).toBe(404)
    })

    it('updates lesson when found', async () => {
      // Mock lesson exists
      mockDB.prepare = vi.fn((sql: string) => ({
        bind: vi.fn().mockReturnThis(),
        all: vi.fn().mockResolvedValue({ results: [], success: true }),
        first: vi.fn().mockResolvedValue(
          sql.includes('SELECT') ? {
            id: 'lesson-1',
            title: 'Updated Title',
            subject: 'phonics',
            description: null,
            source: 'curated',
            is_published: 1,
            created_at: '2026-01-24',
            updated_at: '2026-01-24',
          } : null
        ),
        run: vi.fn().mockResolvedValue({
          success: true,
          meta: { changes: 1, duration: 0, last_row_id: 0, served_by: 'test' }
        }),
        raw: vi.fn().mockResolvedValue([]),
      }))
      env = createMockEnv(mockDB)

      const request = createMockRequest(
        'PUT',
        'http://localhost/api/lessons/lesson-1',
        { title: 'Updated Title' }
      )

      const response = await handleLessons(request, env, ['lesson-1'])

      expect(response.status).toBe(200)
      const data = await response.json() as { lesson: { title: string } }
      expect(data.lesson.title).toBe('Updated Title')
    })
  })

  describe('DELETE /api/lessons/:id', () => {
    it('returns 404 when lesson not found', async () => {
      mockDB.prepare = vi.fn(() => ({
        bind: vi.fn().mockReturnThis(),
        all: vi.fn().mockResolvedValue({ results: [], success: true }),
        first: vi.fn().mockResolvedValue(null),
        run: vi.fn().mockResolvedValue({
          success: true,
          meta: { changes: 0, duration: 0, last_row_id: 0, served_by: 'test' }
        }),
        raw: vi.fn().mockResolvedValue([]),
      }))
      env = createMockEnv(mockDB)

      const request = createMockRequest(
        'DELETE',
        'http://localhost/api/lessons/nonexistent'
      )

      const response = await handleLessons(request, env, ['nonexistent'])

      expect(response.status).toBe(404)
    })

    it('returns 204 on successful deletion', async () => {
      mockDB.prepare = vi.fn(() => ({
        bind: vi.fn().mockReturnThis(),
        all: vi.fn().mockResolvedValue({ results: [], success: true }),
        first: vi.fn().mockResolvedValue(null),
        run: vi.fn().mockResolvedValue({
          success: true,
          meta: { changes: 1, duration: 0, last_row_id: 0, served_by: 'test' }
        }),
        raw: vi.fn().mockResolvedValue([]),
      }))
      env = createMockEnv(mockDB)

      const request = createMockRequest(
        'DELETE',
        'http://localhost/api/lessons/lesson-1'
      )

      const response = await handleLessons(request, env, ['lesson-1'])

      expect(response.status).toBe(204)
    })
  })

  describe('GET /api/lessons/subjects', () => {
    it('returns list of distinct subjects', async () => {
      mockDB.prepare = vi.fn(() => ({
        bind: vi.fn().mockReturnThis(),
        all: vi.fn().mockResolvedValue({
          results: [
            { subject: 'phonics' },
            { subject: 'reading' },
            { subject: 'spelling' },
          ],
          success: true,
        }),
        first: vi.fn().mockResolvedValue(null),
        run: vi.fn().mockResolvedValue({
          success: true,
          meta: { changes: 0, duration: 0, last_row_id: 0, served_by: 'test' }
        }),
        raw: vi.fn().mockResolvedValue([]),
      }))
      env = createMockEnv(mockDB)

      const request = createMockRequest(
        'GET',
        'http://localhost/api/lessons/subjects'
      )

      const response = await handleLessons(request, env, ['subjects'])

      expect(response.status).toBe(200)
      const data = await response.json() as { subjects: string[] }
      expect(data.subjects).toEqual(['phonics', 'reading', 'spelling'])
    })
  })

  describe('GET /api/lessons/filters', () => {
    it('returns available filter options', async () => {
      const request = createMockRequest(
        'GET',
        'http://localhost/api/lessons/filters'
      )

      const response = await handleLessons(request, env, ['filters'])

      expect(response.status).toBe(200)
      const data = await response.json() as {
        subjects: string[]
        difficulties: string[]
        sources: string[]
        learningStyles: string[]
      }
      expect(data).toHaveProperty('subjects')
      expect(data).toHaveProperty('difficulties')
      expect(data).toHaveProperty('sources')
      expect(data).toHaveProperty('learningStyles')
      expect(data.difficulties).toContain('beginner')
      expect(data.difficulties).toContain('advanced')
    })
  })

  describe('GET /api/lessons/search', () => {
    it('returns 400 when query is missing', async () => {
      const request = createMockRequest(
        'GET',
        'http://localhost/api/lessons/search'
      )

      const response = await handleLessons(request, env, ['search'])

      expect(response.status).toBe(400)
      const data = await response.json() as { error: string }
      expect(data.error).toContain('query')
    })

    it('returns search results when query provided', async () => {
      const request = createMockRequest(
        'GET',
        'http://localhost/api/lessons/search?q=phonics'
      )

      const response = await handleLessons(request, env, ['search'])

      expect(response.status).toBe(200)
      const data = await response.json() as { lessons: unknown[]; total: number }
      expect(data).toHaveProperty('lessons')
      expect(data).toHaveProperty('total')
    })
  })

  describe('unsupported methods', () => {
    it('returns 405 for unsupported methods', async () => {
      const request = createMockRequest(
        'PATCH',
        'http://localhost/api/lessons'
      )

      const response = await handleLessons(request, env, [])

      expect(response.status).toBe(405)
    })
  })
})
