import { useState, useEffect } from 'react'
import ProgressBadges, { type Badge } from './ProgressBadges'
import './ProgressDashboard.css'

interface ProgressStats {
  overall: {
    total_lessons: number
    completed_lessons: number
    in_progress_lessons: number
    average_score: number | null
    total_time_seconds: number
  }
  bySubject: Array<{
    subject: string
    lessons_started: number
    lessons_completed: number
    average_score: number | null
  }>
  badges: Badge[]
}

interface RecentLesson {
  lesson_id: string
  lesson_title: string
  subject: string
  status: string
  overall_score: number | null
  updated_at: string
}

interface ProgressDashboardProps {
  childId: string
  childName?: string
}

const SUBJECT_EMOJIS: Record<string, string> = {
  phonics: 'a',
  spelling: 'abc',
  'sight-words': 'the',
  reading: 'Read',
  'word-families': '-at',
  vocabulary: 'Word',
  comprehension: '?',
  default: '*',
}

const SUBJECT_COLORS: Record<string, string> = {
  phonics: '#48bb78',
  spelling: '#4299e1',
  'sight-words': '#9f7aea',
  reading: '#ed8936',
  'word-families': '#ed64a6',
  vocabulary: '#38b2ac',
  comprehension: '#667eea',
  default: '#718096',
}

function formatTime(seconds: number): string {
  if (seconds < 60) return `${seconds}s`
  const minutes = Math.floor(seconds / 60)
  if (minutes < 60) return `${minutes}m`
  const hours = Math.floor(minutes / 60)
  const remainingMinutes = minutes % 60
  return remainingMinutes > 0 ? `${hours}h ${remainingMinutes}m` : `${hours}h`
}

function formatDate(dateString: string): string {
  const date = new Date(dateString)
  const now = new Date()
  const diffMs = now.getTime() - date.getTime()
  const diffMins = Math.floor(diffMs / 60000)

  if (diffMins < 1) return 'Just now'
  if (diffMins < 60) return `${diffMins}m ago`

  const diffHours = Math.floor(diffMins / 60)
  if (diffHours < 24) return `${diffHours}h ago`

  const diffDays = Math.floor(diffHours / 24)
  if (diffDays === 1) return 'Yesterday'
  if (diffDays < 7) return `${diffDays} days ago`

  return date.toLocaleDateString()
}

export default function ProgressDashboard({ childId, childName }: ProgressDashboardProps) {
  const [stats, setStats] = useState<ProgressStats | null>(null)
  const [recent, setRecent] = useState<RecentLesson[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    async function fetchData() {
      try {
        setLoading(true)
        const token = localStorage.getItem('auth_token')
        const headers: HeadersInit = token ? { Authorization: `Bearer ${token}` } : {}

        const [statsRes, recentRes] = await Promise.all([
          fetch(`/api/progress/child/${childId}/stats`, { headers }),
          fetch(`/api/progress/child/${childId}/recent`, { headers }),
        ])

        if (statsRes.ok) {
          const statsData = await statsRes.json()
          setStats(statsData.stats)
        }

        if (recentRes.ok) {
          const recentData = await recentRes.json()
          setRecent(recentData.recent || [])
        }
      } catch (err) {
        setError('Failed to load progress data')
        console.error('Progress fetch error:', err)
      } finally {
        setLoading(false)
      }
    }

    fetchData()
  }, [childId])

  if (loading) {
    return (
      <div className="progress-dashboard loading">
        <div className="loading-spinner" />
        <p>Loading progress...</p>
      </div>
    )
  }

  if (error) {
    return (
      <div className="progress-dashboard error">
        <p>{error}</p>
      </div>
    )
  }

  const completionPercent = stats && stats.overall.total_lessons > 0
    ? Math.round((stats.overall.completed_lessons / stats.overall.total_lessons) * 100)
    : 0

  return (
    <div className="progress-dashboard">
      <header className="dashboard-header">
        <h1 className="dashboard-title">
          {childName ? `${childName}'s Progress` : 'Your Progress'}
        </h1>
      </header>

      {/* Overview Cards */}
      <div className="stats-overview">
        <div className="stat-card lessons-stat">
          <div className="stat-circle" style={{ '--percent': completionPercent } as React.CSSProperties}>
            <span className="stat-value">{stats?.overall.completed_lessons || 0}</span>
          </div>
          <div className="stat-label">
            Lessons Completed
            {stats && stats.overall.total_lessons > 0 && (
              <span className="stat-sublabel">
                of {stats.overall.total_lessons} started
              </span>
            )}
          </div>
        </div>

        <div className="stat-card score-stat">
          <div className="stat-icon">A</div>
          <div className="stat-info">
            <span className="stat-value">
              {stats?.overall.average_score
                ? `${Math.round(stats.overall.average_score)}%`
                : '--'}
            </span>
            <span className="stat-label">Average Score</span>
          </div>
        </div>

        <div className="stat-card time-stat">
          <div className="stat-icon">T</div>
          <div className="stat-info">
            <span className="stat-value">
              {formatTime(stats?.overall.total_time_seconds || 0)}
            </span>
            <span className="stat-label">Time Learning</span>
          </div>
        </div>
      </div>

      {/* Subject Progress */}
      {stats && stats.bySubject.length > 0 && (
        <section className="subject-progress">
          <h2 className="section-title">Progress by Subject</h2>
          <div className="subject-bars">
            {stats.bySubject.map((subject) => {
              const percent = subject.lessons_started > 0
                ? Math.round((subject.lessons_completed / subject.lessons_started) * 100)
                : 0
              return (
                <div key={subject.subject} className="subject-bar-item">
                  <div className="subject-bar-header">
                    <span
                      className="subject-icon"
                      style={{
                        backgroundColor: SUBJECT_COLORS[subject.subject] || SUBJECT_COLORS.default,
                      }}
                    >
                      {SUBJECT_EMOJIS[subject.subject] || SUBJECT_EMOJIS.default}
                    </span>
                    <span className="subject-name">{subject.subject}</span>
                    <span className="subject-count">
                      {subject.lessons_completed}/{subject.lessons_started}
                    </span>
                  </div>
                  <div className="subject-bar-track">
                    <div
                      className="subject-bar-fill"
                      style={{
                        width: `${percent}%`,
                        backgroundColor: SUBJECT_COLORS[subject.subject] || SUBJECT_COLORS.default,
                      }}
                    />
                  </div>
                </div>
              )
            })}
          </div>
        </section>
      )}

      {/* Badges */}
      {stats && (
        <section className="badges-section">
          <ProgressBadges badges={stats.badges} />
        </section>
      )}

      {/* Recent Activity */}
      {recent.length > 0 && (
        <section className="recent-activity">
          <h2 className="section-title">Recent Activity</h2>
          <div className="recent-list">
            {recent.slice(0, 5).map((item) => (
              <div key={item.lesson_id} className="recent-item">
                <div
                  className="recent-subject-icon"
                  style={{
                    backgroundColor: SUBJECT_COLORS[item.subject] || SUBJECT_COLORS.default,
                  }}
                >
                  {SUBJECT_EMOJIS[item.subject] || SUBJECT_EMOJIS.default}
                </div>
                <div className="recent-info">
                  <span className="recent-title">{item.lesson_title}</span>
                  <span className="recent-meta">
                    {item.status === 'completed' ? (
                      <>Score: {item.overall_score || 0}%</>
                    ) : (
                      'In progress'
                    )}
                    {' · '}
                    {formatDate(item.updated_at)}
                  </span>
                </div>
                <div className={`recent-status ${item.status}`}>
                  {item.status === 'completed' ? 'Done' : 'Continue'}
                </div>
              </div>
            ))}
          </div>
        </section>
      )}

      {/* Empty State */}
      {(!stats || stats.overall.total_lessons === 0) && recent.length === 0 && (
        <div className="empty-state">
          <div className="empty-icon">Book</div>
          <h3>Start Learning!</h3>
          <p>Complete lessons to track your progress here.</p>
        </div>
      )}
    </div>
  )
}
