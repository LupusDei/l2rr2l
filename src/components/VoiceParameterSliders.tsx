import { useState, useRef, useCallback } from 'react'
import './VoiceParameterSliders.css'

export interface VoiceSettings {
  speed: number
  stability: number
  similarityBoost: number
  style: number
  useSpeakerBoost: boolean
}

const DEFAULT_SETTINGS: VoiceSettings = {
  speed: 1.0,
  stability: 0.5,
  similarityBoost: 0.75,
  style: 0,
  useSpeakerBoost: true,
}

interface SliderConfig {
  key: keyof Omit<VoiceSettings, 'useSpeakerBoost'>
  label: string
  icon: string
  min: number
  max: number
  step: number
  tooltip: string
  formatValue: (value: number) => string
}

const SLIDER_CONFIGS: SliderConfig[] = [
  {
    key: 'speed',
    label: 'Speed',
    icon: '🚀',
    min: 0.5,
    max: 2.0,
    step: 0.1,
    tooltip: 'How fast the voice speaks. Slower can be easier to understand, faster for quick readers!',
    formatValue: (v) => `${v.toFixed(1)}x`,
  },
  {
    key: 'stability',
    label: 'Stability',
    icon: '⚖️',
    min: 0,
    max: 1,
    step: 0.05,
    tooltip: 'How consistent the voice sounds. Higher means more predictable, lower is more expressive!',
    formatValue: (v) => `${Math.round(v * 100)}%`,
  },
  {
    key: 'similarityBoost',
    label: 'Clarity',
    icon: '✨',
    min: 0,
    max: 1,
    step: 0.05,
    tooltip: 'How clear and crisp the voice sounds. Higher makes words easier to hear!',
    formatValue: (v) => `${Math.round(v * 100)}%`,
  },
  {
    key: 'style',
    label: 'Style',
    icon: '🎭',
    min: 0,
    max: 1,
    step: 0.05,
    tooltip: 'How expressive and dramatic the voice is. Lower is calm, higher is more animated!',
    formatValue: (v) => `${Math.round(v * 100)}%`,
  },
]

const TEST_PHRASES = [
  "Hello! Let's learn to read together!",
  "The quick brown fox jumps over the lazy dog.",
  "Can you spell the word 'cat'?",
  "Great job! You're doing amazing!",
]

interface VoiceParameterSlidersProps {
  voiceId?: string
  initialSettings?: Partial<VoiceSettings>
  onChange?: (settings: VoiceSettings) => void
  onSave?: (settings: VoiceSettings) => void
}

export default function VoiceParameterSliders({
  voiceId,
  initialSettings,
  onChange,
  onSave,
}: VoiceParameterSlidersProps) {
  const [settings, setSettings] = useState<VoiceSettings>({
    ...DEFAULT_SETTINGS,
    ...initialSettings,
  })
  const [activeTooltip, setActiveTooltip] = useState<string | null>(null)
  const [isPlaying, setIsPlaying] = useState(false)
  const [testPhraseIndex, setTestPhraseIndex] = useState(0)
  const audioRef = useRef<HTMLAudioElement | null>(null)

  const updateSetting = useCallback(
    <K extends keyof VoiceSettings>(key: K, value: VoiceSettings[K]) => {
      setSettings((prev) => {
        const newSettings = { ...prev, [key]: value }
        onChange?.(newSettings)
        return newSettings
      })
    },
    [onChange]
  )

  const handleReset = useCallback(() => {
    setSettings(DEFAULT_SETTINGS)
    onChange?.(DEFAULT_SETTINGS)
  }, [onChange])

  const handleSave = useCallback(() => {
    onSave?.(settings)
  }, [onSave, settings])

  const handlePreview = useCallback(async () => {
    if (!voiceId || isPlaying) return

    setIsPlaying(true)

    try {
      // Stop any existing audio
      if (audioRef.current) {
        audioRef.current.pause()
        audioRef.current = null
      }

      const response = await fetch('/api/voice/tts', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          voiceId,
          text: TEST_PHRASES[testPhraseIndex],
          voiceSettings: {
            stability: settings.stability,
            similarityBoost: settings.similarityBoost,
            style: settings.style,
            useSpeakerBoost: settings.useSpeakerBoost,
          },
        }),
      })

      if (!response.ok) {
        throw new Error('Failed to generate speech')
      }

      const audioBlob = await response.blob()
      const audioUrl = URL.createObjectURL(audioBlob)
      const audio = new Audio(audioUrl)

      // Apply speed setting via playback rate
      audio.playbackRate = settings.speed

      audio.onended = () => {
        setIsPlaying(false)
        URL.revokeObjectURL(audioUrl)
        setTestPhraseIndex((i) => (i + 1) % TEST_PHRASES.length)
      }

      audio.onerror = () => {
        setIsPlaying(false)
        URL.revokeObjectURL(audioUrl)
      }

      audioRef.current = audio
      await audio.play()
    } catch (error) {
      console.error('Preview failed:', error)
      setIsPlaying(false)
    }
  }, [voiceId, isPlaying, testPhraseIndex, settings])

  const handleStopPreview = useCallback(() => {
    if (audioRef.current) {
      audioRef.current.pause()
      audioRef.current = null
    }
    setIsPlaying(false)
  }, [])

  const hasChanges =
    settings.speed !== DEFAULT_SETTINGS.speed ||
    settings.stability !== DEFAULT_SETTINGS.stability ||
    settings.similarityBoost !== DEFAULT_SETTINGS.similarityBoost ||
    settings.style !== DEFAULT_SETTINGS.style ||
    settings.useSpeakerBoost !== DEFAULT_SETTINGS.useSpeakerBoost

  return (
    <div className="voice-sliders">
      <div className="voice-sliders-header">
        <h3 className="voice-sliders-title">
          <span className="title-icon">🎙️</span>
          Voice Settings
        </h3>
        {hasChanges && (
          <button
            type="button"
            className="reset-button"
            onClick={handleReset}
            aria-label="Reset to defaults"
          >
            ↺ Reset
          </button>
        )}
      </div>

      <div className="sliders-container">
        {SLIDER_CONFIGS.map((config) => (
          <div key={config.key} className="slider-row">
            <div className="slider-label-row">
              <label className="slider-label" htmlFor={`slider-${config.key}`}>
                <span className="slider-icon">{config.icon}</span>
                {config.label}
              </label>
              <button
                type="button"
                className="tooltip-trigger"
                onClick={() =>
                  setActiveTooltip(activeTooltip === config.key ? null : config.key)
                }
                aria-label={`Info about ${config.label}`}
              >
                ?
              </button>
              <span className="slider-value">{config.formatValue(settings[config.key])}</span>
            </div>

            {activeTooltip === config.key && (
              <div className="tooltip-content">{config.tooltip}</div>
            )}

            <input
              id={`slider-${config.key}`}
              type="range"
              className="slider-input"
              min={config.min}
              max={config.max}
              step={config.step}
              value={settings[config.key]}
              onChange={(e) => updateSetting(config.key, parseFloat(e.target.value))}
              style={
                {
                  '--slider-progress': `${
                    ((settings[config.key] - config.min) / (config.max - config.min)) * 100
                  }%`,
                } as React.CSSProperties
              }
            />
          </div>
        ))}

        {/* Speaker Boost Toggle */}
        <div className="toggle-row">
          <div className="toggle-label-row">
            <label className="slider-label" htmlFor="toggle-speaker-boost">
              <span className="slider-icon">🔊</span>
              Speaker Boost
            </label>
            <button
              type="button"
              className="tooltip-trigger"
              onClick={() =>
                setActiveTooltip(
                  activeTooltip === 'speakerBoost' ? null : 'speakerBoost'
                )
              }
              aria-label="Info about Speaker Boost"
            >
              ?
            </button>
          </div>

          {activeTooltip === 'speakerBoost' && (
            <div className="tooltip-content">
              Makes the voice sound clearer and more natural. Keep it on for best
              quality!
            </div>
          )}

          <button
            id="toggle-speaker-boost"
            type="button"
            className={`toggle-button ${settings.useSpeakerBoost ? 'active' : ''}`}
            onClick={() => updateSetting('useSpeakerBoost', !settings.useSpeakerBoost)}
            aria-pressed={settings.useSpeakerBoost}
          >
            <span className="toggle-track">
              <span className="toggle-thumb" />
            </span>
            <span className="toggle-label-text">
              {settings.useSpeakerBoost ? 'On' : 'Off'}
            </span>
          </button>
        </div>
      </div>

      {/* Preview Section */}
      <div className="preview-section">
        <div className="preview-header">
          <span className="preview-icon">🎧</span>
          <span className="preview-title">Test Voice</span>
        </div>
        <p className="preview-phrase">"{TEST_PHRASES[testPhraseIndex]}"</p>
        <div className="preview-buttons">
          {isPlaying ? (
            <button
              type="button"
              className="preview-button stop"
              onClick={handleStopPreview}
            >
              <span className="button-icon">⏹️</span>
              Stop
            </button>
          ) : (
            <button
              type="button"
              className="preview-button play"
              onClick={handlePreview}
              disabled={!voiceId}
            >
              <span className="button-icon">▶️</span>
              Play Preview
            </button>
          )}
        </div>
        {!voiceId && (
          <p className="preview-hint">Select a voice above to preview</p>
        )}
      </div>

      {/* Save Button */}
      {onSave && (
        <button type="button" className="save-button" onClick={handleSave}>
          <span className="button-icon">💾</span>
          Save Settings
        </button>
      )}
    </div>
  )
}
