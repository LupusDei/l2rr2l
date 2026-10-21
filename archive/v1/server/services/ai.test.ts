import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { generateLesson, getSupportedSubjects, ChildProfile, LessonGenerationRequest } from './ai.js'

describe('AI Service', () => {
  const mockChildProfile: ChildProfile = {
    name: 'Emma',
    age: 7,
    gradeLevel: '2nd grade',
    learningStyle: 'visual',
    interests: ['dinosaurs', 'space', 'art']
  }

  const mockLessonResponse = {
    title: 'Counting with Dinosaurs',
    subject: 'math',
    gradeLevel: '2nd grade',
    difficulty: 'easy',
    durationMinutes: 30,
    objectives: [
      'Count objects up to 100',
      'Understand grouping by 10s',
      'Apply counting to real-world scenarios'
    ],
    activities: [
      {
        step: 1,
        title: 'Dinosaur Counting Warm-up',
        instructions: 'Show the child pictures of dinosaurs in groups. Ask them to count how many dinosaurs they see.',
        durationMinutes: 5,
        type: 'introduction'
      },
      {
        step: 2,
        title: 'Grouping Practice',
        instructions: 'Using toy dinosaurs or drawings, have the child arrange them into groups of 10.',
        durationMinutes: 15,
        type: 'practice'
      },
      {
        step: 3,
        title: 'Counting Challenge',
        instructions: 'Present various groups of dinosaurs and ask the child to count them quickly.',
        durationMinutes: 8,
        type: 'assessment'
      },
      {
        step: 4,
        title: 'Wrap-up',
        instructions: 'Review what was learned and praise their efforts.',
        durationMinutes: 2,
        type: 'wrap-up'
      }
    ],
    materials: ['Dinosaur pictures or toys', 'Paper and crayons', 'Number chart 1-100'],
    assessmentCriteria: [
      'Child can count objects up to 50 without help',
      'Child can group objects into 10s',
      'Child shows enthusiasm during activities'
    ]
  }

  describe('getSupportedSubjects', () => {
    it('returns list of supported subjects', () => {
      const subjects = getSupportedSubjects()
      expect(subjects).toContain('reading')
      expect(subjects).toContain('math')
      expect(subjects).toContain('science')
      expect(subjects).toContain('writing')
      expect(subjects).toContain('art')
      expect(subjects.length).toBeGreaterThan(0)
    })
  })

  describe('generateLesson', () => {
    const originalFetch = global.fetch
    const originalEnv = process.env

    beforeEach(() => {
      process.env = { ...originalEnv }
    })

    afterEach(() => {
      global.fetch = originalFetch
      process.env = originalEnv
    })

    it('rejects unsupported subjects', async () => {
      process.env.XAI_API_KEY = 'test-key'

      const request: LessonGenerationRequest = {
        childProfile: mockChildProfile,
        subject: 'underwater-basket-weaving'
      }

      await expect(generateLesson(request)).rejects.toThrow('Unsupported subject')
    })

    it('throws error when API key is missing for Grok', async () => {
      delete process.env.XAI_API_KEY
      delete process.env.GROK_API_KEY

      const request: LessonGenerationRequest = {
        childProfile: mockChildProfile,
        subject: 'math'
      }

      await expect(generateLesson(request, 'grok')).rejects.toThrow('XAI_API_KEY or GROK_API_KEY environment variable is required')
    })

    it('throws error when API key is missing for Claude', async () => {
      delete process.env.ANTHROPIC_API_KEY

      const request: LessonGenerationRequest = {
        childProfile: mockChildProfile,
        subject: 'math'
      }

      await expect(generateLesson(request, 'claude')).rejects.toThrow('ANTHROPIC_API_KEY environment variable is required')
    })

    it('generates lesson using Grok API', async () => {
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

      const request: LessonGenerationRequest = {
        childProfile: mockChildProfile,
        subject: 'math',
        topic: 'counting'
      }

      const lesson = await generateLesson(request, 'grok')

      expect(lesson.title).toBe('Counting with Dinosaurs')
      expect(lesson.subject).toBe('math')
      expect(lesson.id).toBeDefined()
      expect(lesson.source).toBe('ai-generated')
      expect(lesson.objectives).toHaveLength(3)
      expect(lesson.activities).toHaveLength(4)
      expect(lesson.materials).toContain('Dinosaur pictures or toys')

      expect(global.fetch).toHaveBeenCalledWith(
        'https://api.x.ai/v1/chat/completions',
        expect.objectContaining({
          method: 'POST',
          headers: expect.objectContaining({
            'Authorization': 'Bearer test-key'
          })
        })
      )
    })

    it('generates lesson using Claude API', async () => {
      process.env.ANTHROPIC_API_KEY = 'test-anthropic-key'

      global.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: async () => ({
          content: [{
            type: 'text',
            text: JSON.stringify(mockLessonResponse)
          }]
        })
      })

      const request: LessonGenerationRequest = {
        childProfile: mockChildProfile,
        subject: 'reading'
      }

      const lesson = await generateLesson(request, 'claude')

      expect(lesson.title).toBe('Counting with Dinosaurs')
      expect(lesson.source).toBe('ai-generated')

      expect(global.fetch).toHaveBeenCalledWith(
        'https://api.anthropic.com/v1/messages',
        expect.objectContaining({
          method: 'POST',
          headers: expect.objectContaining({
            'x-api-key': 'test-anthropic-key'
          })
        })
      )
    })

    it('handles markdown code blocks in response', async () => {
      process.env.XAI_API_KEY = 'test-key'

      global.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: async () => ({
          choices: [{
            message: {
              content: '```json\n' + JSON.stringify(mockLessonResponse) + '\n```'
            }
          }]
        })
      })

      const request: LessonGenerationRequest = {
        childProfile: mockChildProfile,
        subject: 'math'
      }

      const lesson = await generateLesson(request, 'grok')
      expect(lesson.title).toBe('Counting with Dinosaurs')
    })

    it('handles API errors gracefully', async () => {
      process.env.XAI_API_KEY = 'test-key'

      global.fetch = vi.fn().mockResolvedValue({
        ok: false,
        status: 429,
        text: async () => 'Rate limit exceeded'
      })

      const request: LessonGenerationRequest = {
        childProfile: mockChildProfile,
        subject: 'math'
      }

      await expect(generateLesson(request, 'grok')).rejects.toThrow('Grok API error: 429')
    })

    it('validates required fields in response', async () => {
      process.env.XAI_API_KEY = 'test-key'

      global.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: async () => ({
          choices: [{
            message: {
              content: JSON.stringify({ title: 'Test' })  // Missing required fields
            }
          }]
        })
      })

      const request: LessonGenerationRequest = {
        childProfile: mockChildProfile,
        subject: 'math'
      }

      await expect(generateLesson(request, 'grok')).rejects.toThrow('Invalid lesson format')
    })

    it('uses default duration when not specified', async () => {
      process.env.XAI_API_KEY = 'test-key'

      let capturedBody: string = ''
      global.fetch = vi.fn().mockImplementation(async (_url, options) => {
        capturedBody = options?.body as string
        return {
          ok: true,
          json: async () => ({
            choices: [{
              message: {
                content: JSON.stringify(mockLessonResponse)
              }
            }]
          })
        }
      })

      const request: LessonGenerationRequest = {
        childProfile: mockChildProfile,
        subject: 'math'
      }

      await generateLesson(request, 'grok')

      expect(capturedBody).toContain('Target Duration: 30 minutes')
    })

    it('incorporates child interests in prompt', async () => {
      process.env.XAI_API_KEY = 'test-key'

      let capturedBody: string = ''
      global.fetch = vi.fn().mockImplementation(async (_url, options) => {
        capturedBody = options?.body as string
        return {
          ok: true,
          json: async () => ({
            choices: [{
              message: {
                content: JSON.stringify(mockLessonResponse)
              }
            }]
          })
        }
      })

      const request: LessonGenerationRequest = {
        childProfile: mockChildProfile,
        subject: 'math'
      }

      await generateLesson(request, 'grok')

      expect(capturedBody).toContain('dinosaurs')
      expect(capturedBody).toContain('space')
      expect(capturedBody).toContain('art')
    })
  })
})
