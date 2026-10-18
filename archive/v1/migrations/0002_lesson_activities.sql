-- Lesson activities and progress tracking schema
-- Extends the lesson system with activity-level granularity

-- Lesson activities table for queryable/indexable activity data
-- Activities are also stored as JSON in lessons.activities for quick access
CREATE TABLE IF NOT EXISTS lesson_activities (
  id TEXT PRIMARY KEY,
  lesson_id TEXT NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK(type IN (
    'reading', 'spelling', 'phonics', 'sight-words', 'quiz',
    'matching', 'fill-in-blank', 'listen-repeat', 'word-building'
  )),
  instructions TEXT NOT NULL,
  spoken_instructions TEXT,
  activity_order INTEGER NOT NULL,
  points INTEGER DEFAULT 10,
  content TEXT NOT NULL, -- JSON blob with type-specific fields
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now'))
);

-- Activity-level progress tracking
CREATE TABLE IF NOT EXISTS activity_progress (
  id TEXT PRIMARY KEY,
  child_id TEXT NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  lesson_id TEXT NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
  activity_id TEXT NOT NULL REFERENCES lesson_activities(id) ON DELETE CASCADE,
  completed INTEGER DEFAULT 0,
  score INTEGER,
  attempts INTEGER DEFAULT 0,
  time_spent_seconds INTEGER DEFAULT 0,
  completed_at TEXT,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now')),
  UNIQUE(child_id, activity_id)
);

-- Add missing columns to lessons table to match TypeScript types
ALTER TABLE lessons ADD COLUMN prerequisites TEXT; -- JSON array of lesson IDs
ALTER TABLE lessons ADD COLUMN thumbnail_url TEXT;

-- Add current_activity_index to progress table for resume functionality
ALTER TABLE progress ADD COLUMN current_activity_index INTEGER DEFAULT 0;

-- Add overall_score for weighted scoring
ALTER TABLE progress ADD COLUMN overall_score REAL;

-- Indexes for common queries
CREATE INDEX IF NOT EXISTS idx_lesson_activities_lesson ON lesson_activities(lesson_id);
CREATE INDEX IF NOT EXISTS idx_lesson_activities_type ON lesson_activities(type);
CREATE INDEX IF NOT EXISTS idx_lesson_activities_order ON lesson_activities(lesson_id, activity_order);
CREATE INDEX IF NOT EXISTS idx_activity_progress_child ON activity_progress(child_id);
CREATE INDEX IF NOT EXISTS idx_activity_progress_lesson ON activity_progress(lesson_id);
CREATE INDEX IF NOT EXISTS idx_activity_progress_activity ON activity_progress(activity_id);
CREATE INDEX IF NOT EXISTS idx_activity_progress_child_lesson ON activity_progress(child_id, lesson_id);
