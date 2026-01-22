import { useState, useEffect, useMemo } from 'react'
import LessonCard from './LessonCard'
import type { Lesson } from './LessonCard'
import LessonFilters from './LessonFilters'
import type { FilterState } from './LessonFilters'
import './LessonSelection.css'

interface ChildData {
  name: string
  age: number | null
  sex: string | null
  avatar: string | null
}

interface LessonSelectionProps {
  childData: ChildData
  onSelectLesson: (lesson: Lesson) => void
  onBack: () => void
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

export default function LessonSelection({ childData, onSelectLesson, onBack }: LessonSelectionProps) {
  const [lessons, setLessons] = useState<Lesson[]>([])
  const [subjects, setSubjects] = useState<string[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [greeting] = useState(getRandomGreeting)
  const [filters, setFilters] = useState<FilterState>({
    search: '',
    subject: null,
    duration: null,
    difficulty: null,
  })

  const avatarEmoji = childData.avatar ? AVATAR_EMOJIS[childData.avatar] || '⭐' : '⭐'

  useEffect(() => {
    fetchLessons()
    fetchSubjects()
  }, [])

  const fetchLessons = async () => {
    try {
      setLoading(true)
      setError(null)
      const response = await fetch('/api/lessons')
      if (!response.ok) {
        throw new Error('Failed to load lessons')
      }
      const data = await response.json()
      setLessons(data.lessons || [])
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Something went wrong')
    } finally {
      setLoading(false)
    }
  }

  const fetchSubjects = async () => {
    try {
      const response = await fetch('/api/lessons/subjects')
      if (response.ok) {
        const data = await response.json()
        setSubjects(data.subjects || [])
      }
    } catch {
      // Silently fail - subjects are optional
    }
  }

  const filteredLessons = useMemo(() => {
    return lessons.filter(lesson => {
      // Search filter
      if (filters.search) {
        const searchLower = filters.search.toLowerCase()
        const titleMatch = lesson.title.toLowerCase().includes(searchLower)
        const subjectMatch = lesson.subject.toLowerCase().includes(searchLower)
        if (!titleMatch && !subjectMatch) return false
      }

      // Subject filter
      if (filters.subject && lesson.subject.toLowerCase() !== filters.subject.toLowerCase()) {
        return false
      }

      // Duration filter
      if (filters.duration) {
        const duration = lesson.duration_minutes || 5
        if (filters.duration === '5' && duration > 10) return false
        if (filters.duration === '15' && (duration < 10 || duration > 20)) return false
        if (filters.duration === '30' && duration < 25) return false
      }

      // Difficulty filter
      if (filters.difficulty && lesson.difficulty?.toLowerCase() !== filters.difficulty) {
        return false
      }

      return true
    })
  }, [lessons, filters])

  const recommendedLessons = lessons.slice(0, 3)
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
            <button type="button" className="retry-button" onClick={fetchLessons}>
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
            {recommendedLessons.length > 0 && (
              <section className="lesson-section">
                <h2 className="section-title">
                  <span className="section-icon">⭐</span>
                  Recommended for you
                </h2>
                <div className="lesson-grid recommended-grid">
                  {recommendedLessons.map(lesson => (
                    <LessonCard
                      key={lesson.id}
                      lesson={lesson}
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

              {allLessons.length === 0 && hasActiveFilters ? (
                <div className="no-results">
                  <span className="no-results-icon">🔍</span>
                  <p>No lessons match your filters. Try changing them!</p>
                </div>
              ) : (
                <div className="lesson-grid all-lessons-grid">
                  {allLessons.map(lesson => (
                    <LessonCard
                      key={lesson.id}
                      lesson={lesson}
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
