import './LessonCard.css'

export interface Lesson {
  id: string
  title: string
  subject: string
  grade_level: string | null
  difficulty: string | null
  duration_minutes: number | null
  content: unknown | null
  objectives: string[] | null
}

export type LessonProgressStatus = 'not-started' | 'in-progress' | 'completed'

export interface LessonProgress {
  status: LessonProgressStatus
  score?: number | null
  currentActivityIndex?: number
}

interface LessonCardProps {
  lesson: Lesson
  progress?: LessonProgress
  onSelect: (lesson: Lesson) => void
}

const SUBJECT_EMOJIS: Record<string, string> = {
  reading: '📚',
  phonics: '🔤',
  spelling: '✏️',
  'sight-words': '👀',
  'word-families': '👨‍👩‍👧‍👦',
  vocabulary: '📖',
  comprehension: '🧠',
  math: '🔢',
  science: '🔬',
  art: '🎨',
  music: '🎵',
  nature: '🌿',
  animals: '🐾',
  default: '⭐',
}

const PROGRESS_CONFIG: Record<LessonProgressStatus, { label: string; icon: string; color: string }> = {
  'not-started': { label: 'New', icon: '✨', color: '#868e96' },
  'in-progress': { label: 'Continue', icon: '▶️', color: '#fab005' },
  'completed': { label: 'Done', icon: '✅', color: '#40c057' },
}

const DIFFICULTY_CONFIG: Record<string, { label: string; color: string; stars: number }> = {
  easy: { label: 'Easy', color: '#6bcb77', stars: 1 },
  medium: { label: 'Medium', color: '#ffd93d', stars: 2 },
  hard: { label: 'Tricky', color: '#ff922b', stars: 3 },
}

function getSubjectEmoji(subject: string): string {
  return SUBJECT_EMOJIS[subject.toLowerCase()] || SUBJECT_EMOJIS.default
}

function getDifficultyConfig(difficulty: string | null) {
  if (!difficulty) return DIFFICULTY_CONFIG.easy
  return DIFFICULTY_CONFIG[difficulty.toLowerCase()] || DIFFICULTY_CONFIG.easy
}

function formatDuration(minutes: number | null): string {
  if (!minutes) return '5 min'
  if (minutes < 60) return `${minutes} min`
  const hours = Math.floor(minutes / 60)
  const mins = minutes % 60
  return mins > 0 ? `${hours}h ${mins}m` : `${hours}h`
}

function getGradeLevelLabel(gradeLevel: string | null): string {
  if (!gradeLevel) return 'Ages 4-6'
  const level = gradeLevel.toLowerCase()
  if (level.includes('pre-k') || level.includes('prek')) return 'Ages 4-5'
  if (level.includes('k') || level.includes('kindergarten')) return 'Ages 5-6'
  if (level.includes('1') || level.includes('first')) return 'Ages 6-7'
  return gradeLevel
}

export default function LessonCard({ lesson, progress, onSelect }: LessonCardProps) {
  const subjectEmoji = getSubjectEmoji(lesson.subject)
  const difficultyConfig = getDifficultyConfig(lesson.difficulty)
  const duration = formatDuration(lesson.duration_minutes)
  const ageLabel = getGradeLevelLabel(lesson.grade_level)
  const progressStatus = progress?.status || 'not-started'
  const progressConfig = PROGRESS_CONFIG[progressStatus]

  const handleSelect = () => {
    onSelect(lesson)
  }

  const buttonText = progressStatus === 'completed'
    ? 'Play Again!'
    : progressStatus === 'in-progress'
    ? 'Continue!'
    : "Let's Go!"

  return (
    <article className={`lesson-card ${progressStatus === 'completed' ? 'lesson-card-completed' : ''}`}>
      {/* Progress indicator */}
      <div
        className="lesson-progress-indicator"
        style={{ backgroundColor: progressConfig.color }}
      >
        <span aria-hidden="true">{progressConfig.icon}</span>
        <span>{progressConfig.label}</span>
        {progressStatus === 'completed' && progress?.score != null && (
          <span className="lesson-score">{Math.round(progress.score)}%</span>
        )}
      </div>

      <div className="lesson-card-header">
        <span className="lesson-subject-emoji" aria-hidden="true">
          {subjectEmoji}
        </span>
        <span className="lesson-subject-label">{lesson.subject}</span>
      </div>

      <h3 className="lesson-title">{lesson.title}</h3>

      <div className="lesson-meta">
        <span className="lesson-badge lesson-age-badge">
          {ageLabel}
        </span>
        <span
          className="lesson-badge lesson-difficulty-badge"
          style={{ backgroundColor: difficultyConfig.color }}
        >
          {'⭐'.repeat(difficultyConfig.stars)} {difficultyConfig.label}
        </span>
        <span className="lesson-badge lesson-duration-badge">
          ⏱️ {duration}
        </span>
      </div>

      {lesson.objectives && lesson.objectives.length > 0 && (
        <p className="lesson-preview">
          {lesson.objectives[0]}
        </p>
      )}

      <button
        type="button"
        className={`lesson-select-button ${progressStatus === 'in-progress' ? 'lesson-select-button-continue' : ''}`}
        onClick={handleSelect}
        aria-label={`${buttonText} ${lesson.title}`}
      >
        {buttonText}
      </button>
    </article>
  )
}
