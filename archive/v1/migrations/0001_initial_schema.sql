-- Initial database schema for L2RR2L
-- This migration creates all tables needed for the application

CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  name TEXT NOT NULL,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS children (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  age INTEGER,
  sex TEXT,
  avatar TEXT,
  grade_level TEXT,
  learning_style TEXT,
  interests TEXT,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS onboarding (
  id TEXT PRIMARY KEY,
  user_id TEXT UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  completed INTEGER DEFAULT 0,
  step INTEGER DEFAULT 0,
  data TEXT,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS progress (
  id TEXT PRIMARY KEY,
  child_id TEXT NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  lesson_id TEXT NOT NULL,
  status TEXT DEFAULT 'not_started',
  score INTEGER,
  time_spent INTEGER DEFAULT 0,
  started_at TEXT,
  completed_at TEXT,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now')),
  UNIQUE(child_id, lesson_id)
);

CREATE TABLE IF NOT EXISTS lessons (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  subject TEXT NOT NULL,
  description TEXT,
  grade_level TEXT,
  difficulty TEXT CHECK(difficulty IN ('beginner', 'easy', 'medium', 'hard', 'advanced')),
  duration_minutes INTEGER,
  age_min INTEGER,
  age_max INTEGER,
  learning_styles TEXT,
  interests TEXT,
  objectives TEXT,
  activities TEXT,
  materials TEXT,
  assessment_criteria TEXT,
  source TEXT DEFAULT 'curated' CHECK(source IN ('ai_generated', 'curated')),
  tags TEXT,
  is_published INTEGER DEFAULT 1,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS lesson_ratings (
  id TEXT PRIMARY KEY,
  lesson_id TEXT NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  child_id TEXT REFERENCES children(id) ON DELETE SET NULL,
  rating INTEGER NOT NULL CHECK(rating >= 1 AND rating <= 5),
  feedback TEXT,
  created_at TEXT DEFAULT (datetime('now')),
  UNIQUE(lesson_id, user_id, child_id)
);

CREATE TABLE IF NOT EXISTS lesson_engagement (
  id TEXT PRIMARY KEY,
  lesson_id TEXT NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
  child_id TEXT NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  view_count INTEGER DEFAULT 0,
  start_count INTEGER DEFAULT 0,
  completion_count INTEGER DEFAULT 0,
  total_time_seconds INTEGER DEFAULT 0,
  last_accessed_at TEXT,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now')),
  UNIQUE(lesson_id, child_id)
);

CREATE TABLE IF NOT EXISTS voice_settings (
  id TEXT PRIMARY KEY,
  child_id TEXT UNIQUE NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  voice_id TEXT DEFAULT 'pMsXgVXv3BLzUgSXRplE',
  stability REAL DEFAULT 0.5,
  similarity_boost REAL DEFAULT 0.75,
  style REAL DEFAULT 0.0,
  speed REAL DEFAULT 1.0,
  use_speaker_boost INTEGER DEFAULT 1,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now'))
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_children_user ON children(user_id);
CREATE INDEX IF NOT EXISTS idx_progress_child ON progress(child_id);
CREATE INDEX IF NOT EXISTS idx_progress_lesson ON progress(lesson_id);
CREATE INDEX IF NOT EXISTS idx_lessons_subject ON lessons(subject);
CREATE INDEX IF NOT EXISTS idx_lessons_difficulty ON lessons(difficulty);
CREATE INDEX IF NOT EXISTS idx_lessons_age ON lessons(age_min, age_max);
CREATE INDEX IF NOT EXISTS idx_lessons_source ON lessons(source);
CREATE INDEX IF NOT EXISTS idx_lesson_ratings_lesson ON lesson_ratings(lesson_id);
CREATE INDEX IF NOT EXISTS idx_lesson_engagement_lesson ON lesson_engagement(lesson_id);
CREATE INDEX IF NOT EXISTS idx_lesson_engagement_child ON lesson_engagement(child_id);
CREATE INDEX IF NOT EXISTS idx_voice_settings_child ON voice_settings(child_id);
