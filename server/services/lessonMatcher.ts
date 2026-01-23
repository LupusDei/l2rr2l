import { db } from '../db/index.js'
import { Lesson, LessonRow, parseLesson, LessonDifficulty, LearningStyle } from '../types/lesson.js'

export interface ChildProfile {
  id: string
  age: number | null
  gradeLevel: string | null
  learningStyle: string | null
  interests: string[]
}

export interface ScoredLesson extends Lesson {
  matchScore: number
  scoreBreakdown: {
    ageScore: number
    interestScore: number
    learningStyleScore: number
    difficultyScore: number
    popularityScore: number
  }
}

interface ChildProgressSummary {
  completedLessonIds: Set<string>
  completedDifficulties: LessonDifficulty[]
  subjectProgress: Map<string, { completed: number; avgScore: number }>
}

const DIFFICULTY_ORDER: LessonDifficulty[] = ['beginner', 'easy', 'medium', 'hard', 'advanced']

const GRADE_TO_AGE: Record<string, { min: number; max: number }> = {
  'Pre-K': { min: 3, max: 4 },
  'Kindergarten': { min: 5, max: 6 },
  '1st grade': { min: 6, max: 7 },
  '2nd grade': { min: 7, max: 8 },
  '3rd grade': { min: 8, max: 9 },
  '4th grade': { min: 9, max: 10 },
  '5th grade': { min: 10, max: 11 },
}

/**
 * Get child's learning progress for difficulty progression calculation
 */
function getChildProgress(childId: string): ChildProgressSummary {
  const completedLessons = db.prepare(`
    SELECT p.lesson_id, p.score, l.difficulty, l.subject
    FROM progress p
    JOIN lessons l ON p.lesson_id = l.id
    WHERE p.child_id = ? AND p.status = 'completed'
  `).all(childId) as { lesson_id: string; score: number | null; difficulty: string | null; subject: string }[]

  const completedLessonIds = new Set(completedLessons.map(l => l.lesson_id))
  const completedDifficulties = [...new Set(
    completedLessons
      .filter(l => l.difficulty)
      .map(l => l.difficulty as LessonDifficulty)
  )]

  const subjectProgress = new Map<string, { completed: number; avgScore: number }>()
  for (const lesson of completedLessons) {
    const existing = subjectProgress.get(lesson.subject) || { completed: 0, avgScore: 0 }
    const newCompleted = existing.completed + 1
    const newAvgScore = ((existing.avgScore * existing.completed) + (lesson.score || 0)) / newCompleted
    subjectProgress.set(lesson.subject, { completed: newCompleted, avgScore: newAvgScore })
  }

  return { completedLessonIds, completedDifficulties, subjectProgress }
}

/**
 * Calculate age appropriateness score (0-100)
 */
function calculateAgeScore(lesson: Lesson, childAge: number | null, gradeLevel: string | null): number {
  let effectiveAge = childAge

  // If no age but have grade level, estimate age
  if (!effectiveAge && gradeLevel && GRADE_TO_AGE[gradeLevel]) {
    effectiveAge = Math.round((GRADE_TO_AGE[gradeLevel].min + GRADE_TO_AGE[gradeLevel].max) / 2)
  }

  if (!effectiveAge) return 50 // Neutral score if no age info

  const { age_min, age_max } = lesson

  // No age restrictions - neutral match
  if (age_min === null && age_max === null) return 60

  // Check if child is within range
  const minAge = age_min ?? 0
  const maxAge = age_max ?? 100

  if (effectiveAge >= minAge && effectiveAge <= maxAge) {
    // Perfect match - score based on how centered they are in the range
    const rangeSize = maxAge - minAge
    if (rangeSize === 0) return 100
    const center = (minAge + maxAge) / 2
    const distanceFromCenter = Math.abs(effectiveAge - center)
    const maxDistance = rangeSize / 2
    return 100 - (distanceFromCenter / maxDistance) * 20 // 80-100 range
  }

  // Outside range - penalize based on distance
  const distance = effectiveAge < minAge
    ? minAge - effectiveAge
    : effectiveAge - maxAge

  // Penalize 15 points per year outside range, minimum 0
  return Math.max(0, 50 - distance * 15)
}

/**
 * Calculate interest match score (0-100)
 */
function calculateInterestScore(lesson: Lesson, childInterests: string[]): number {
  if (childInterests.length === 0) return 50 // Neutral if no interests specified

  const lessonInterests = lesson.interests || []
  const lessonTags = lesson.tags || []
  const lessonSubject = lesson.subject.toLowerCase()

  // Combine lesson interests and tags for matching
  const lessonKeywords = new Set([
    ...lessonInterests.map(i => i.toLowerCase()),
    ...lessonTags.map(t => t.toLowerCase()),
    lessonSubject
  ])

  if (lessonKeywords.size === 0) return 40 // Slight penalty for lessons with no interest metadata

  const childInterestLower = childInterests.map(i => i.toLowerCase())

  // Count matches (exact and partial)
  let matchCount = 0
  for (const childInterest of childInterestLower) {
    for (const keyword of lessonKeywords) {
      if (keyword === childInterest || keyword.includes(childInterest) || childInterest.includes(keyword)) {
        matchCount++
        break
      }
    }
  }

  // Score based on percentage of child interests matched
  const matchPercentage = matchCount / childInterests.length
  return Math.round(40 + matchPercentage * 60) // 40-100 range
}

/**
 * Calculate learning style match score (0-100)
 */
function calculateLearningStyleScore(lesson: Lesson, childLearningStyle: string | null): number {
  if (!childLearningStyle) return 50 // Neutral if no preference

  const lessonStyles = lesson.learning_styles || []

  if (lessonStyles.length === 0) return 50 // Neutral for lessons without style info

  // Check if child's style is included
  if (lessonStyles.includes(childLearningStyle as LearningStyle)) {
    // Bonus if it's the primary style (first in list)
    if (lessonStyles[0] === childLearningStyle) return 100
    return 85
  }

  // Style not matched - moderate penalty
  return 30
}

/**
 * Calculate difficulty progression score (0-100)
 * Favors lessons at appropriate difficulty based on completed lessons
 */
function calculateDifficultyScore(
  lesson: Lesson,
  progress: ChildProgressSummary
): number {
  const lessonDifficulty = lesson.difficulty
  if (!lessonDifficulty) return 50 // Neutral for lessons without difficulty

  const lessonDifficultyIndex = DIFFICULTY_ORDER.indexOf(lessonDifficulty)

  // Determine child's current level based on completed lessons
  let maxCompletedIndex = -1
  for (const completed of progress.completedDifficulties) {
    const idx = DIFFICULTY_ORDER.indexOf(completed)
    if (idx > maxCompletedIndex) maxCompletedIndex = idx
  }

  // Check subject-specific progress for more targeted difficulty
  const subjectProgress = progress.subjectProgress.get(lesson.subject)
  if (subjectProgress && subjectProgress.avgScore >= 80) {
    // Good scores in this subject - can handle harder content
    maxCompletedIndex = Math.min(maxCompletedIndex + 1, DIFFICULTY_ORDER.length - 1)
  }

  // Ideal difficulty is one level above current or at current level
  const idealIndex = Math.min(maxCompletedIndex + 1, DIFFICULTY_ORDER.length - 1)
  const idealDifficulty = maxCompletedIndex >= 0 ? DIFFICULTY_ORDER[idealIndex] : 'beginner'

  if (lessonDifficulty === idealDifficulty) return 100

  // Calculate distance from ideal
  const distance = Math.abs(lessonDifficultyIndex - idealIndex)

  if (lessonDifficultyIndex < idealIndex) {
    // Easier than ideal - slight penalty (review is okay)
    return Math.max(50, 100 - distance * 20)
  } else {
    // Harder than ideal - bigger penalty (don't want to overwhelm)
    return Math.max(20, 100 - distance * 30)
  }
}

/**
 * Calculate popularity score based on ratings and completions (0-100)
 */
function calculatePopularityScore(avgRating: number | null, totalCompletions: number): number {
  let score = 50 // Base score

  // Rating component (0-30 points)
  if (avgRating !== null) {
    score += (avgRating / 5) * 30
  }

  // Completions component (0-20 points, diminishing returns)
  const completionBonus = Math.min(20, Math.log10(totalCompletions + 1) * 10)
  score += completionBonus

  return Math.round(score)
}

/**
 * Main matching function - returns scored and ranked lessons for a child
 */
export function matchLessonsForChild(
  childId: string,
  options: {
    limit?: number
    excludeCompleted?: boolean
    subjectFilter?: string
    minScore?: number
  } = {}
): ScoredLesson[] {
  const { limit = 20, excludeCompleted = true, subjectFilter, minScore = 0 } = options

  // Get child profile
  const child = db.prepare(`
    SELECT id, age, grade_level, learning_style, interests
    FROM children WHERE id = ?
  `).get(childId) as {
    id: string
    age: number | null
    grade_level: string | null
    learning_style: string | null
    interests: string | null
  } | undefined

  if (!child) {
    throw new Error('Child not found')
  }

  const childProfile: ChildProfile = {
    id: child.id,
    age: child.age,
    gradeLevel: child.grade_level,
    learningStyle: child.learning_style,
    interests: child.interests ? JSON.parse(child.interests) : []
  }

  // Get child's progress
  const progress = getChildProgress(childId)

  // Fetch all published lessons with metrics
  let sql = `
    SELECT l.*,
      COALESCE(AVG(r.rating), 0) as avg_rating,
      COUNT(DISTINCT r.id) as rating_count,
      COALESCE(SUM(e.completion_count), 0) as total_completions
    FROM lessons l
    LEFT JOIN lesson_ratings r ON l.id = r.lesson_id
    LEFT JOIN lesson_engagement e ON l.id = e.lesson_id
    WHERE l.is_published = 1
  `
  const params: (string | number)[] = []

  if (subjectFilter) {
    sql += ' AND l.subject = ?'
    params.push(subjectFilter)
  }

  sql += ' GROUP BY l.id'

  const lessons = db.prepare(sql).all(...params) as (LessonRow & {
    avg_rating: number
    rating_count: number
    total_completions: number
  })[]

  // Score each lesson
  const scoredLessons: ScoredLesson[] = []

  for (const row of lessons) {
    // Skip completed lessons if requested
    if (excludeCompleted && progress.completedLessonIds.has(row.id)) {
      continue
    }

    const lesson = parseLesson(row)

    const ageScore = calculateAgeScore(lesson, childProfile.age, childProfile.gradeLevel)
    const interestScore = calculateInterestScore(lesson, childProfile.interests)
    const learningStyleScore = calculateLearningStyleScore(lesson, childProfile.learningStyle)
    const difficultyScore = calculateDifficultyScore(lesson, progress)
    const popularityScore = calculatePopularityScore(
      row.avg_rating || null,
      row.total_completions
    )

    // Weighted composite score
    const matchScore = Math.round(
      ageScore * 0.30 +           // Age appropriateness is critical
      interestScore * 0.25 +      // Interests drive engagement
      learningStyleScore * 0.20 + // Learning style affects comprehension
      difficultyScore * 0.15 +    // Difficulty progression for growth
      popularityScore * 0.10      // Social proof as tiebreaker
    )

    if (matchScore >= minScore) {
      scoredLessons.push({
        ...lesson,
        matchScore,
        scoreBreakdown: {
          ageScore,
          interestScore,
          learningStyleScore,
          difficultyScore,
          popularityScore
        }
      })
    }
  }

  // Sort by score descending
  scoredLessons.sort((a, b) => b.matchScore - a.matchScore)

  // Return top results
  return scoredLessons.slice(0, limit)
}

/**
 * Get quick recommendations without full scoring (for performance)
 */
export function getQuickRecommendations(
  childId: string,
  currentLessonId: string,
  limit: number = 5
): Lesson[] {
  const child = db.prepare(`
    SELECT age, learning_style, interests FROM children WHERE id = ?
  `).get(childId) as {
    age: number | null
    learning_style: string | null
    interests: string | null
  } | undefined

  if (!child) return []

  const currentLesson = db.prepare('SELECT subject, grade_level FROM lessons WHERE id = ?')
    .get(currentLessonId) as { subject: string; grade_level: string | null } | undefined

  if (!currentLesson) return []

  // Simple query for related lessons
  let sql = `
    SELECT * FROM lessons
    WHERE id != ? AND is_published = 1
    AND (subject = ? OR grade_level = ?)
  `
  const params: (string | number)[] = [currentLessonId, currentLesson.subject, currentLesson.grade_level || '']

  if (child.age) {
    sql += ' AND (age_min IS NULL OR age_min <= ?) AND (age_max IS NULL OR age_max >= ?)'
    params.push(child.age, child.age)
  }

  if (child.learning_style) {
    sql += ' AND (learning_styles IS NULL OR learning_styles LIKE ?)'
    params.push(`%"${child.learning_style}"%`)
  }

  sql += ' ORDER BY RANDOM() LIMIT ?'
  params.push(limit)

  const lessons = db.prepare(sql).all(...params) as LessonRow[]
  return lessons.map(parseLesson)
}
