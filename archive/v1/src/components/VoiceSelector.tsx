import { useState, useEffect, useRef, useCallback } from 'react'
import './VoiceSelector.css'

export interface Voice {
  voiceId: string
  name: string
  category?: string
  description?: string
  previewUrl?: string
  labels?: Record<string, string>
}

interface VoiceSelectorProps {
  selectedVoiceId?: string
  onVoiceSelect: (voice: Voice) => void
  showChildFriendlyOnly?: boolean
}

// Voice categories considered child-friendly
const CHILD_FRIENDLY_CATEGORIES = ['premade', 'professional']
const CHILD_FRIENDLY_KEYWORDS = ['child', 'kid', 'young', 'friendly', 'warm', 'soft', 'gentle']

function isChildFriendly(voice: Voice): boolean {
  // Check category
  if (voice.category && CHILD_FRIENDLY_CATEGORIES.includes(voice.category.toLowerCase())) {
    return true
  }

  // Check labels
  if (voice.labels) {
    const labelValues = Object.values(voice.labels).join(' ').toLowerCase()
    if (CHILD_FRIENDLY_KEYWORDS.some(keyword => labelValues.includes(keyword))) {
      return true
    }
  }

  // Check description
  if (voice.description) {
    const desc = voice.description.toLowerCase()
    if (CHILD_FRIENDLY_KEYWORDS.some(keyword => desc.includes(keyword))) {
      return true
    }
  }

  // Default: include premade voices as they're generally suitable
  return voice.category === 'premade'
}

export default function VoiceSelector({
  selectedVoiceId,
  onVoiceSelect,
  showChildFriendlyOnly = true,
}: VoiceSelectorProps) {
  const [voices, setVoices] = useState<Voice[]>([])
  const [filteredVoices, setFilteredVoices] = useState<Voice[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [isOpen, setIsOpen] = useState(false)
  const [playingVoiceId, setPlayingVoiceId] = useState<string | null>(null)
  const [filterChildFriendly, setFilterChildFriendly] = useState(showChildFriendlyOnly)

  const audioRef = useRef<HTMLAudioElement | null>(null)
  const dropdownRef = useRef<HTMLDivElement>(null)

  // Fetch voices from API
  useEffect(() => {
    const fetchVoices = async () => {
      try {
        setLoading(true)
        setError(null)

        const response = await fetch('/api/voice/voices')
        if (!response.ok) {
          throw new Error('Failed to load voices')
        }

        const data = await response.json()
        setVoices(data.voices || [])
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to load voices')
      } finally {
        setLoading(false)
      }
    }

    fetchVoices()
  }, [])

  // Filter voices when filter changes
  useEffect(() => {
    if (filterChildFriendly) {
      setFilteredVoices(voices.filter(isChildFriendly))
    } else {
      setFilteredVoices(voices)
    }
  }, [voices, filterChildFriendly])

  // Close dropdown when clicking outside
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setIsOpen(false)
      }
    }

    document.addEventListener('mousedown', handleClickOutside)
    return () => document.removeEventListener('mousedown', handleClickOutside)
  }, [])

  // Stop audio when component unmounts
  useEffect(() => {
    return () => {
      if (audioRef.current) {
        audioRef.current.pause()
        audioRef.current = null
      }
    }
  }, [])

  const handlePlayPreview = useCallback((voice: Voice, event: React.MouseEvent) => {
    event.stopPropagation()

    if (!voice.previewUrl) return

    // If same voice is playing, stop it
    if (playingVoiceId === voice.voiceId) {
      if (audioRef.current) {
        audioRef.current.pause()
        audioRef.current = null
      }
      setPlayingVoiceId(null)
      return
    }

    // Stop any currently playing audio
    if (audioRef.current) {
      audioRef.current.pause()
    }

    // Play new audio
    const audio = new Audio(voice.previewUrl)
    audioRef.current = audio
    setPlayingVoiceId(voice.voiceId)

    audio.play().catch(() => {
      setPlayingVoiceId(null)
    })

    audio.onended = () => {
      setPlayingVoiceId(null)
      audioRef.current = null
    }

    audio.onerror = () => {
      setPlayingVoiceId(null)
      audioRef.current = null
    }
  }, [playingVoiceId])

  const handleSelectVoice = useCallback((voice: Voice) => {
    onVoiceSelect(voice)
    setIsOpen(false)
  }, [onVoiceSelect])

  const selectedVoice = voices.find(v => v.voiceId === selectedVoiceId)

  const getCategoryLabel = (category?: string): string => {
    if (!category) return ''
    const labels: Record<string, string> = {
      premade: 'Standard',
      cloned: 'Custom',
      generated: 'AI Generated',
      professional: 'Professional',
    }
    return labels[category.toLowerCase()] || category
  }

  if (loading) {
    return (
      <div className="voice-selector voice-selector-loading">
        <span className="voice-selector-spinner" aria-hidden="true">🎤</span>
        <span>Loading voices...</span>
      </div>
    )
  }

  if (error) {
    return (
      <div className="voice-selector voice-selector-error">
        <span className="voice-selector-error-icon" aria-hidden="true">😢</span>
        <span>{error}</span>
        <button
          type="button"
          className="voice-selector-retry"
          onClick={() => window.location.reload()}
        >
          Try Again
        </button>
      </div>
    )
  }

  return (
    <div className="voice-selector" ref={dropdownRef}>
      <label className="voice-selector-label">
        <span className="voice-selector-label-icon" aria-hidden="true">🎤</span>
        Voice
      </label>

      <button
        type="button"
        className={`voice-selector-trigger ${isOpen ? 'voice-selector-trigger-open' : ''}`}
        onClick={() => setIsOpen(!isOpen)}
        aria-expanded={isOpen}
        aria-haspopup="listbox"
      >
        {selectedVoice ? (
          <span className="voice-selector-selected">
            <span className="voice-selector-selected-name">{selectedVoice.name}</span>
            {selectedVoice.category && (
              <span className="voice-selector-selected-category">
                {getCategoryLabel(selectedVoice.category)}
              </span>
            )}
          </span>
        ) : (
          <span className="voice-selector-placeholder">Select a voice...</span>
        )}
        <span className="voice-selector-arrow" aria-hidden="true">
          {isOpen ? '▲' : '▼'}
        </span>
      </button>

      {isOpen && (
        <div className="voice-selector-dropdown" role="listbox">
          <div className="voice-selector-filter">
            <label className="voice-selector-filter-label">
              <input
                type="checkbox"
                checked={filterChildFriendly}
                onChange={(e) => setFilterChildFriendly(e.target.checked)}
              />
              <span>Child-friendly voices only</span>
            </label>
          </div>

          {filteredVoices.length === 0 ? (
            <div className="voice-selector-empty">
              No voices available
            </div>
          ) : (
            <ul className="voice-selector-list">
              {filteredVoices.map((voice) => (
                <li
                  key={voice.voiceId}
                  className={`voice-selector-option ${
                    selectedVoiceId === voice.voiceId ? 'voice-selector-option-selected' : ''
                  }`}
                  role="option"
                  aria-selected={selectedVoiceId === voice.voiceId}
                  onClick={() => handleSelectVoice(voice)}
                >
                  <div className="voice-selector-option-info">
                    <span className="voice-selector-option-name">{voice.name}</span>
                    {voice.category && (
                      <span className="voice-selector-option-category">
                        {getCategoryLabel(voice.category)}
                      </span>
                    )}
                    {voice.description && (
                      <span className="voice-selector-option-description">
                        {voice.description}
                      </span>
                    )}
                  </div>

                  {voice.previewUrl && (
                    <button
                      type="button"
                      className={`voice-selector-preview-btn ${
                        playingVoiceId === voice.voiceId ? 'voice-selector-preview-playing' : ''
                      }`}
                      onClick={(e) => handlePlayPreview(voice, e)}
                      aria-label={playingVoiceId === voice.voiceId ? 'Stop preview' : 'Play preview'}
                    >
                      {playingVoiceId === voice.voiceId ? '⏹' : '▶'}
                    </button>
                  )}
                </li>
              ))}
            </ul>
          )}
        </div>
      )}
    </div>
  )
}
