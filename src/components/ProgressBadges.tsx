import './ProgressBadges.css'

export interface Badge {
  id: string
  name: string
  description: string
  earnedAt?: string
}

interface ProgressBadgesProps {
  badges: Badge[]
  showAll?: boolean
}

const BADGE_ICONS: Record<string, string> = {
  'first-lesson': '1',
  'five-lessons': '5',
  'ten-lessons': '10',
  'high-achiever': 'A+',
  'dedicated': '60',
  default: '*',
}

const BADGE_COLORS: Record<string, string> = {
  'first-lesson': '#48bb78',
  'five-lessons': '#4299e1',
  'ten-lessons': '#9f7aea',
  'high-achiever': '#ed8936',
  'dedicated': '#ed64a6',
  default: '#718096',
}

export default function ProgressBadges({ badges, showAll = false }: ProgressBadgesProps) {
  const displayBadges = showAll ? badges : badges.slice(0, 5)

  if (badges.length === 0) {
    return (
      <div className="progress-badges empty">
        <p className="badges-empty-text">
          Keep learning to earn badges!
        </p>
      </div>
    )
  }

  return (
    <div className="progress-badges">
      <h3 className="badges-title">Your Badges</h3>
      <div className="badges-grid">
        {displayBadges.map((badge) => (
          <div
            key={badge.id}
            className="badge-item"
            style={{
              '--badge-color': BADGE_COLORS[badge.id] || BADGE_COLORS.default,
            } as React.CSSProperties}
          >
            <div className="badge-icon">
              {BADGE_ICONS[badge.id] || BADGE_ICONS.default}
            </div>
            <div className="badge-info">
              <span className="badge-name">{badge.name}</span>
              <span className="badge-description">{badge.description}</span>
            </div>
          </div>
        ))}
      </div>
      {!showAll && badges.length > 5 && (
        <p className="badges-more">+{badges.length - 5} more badges</p>
      )}
    </div>
  )
}
