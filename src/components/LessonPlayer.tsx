import { useState, useEffect, useCallback } from 'react'
import { useVoice } from '../hooks/useVoice'
import LessonProgress from './LessonProgress'
import LessonActivity from './LessonActivity'
import type { Lesson, ActivityProgress } from '../types/lesson'
import './LessonPlayer.css'

interface LessonPlayerProps {
  lesson: Lesson
  initialActivityIndex?: number
  onComplete: (progress: { overallScore: number; activityProgress: ActivityProgress[] }) => void
  onExit: () => void
}

export default function LessonPlayer({
  lesson,
  initialActivityIndex = 0,
  onComplete,
  onExit,
}: LessonPlayerProps) {
  const { speak } = useVoice()
  const [currentIndex, setCurrentIndex] = useState(initialActivityIndex)
  const [activityProgress, setActivityProgress] = useState<ActivityProgress[]>([])
  const [showObjectives, setShowObjectives] = useState(true)
  const [lessonStartTime] = useState(Date.now())

  const currentActivity = lesson.activities[currentIndex]
  const isLastActivity = currentIndex === lesson.activities.length - 1

  // Start with objectives screen
  useEffect(() => {
    if (showObjectives && lesson.objectives.length > 0) {
      speak(`Let's learn: ${lesson.title}. ${lesson.objectives[0]}`)
    }
  }, [])

  const handleStartLesson = () => {
    setShowObjectives(false)
    speak(lesson.activities[0]?.instructions || 'Let\'s begin!')
  }

  const handleActivityComplete = useCallback((score?: number) => {
    const progress: ActivityProgress = {
      activityId: currentActivity.id,
      completed: true,
      score: score ?? 100,
      attempts: 1,
      timeSpentSeconds: Math.round((Date.now() - lessonStartTime) / 1000),
      completedAt: new Date().toISOString(),
    }

    setActivityProgress(prev => [...prev, progress])

    if (isLastActivity) {
      // Calculate overall score
      const allProgress = [...activityProgress, progress]
      const totalScore = allProgress.reduce((sum, p) => sum + (p.score || 0), 0)
      const overallScore = Math.round(totalScore / allProgress.length)

      speak('Great job! You finished the lesson!')

      setTimeout(() => {
        onComplete({
          overallScore,
          activityProgress: allProgress,
        })
      }, 2000)
    } else {
      // Move to next activity
      setTimeout(() => {
        setCurrentIndex(prev => prev + 1)
      }, 500)
    }
  }, [currentActivity, isLastActivity, activityProgress, lessonStartTime, onComplete, speak])

  const handlePrevious = () => {
    if (currentIndex > 0) {
      setCurrentIndex(prev => prev - 1)
    }
  }

  const handleSkip = () => {
    const progress: ActivityProgress = {
      activityId: currentActivity.id,
      completed: false,
      score: 0,
      attempts: 0,
      timeSpentSeconds: 0,
    }
    setActivityProgress(prev => [...prev, progress])

    if (isLastActivity) {
      const allProgress = [...activityProgress, progress]
      const completedActivities = allProgress.filter(p => p.completed)
      const overallScore = completedActivities.length > 0
        ? Math.round(completedActivities.reduce((sum, p) => sum + (p.score || 0), 0) / completedActivities.length)
        : 0

      onComplete({
        overallScore,
        activityProgress: allProgress,
      })
    } else {
      setCurrentIndex(prev => prev + 1)
    }
  }

  // Objectives screen
  if (showObjectives) {
    return (
      <div className="lesson-player">
        <div className="lesson-objectives-screen">
          <h1 className="lesson-main-title">{lesson.title}</h1>
          {lesson.description && (
            <p className="lesson-description">{lesson.description}</p>
          )}
          <div className="lesson-objectives">
            <h2>What you'll learn:</h2>
            <ul>
              {lesson.objectives.map((objective, index) => (
                <li key={index}>{objective}</li>
              ))}
            </ul>
          </div>
          <div className="lesson-meta-info">
            <span className="meta-item">
              {lesson.activities.length} activities
            </span>
            <span className="meta-item">
              ~{lesson.durationMinutes} minutes
            </span>
          </div>
          <div className="lesson-objectives-buttons">
            <button
              type="button"
              className="lesson-button secondary"
              onClick={onExit}
            >
              Back
            </button>
            <button
              type="button"
              className="lesson-button primary"
              onClick={handleStartLesson}
            >
              Start Lesson
            </button>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="lesson-player">
      <LessonProgress
        currentIndex={currentIndex}
        totalActivities={lesson.activities.length}
        lessonTitle={lesson.title}
        onExit={onExit}
      />

      <div className="lesson-activity-container">
        <LessonActivity
          key={currentActivity.id}
          activity={currentActivity}
          onComplete={handleActivityComplete}
        />
      </div>

      <div className="lesson-navigation">
        <button
          type="button"
          className="nav-button"
          onClick={handlePrevious}
          disabled={currentIndex === 0}
          aria-label="Previous activity"
        >
          Back
        </button>
        <button
          type="button"
          className="nav-button skip"
          onClick={handleSkip}
          aria-label="Skip this activity"
        >
          Skip
        </button>
      </div>
    </div>
  )
}
