import { useState, useEffect, useRef, useCallback } from 'react'
import LessonCard from './LessonCard'
import type { Lesson, LessonProgress, LessonProgressStatus } from './LessonCard'
import LessonFilters from './LessonFilters'
import type { FilterState } from './LessonFilters'
import './LessonSelection.css'

interface ChildData {
  id?: string
  name: string
  age: number | null
  sex: string | null
  avatar: string | null
}

interface LessonSelectionProps {
  childData: ChildData
  childId: string
  onSelectLesson: (lesson: Lesson) => void
  onBack: () => void
}

interface ProgressRecord {
  lesson_id: string
  status: string
  score: number | null
  overall_score: number | null
  current_activity_index: number
}

// Simple cache for API results
interface CacheEntry<T> {
  data: T
  timestamp: number
}

const cache = new Map<string, CacheEntry<unknown>>()
const CACHE_TTL = 5 * 60 * 1000 // 5 minutes

function getCached<T>(key: string): T | null {
  const entry = cache.get(key)
  if (!entry) return null
  if (Date.now() - entry.timestamp > CACHE_TTL) {
    cache.delete(key)
    return null
  }
  return entry.data as T
}

function setCache<T>(key: string, data: T): void {
  cache.set(key, { data, timestamp: Date.now() })
}

// Build query string from filters
function buildQueryParams(filters: FilterState): string {
  const params = new URLSearchParams()
  if (filters.search) params.set('query', filters.search)
  if (filters.subject) params.set('subject', filters.subject)
  if (filters.difficulty) params.set('difficulty', filters.difficulty)
  return params.toString()
}

const AVATAR_EMOJIS: Record<string, string> = {
  bear: '🐻',
  bunny: '🐰',
  fox: '🦊',
  owl: '🦉',
  cat: '🐱',
  dog: '🐶',
  panda: '🐼',
  lion: '🦁',
}

const GREETINGS = [
  "Ready to learn something fun?",
  "What shall we explore today?",
  "Pick a lesson and let's go!",
  "Your adventure awaits!",
]

function getRandomGreeting(): string {
  return GREETINGS[Math.floor(Math.random() * GREETINGS.length)]
}

export default function LessonSelection({ childData, childId, onSelectLesson, onBack }: LessonSelectionProps) {
  const [lessons, setLessons] = useState<Lesson[]>([])
  const [recommendedLessons, setRecommendedLessons] = useState<Lesson[]>([])
  const [subjects, setSubjects] = useState<string[]>([])
  const [progressMap, setProgressMap] = useState<Map<string, LessonProgress>>(new Map())
  const [loading, setLoading] = useState(true)
  const [filterLoading, setFilterLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [greeting] = useState(getRandomGreeting)
  const [filters, setFilters] = useState<FilterState>({
    search: '',
    subject: null,
    duration: null,
    difficulty: null,
  })

  const debounceTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null)
  const abortControllerRef = useRef<AbortController | null>(null)

  const avatarEmoji = childData.avatar ? AVATAR_EMOJIS[childData.avatar] || '⭐' : '⭐'

  // Fetch lessons with optional filters and caching
  const fetchLessons = useCallback(async (filterParams?: FilterState, isFilterChange = false) => {
    // Cancel any pending request
    if (abortControllerRef.current) {
      abortControllerRef.current.abort()
    }
    abortControllerRef.current = new AbortController()

    const queryString = filterParams ? buildQueryParams(filterParams) : ''
    const url = queryString ? `/api/lessons?${queryString}` : '/api/lessons'
    const cacheKey = `lessons:${url}`

    // Check cache first
    const cached = getCached<{ lessons: Lesson[] }>(cacheKey)
    if (cached) {
      setLessons(cached.lessons)
      if (!isFilterChange) setLoading(false)
      setFilterLoading(false)
      return
    }

    try {
      if (isFilterChange) {
        setFilterLoading(true)
      } else {
        setLoading(true)
      }
      setError(null)

      const response = await fetch(url, { signal: abortControllerRef.current.signal })
      if (!response.ok) {
        throw new Error('Failed to load lessons')
      }
      const data = await response.json()
      const lessonsData = data.lessons || []

      setLessons(lessonsData)
      setCache(cacheKey, { lessons: lessonsData })
    } catch (err) {
      if (err instanceof Error && err.name === 'AbortError') {
        return // Ignore aborted requests
      }
      setError(err instanceof Error ? err.message : 'Something went wrong')
    } finally {
      setLoading(false)
      setFilterLoading(false)
    }
  }, [])

  // Fetch recommended lessons based on child's age
  const fetchRecommendedLessons = useCallback(async () => {
    const params = new URLSearchParams()
    if (childData.age) {
      params.set('ageMin', String(childData.age))
      params.set('ageMax', String(childData.age))
    }
    params.set('limit', '3')

    const url = `/api/lessons?${params.toString()}`
    const cacheKey = `recommended:${url}`

    // Check cache first
    const cached = getCached<{ lessons: Lesson[] }>(cacheKey)
    if (cached) {
      setRecommendedLessons(cached.lessons)
      return
    }

    try {
      const response = await fetch(url)
      if (response.ok) {
        const data = await response.json()
        const lessonsData = data.lessons || []
        setRecommendedLessons(lessonsData)
        setCache(cacheKey, { lessons: lessonsData })
      }
    } catch {
      // Fall back to first 3 lessons if recommendations fail
    }
  }, [childData.age])

  // Fetch subjects with caching
  const fetchSubjects = useCallback(async () => {
    const cacheKey = 'subjects'
    const cached = getCached<string[]>(cacheKey)
    if (cached) {
      setSubjects(cached)
      return
    }

    try {
      const response = await fetch('/api/lessons/subjects')
      if (response.ok) {
        const data = await response.json()
        const subjectsData = data.subjects || []
        setSubjects(subjectsData)
        setCache(cacheKey, subjectsData)
      }
    } catch {
      // Silently fail - subjects are optional
    }
  }, [])

  // Fetch progress for all lessons
  const fetchProgress = useCallback(async () => {
    if (!childId) return

    const cacheKey = `progress:${childId}`
    const cached = getCached<ProgressRecord[]>(cacheKey)
    if (cached) {
      const map = new Map<string, LessonProgress>()
      for (const p of cached) {
        map.set(p.lesson_id, {
          status: (p.status === 'in_progress' ? 'in-progress' : p.status) as LessonProgressStatus,
          score: p.overall_score ?? p.score,
          currentActivityIndex: p.current_activity_index,
        })
      }
      setProgressMap(map)
      return
    }

    try {
      const response = await fetch(`/api/progress/child/${childId}`)
      if (response.ok) {
        const data = await response.json()
        const progressData = data.progress || []
        setCache(cacheKey, progressData)

        const map = new Map<string, LessonProgress>()
        for (const p of progressData) {
          map.set(p.lesson_id, {
            status: (p.status === 'in_progress' ? 'in-progress' : p.status) as LessonProgressStatus,
            score: p.overall_score ?? p.score,
            currentActivityIndex: p.current_activity_index,
          })
        }
        setProgressMap(map)
      }
    } catch {
      // Silently fail - progress is optional enhancement
    }
  }, [childId])

  // Initial data fetch
  useEffect(() => {
    fetchLessons()
    fetchRecommendedLessons()
    fetchSubjects()
    fetchProgress()
  }, [fetchLessons, fetchRecommendedLessons, fetchSubjects, fetchProgress])

  // Handle filter changes with debounce for search
  useEffect(() => {
    const hasActiveFilters = filters.search || filters.subject || filters.difficulty

    if (!hasActiveFilters) {
      // No filters - fetch all lessons
      fetchLessons()
      return
    }

    // Debounce search input
    if (debounceTimerRef.current) {
      clearTimeout(debounceTimerRef.current)
    }

    debounceTimerRef.current = setTimeout(() => {
      fetchLessons(filters, true)
    }, filters.search ? 300 : 0) // Only debounce search, not other filters

    return () => {
      if (debounceTimerRef.current) {
        clearTimeout(debounceTimerRef.current)
      }
    }
  }, [filters, fetchLessons])

  // Client-side duration filter (not supported by API)
  const filteredLessons = lessons.filter(lesson => {
    if (!filters.duration) return true
    const duration = lesson.duration_minutes || 5
    if (filters.duration === '5' && duration > 10) return false
    if (filters.duration === '15' && (duration < 10 || duration > 20)) return false
    if (filters.duration === '30' && duration < 25) return false
    return true
  })

  // Use recommended lessons, falling back to first 3 of all lessons
  const displayRecommendedLessons = recommendedLessons.length > 0 ? recommendedLessons : lessons.slice(0, 3)
  const allLessons = filteredLessons
  const hasActiveFilters = filters.search || filters.subject || filters.duration || filters.difficulty

  return (
    <div className="lesson-selection">
      {/* Header */}
      <header className="lesson-selection-header">
        <button
          type="button"
          className="back-button"
          onClick={onBack}
          aria-label="Go back"
        >
          ← Back
        </button>

        <div className="header-content">
          <span className="header-avatar">{avatarEmoji}</span>
          <div className="header-text">
            <h1 className="header-greeting">Hi, {childData.name}!</h1>
            <p className="header-subtitle">{greeting}</p>
          </div>
        </div>
      </header>

      {/* Main content */}
      <main className="lesson-selection-content">
        {loading && (
          <div className="loading-state">
            <span className="loading-spinner">🌟</span>
            <p>Finding fun lessons for you...</p>
          </div>
        )}

        {error && (
          <div className="error-state">
            <span className="error-icon">😢</span>
            <p>{error}</p>
            <button type="button" className="retry-button" onClick={() => fetchLessons()}>
              Try Again
            </button>
          </div>
        )}

        {!loading && !error && lessons.length === 0 && (
          <div className="empty-state">
            <span className="empty-icon">📚</span>
            <p>No lessons available yet. Check back soon!</p>
          </div>
        )}

        {!loading && !error && lessons.length > 0 && (
          <>
            {/* Recommended section */}
            {displayRecommendedLessons.length > 0 && !hasActiveFilters && (
              <section className="lesson-section">
                <h2 className="section-title">
                  <span className="section-icon">⭐</span>
                  Recommended for you
                </h2>
                <div className="lesson-grid recommended-grid">
                  {displayRecommendedLessons.map(lesson => (
                    <LessonCard
                      key={lesson.id}
                      lesson={lesson}
                      progress={progressMap.get(lesson.id)}
                      onSelect={onSelectLesson}
                    />
                  ))}
                </div>
              </section>
            )}

            {/* Browse all section */}
            <section className="lesson-section">
              <h2 className="section-title">
                <span className="section-icon">📖</span>
                Browse all lessons
              </h2>

              <LessonFilters
                filters={filters}
                onFilterChange={setFilters}
                subjects={subjects}
              />

              {filterLoading && (
                <div className="filter-loading">
                  <span className="filter-loading-spinner">🔄</span>
                  <span>Updating results...</span>
                </div>
              )}

              {!filterLoading && allLessons.length === 0 && hasActiveFilters ? (
                <div className="no-results">
                  <span className="no-results-icon">🔍</span>
                  <p>No lessons match your filters. Try changing them!</p>
                </div>
              ) : !filterLoading && (
                <div className="lesson-grid all-lessons-grid">
                  {allLessons.map(lesson => (
                    <LessonCard
                      key={lesson.id}
                      lesson={lesson}
                      progress={progressMap.get(lesson.id)}
                      onSelect={onSelectLesson}
                    />
                  ))}
                </div>
              )}
            </section>
          </>
        )}
      </main>
    </div>
  )
}
