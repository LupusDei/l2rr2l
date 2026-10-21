export type LessonDifficulty = 'beginner' | 'easy' | 'medium' | 'hard' | 'advanced'
export type LessonSource = 'ai_generated' | 'curated'
export type LearningStyle = 'visual' | 'auditory' | 'kinesthetic'

export interface ActivityStep {
  order: number
  title: string
  instructions: string
  duration_minutes?: number
  materials?: string[]
  tips?: string
}

export interface AssessmentCriteria {
  type: 'observation' | 'question' | 'activity'
  description: string
  success_indicators: string[]
}

export interface LessonObjective {
  description: string
  measurable?: boolean
}

export interface Lesson {
  id: string
  title: string
  subject: string
  description: string | null
  grade_level: string | null
  difficulty: LessonDifficulty | null
  duration_minutes: number | null
  age_min: number | null
  age_max: number | null
  learning_styles: LearningStyle[]
  interests: string[]
  objectives: LessonObjective[]
  activities: ActivityStep[]
  materials: string[]
  assessment_criteria: AssessmentCriteria[]
  source: LessonSource
  tags: string[]
  is_published: boolean
  created_at: string
  updated_at: string
}

export interface LessonRow {
  id: string
  title: string
  subject: string
  description: string | null
  grade_level: string | null
  difficulty: string | null
  duration_minutes: number | null
  age_min: number | null
  age_max: number | null
  learning_styles: string | null
  interests: string | null
  objectives: string | null
  activities: string | null
  materials: string | null
  assessment_criteria: string | null
  source: string
  tags: string | null
  is_published: number
  created_at: string
  updated_at: string
}

export interface LessonRating {
  id: string
  lesson_id: string
  user_id: string
  child_id: string | null
  rating: number
  feedback: string | null
  created_at: string
}

export interface LessonEngagement {
  id: string
  lesson_id: string
  child_id: string
  view_count: number
  start_count: number
  completion_count: number
  total_time_seconds: number
  last_accessed_at: string | null
  created_at: string
  updated_at: string
}

export interface LessonSearchFilters {
  subject?: string
  gradeLevel?: string
  difficulty?: LessonDifficulty
  ageMin?: number
  ageMax?: number
  learningStyles?: LearningStyle[]
  interests?: string[]
  source?: LessonSource
  tags?: string[]
  query?: string
}

export interface LessonWithMetrics extends Lesson {
  avg_rating: number | null
  rating_count: number
  total_completions: number
}

export function parseLesson(row: LessonRow): Lesson {
  return {
    ...row,
    difficulty: row.difficulty as LessonDifficulty | null,
    source: row.source as LessonSource,
    learning_styles: row.learning_styles ? JSON.parse(row.learning_styles) : [],
    interests: row.interests ? JSON.parse(row.interests) : [],
    objectives: row.objectives ? JSON.parse(row.objectives) : [],
    activities: row.activities ? JSON.parse(row.activities) : [],
    materials: row.materials ? JSON.parse(row.materials) : [],
    assessment_criteria: row.assessment_criteria ? JSON.parse(row.assessment_criteria) : [],
    tags: row.tags ? JSON.parse(row.tags) : [],
    is_published: row.is_published === 1
  }
}

export interface CreateLessonInput {
  title: string
  subject: string
  description?: string
  gradeLevel?: string
  difficulty?: LessonDifficulty
  durationMinutes?: number
  ageMin?: number
  ageMax?: number
  learningStyles?: LearningStyle[]
  interests?: string[]
  objectives?: LessonObjective[]
  activities?: ActivityStep[]
  materials?: string[]
  assessmentCriteria?: AssessmentCriteria[]
  source?: LessonSource
  tags?: string[]
  isPublished?: boolean
}
