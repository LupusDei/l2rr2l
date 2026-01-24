import './LessonProgress.css'

interface LessonProgressProps {
  currentIndex: number
  totalActivities: number
  lessonTitle: string
  onExit?: () => void
}

export default function LessonProgress({
  currentIndex,
  totalActivities,
  lessonTitle,
  onExit,
}: LessonProgressProps) {
  const progressPercent = totalActivities > 0
    ? Math.round(((currentIndex + 1) / totalActivities) * 100)
    : 0

  return (
    <div className="lesson-progress">
      <div className="lesson-progress-header">
        {onExit && (
          <button
            type="button"
            className="lesson-exit-button"
            onClick={onExit}
            aria-label="Exit lesson"
          >
            X
          </button>
        )}
        <h2 className="lesson-progress-title">{lessonTitle}</h2>
        <span className="lesson-progress-count">
          {currentIndex + 1} / {totalActivities}
        </span>
      </div>

      <div className="lesson-progress-bar-container">
        <div
          className="lesson-progress-bar"
          style={{ width: `${progressPercent}%` }}
          role="progressbar"
          aria-valuenow={progressPercent}
          aria-valuemin={0}
          aria-valuemax={100}
          aria-label={`Lesson progress: ${progressPercent}%`}
        />
      </div>

      <div className="lesson-progress-dots">
        {Array.from({ length: totalActivities }).map((_, index) => (
          <span
            key={index}
            className={`lesson-progress-dot ${
              index < currentIndex
                ? 'completed'
                : index === currentIndex
                ? 'current'
                : ''
            }`}
            aria-label={
              index < currentIndex
                ? `Activity ${index + 1} completed`
                : index === currentIndex
                ? `Current activity ${index + 1}`
                : `Activity ${index + 1} not started`
            }
          />
        ))}
      </div>
    </div>
  )
}
