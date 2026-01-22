import './LessonFilters.css'

export interface FilterState {
  search: string
  subject: string | null
  duration: string | null
  difficulty: string | null
}

interface LessonFiltersProps {
  filters: FilterState
  onFilterChange: (filters: FilterState) => void
  subjects: string[]
}

const DURATION_OPTIONS = [
  { value: '5', label: '5 min' },
  { value: '15', label: '15 min' },
  { value: '30', label: '30+ min' },
]

const DIFFICULTY_OPTIONS = [
  { value: 'easy', label: 'Easy', emoji: '⭐' },
  { value: 'medium', label: 'Medium', emoji: '⭐⭐' },
  { value: 'hard', label: 'Tricky', emoji: '⭐⭐⭐' },
]

export default function LessonFilters({ filters, onFilterChange, subjects }: LessonFiltersProps) {
  const handleSearchChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    onFilterChange({ ...filters, search: e.target.value })
  }

  const handleSubjectChange = (subject: string | null) => {
    onFilterChange({ ...filters, subject })
  }

  const handleDurationChange = (duration: string | null) => {
    onFilterChange({ ...filters, duration })
  }

  const handleDifficultyChange = (difficulty: string | null) => {
    onFilterChange({ ...filters, difficulty })
  }

  const handleClearAll = () => {
    onFilterChange({ search: '', subject: null, duration: null, difficulty: null })
  }

  const hasActiveFilters = filters.search || filters.subject || filters.duration || filters.difficulty

  return (
    <div className="lesson-filters">
      {/* Search box */}
      <div className="filter-search">
        <span className="search-icon" aria-hidden="true">🔍</span>
        <input
          type="text"
          className="search-input"
          placeholder="Search lessons..."
          value={filters.search}
          onChange={handleSearchChange}
          aria-label="Search lessons"
        />
        {filters.search && (
          <button
            type="button"
            className="search-clear"
            onClick={() => onFilterChange({ ...filters, search: '' })}
            aria-label="Clear search"
          >
            ✕
          </button>
        )}
      </div>

      {/* Filter chips */}
      <div className="filter-groups">
        {/* Subject filter */}
        {subjects.length > 0 && (
          <div className="filter-group">
            <span className="filter-label">Subject:</span>
            <div className="filter-chips">
              {subjects.map(subject => (
                <button
                  key={subject}
                  type="button"
                  className={`filter-chip ${filters.subject === subject ? 'active' : ''}`}
                  onClick={() => handleSubjectChange(filters.subject === subject ? null : subject)}
                >
                  {subject}
                </button>
              ))}
            </div>
          </div>
        )}

        {/* Duration filter */}
        <div className="filter-group">
          <span className="filter-label">Time:</span>
          <div className="filter-chips">
            {DURATION_OPTIONS.map(option => (
              <button
                key={option.value}
                type="button"
                className={`filter-chip ${filters.duration === option.value ? 'active' : ''}`}
                onClick={() => handleDurationChange(filters.duration === option.value ? null : option.value)}
              >
                ⏱️ {option.label}
              </button>
            ))}
          </div>
        </div>

        {/* Difficulty filter */}
        <div className="filter-group">
          <span className="filter-label">Level:</span>
          <div className="filter-chips">
            {DIFFICULTY_OPTIONS.map(option => (
              <button
                key={option.value}
                type="button"
                className={`filter-chip ${filters.difficulty === option.value ? 'active' : ''}`}
                onClick={() => handleDifficultyChange(filters.difficulty === option.value ? null : option.value)}
              >
                {option.emoji} {option.label}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Clear all button */}
      {hasActiveFilters && (
        <button type="button" className="clear-all-button" onClick={handleClearAll}>
          Clear all filters
        </button>
      )}
    </div>
  )
}
