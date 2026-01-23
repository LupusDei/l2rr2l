import { useState, useEffect, useCallback, useRef } from 'react'
import VoiceSelector, { type Voice } from './VoiceSelector'
import VoiceParameterSliders, { type VoiceSettings } from './VoiceParameterSliders'
import './Settings.css'

export interface FullVoiceSettings extends VoiceSettings {
  voiceId: string
}

interface SettingsProps {
  childId: string
  onBack: () => void
  onSettingsChange?: (settings: FullVoiceSettings) => void
}

type SaveStatus = 'idle' | 'saving' | 'saved' | 'error'

export default function Settings({ childId, onBack, onSettingsChange }: SettingsProps) {
  const [settings, setSettings] = useState<FullVoiceSettings | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [loadError, setLoadError] = useState<string | null>(null)
  const [saveStatus, setSaveStatus] = useState<SaveStatus>('idle')
  const [saveError, setSaveError] = useState<string | null>(null)

  const saveTimeoutRef = useRef<number | null>(null)
  const toastTimeoutRef = useRef<number | null>(null)

  // Load settings on mount
  useEffect(() => {
    const loadSettings = async () => {
      try {
        setIsLoading(true)
        setLoadError(null)

        const response = await fetch(`/api/voice/settings/${childId}`)
        if (!response.ok) {
          throw new Error('Failed to load settings')
        }

        const data = await response.json()
        setSettings(data)
      } catch (err) {
        setLoadError(err instanceof Error ? err.message : 'Failed to load settings')
      } finally {
        setIsLoading(false)
      }
    }

    loadSettings()
  }, [childId])

  // Cleanup timeouts on unmount
  useEffect(() => {
    return () => {
      if (saveTimeoutRef.current) {
        clearTimeout(saveTimeoutRef.current)
      }
      if (toastTimeoutRef.current) {
        clearTimeout(toastTimeoutRef.current)
      }
    }
  }, [])

  // Save settings to API with debounce
  const saveSettings = useCallback(async (newSettings: FullVoiceSettings) => {
    // Clear any pending save
    if (saveTimeoutRef.current) {
      clearTimeout(saveTimeoutRef.current)
    }

    // Debounce the save
    saveTimeoutRef.current = window.setTimeout(async () => {
      try {
        setSaveStatus('saving')
        setSaveError(null)

        const response = await fetch(`/api/voice/settings/${childId}`, {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(newSettings),
        })

        if (!response.ok) {
          const data = await response.json()
          throw new Error(data.error || 'Failed to save settings')
        }

        setSaveStatus('saved')

        // Clear the "saved" toast after 2 seconds
        if (toastTimeoutRef.current) {
          clearTimeout(toastTimeoutRef.current)
        }
        toastTimeoutRef.current = window.setTimeout(() => {
          setSaveStatus('idle')
        }, 2000)
      } catch (err) {
        setSaveStatus('error')
        setSaveError(err instanceof Error ? err.message : 'Failed to save settings')

        // Clear error after 5 seconds
        if (toastTimeoutRef.current) {
          clearTimeout(toastTimeoutRef.current)
        }
        toastTimeoutRef.current = window.setTimeout(() => {
          setSaveStatus('idle')
          setSaveError(null)
        }, 5000)
      }
    }, 500) // 500ms debounce
  }, [childId])

  const handleVoiceSelect = useCallback((voice: Voice) => {
    if (!settings) return

    const newSettings = { ...settings, voiceId: voice.voiceId }
    setSettings(newSettings)
    onSettingsChange?.(newSettings)
    saveSettings(newSettings)
  }, [settings, onSettingsChange, saveSettings])

  const handleParameterChange = useCallback((paramSettings: VoiceSettings) => {
    if (!settings) return

    const newSettings = { ...settings, ...paramSettings }
    setSettings(newSettings)
    onSettingsChange?.(newSettings)
    saveSettings(newSettings)
  }, [settings, onSettingsChange, saveSettings])

  if (isLoading) {
    return (
      <div className="settings">
        <header className="settings-header">
          <button className="settings-back-btn" type="button" onClick={onBack}>
            <span aria-hidden="true">&larr;</span> Back
          </button>
          <h1 className="settings-title">Settings</h1>
        </header>
        <div className="settings-loading">
          <span className="settings-spinner" aria-hidden="true">&#9881;</span>
          <span>Loading settings...</span>
        </div>
      </div>
    )
  }

  if (loadError) {
    return (
      <div className="settings">
        <header className="settings-header">
          <button className="settings-back-btn" type="button" onClick={onBack}>
            <span aria-hidden="true">&larr;</span> Back
          </button>
          <h1 className="settings-title">Settings</h1>
        </header>
        <div className="settings-error">
          <span className="settings-error-icon" aria-hidden="true">&#9888;</span>
          <span>{loadError}</span>
          <button
            type="button"
            className="settings-retry-btn"
            onClick={() => window.location.reload()}
          >
            Try Again
          </button>
        </div>
      </div>
    )
  }

  return (
    <div className="settings">
      <header className="settings-header">
        <button className="settings-back-btn" type="button" onClick={onBack}>
          <span aria-hidden="true">&larr;</span> Back
        </button>
        <h1 className="settings-title">Settings</h1>
        <div className="settings-status">
          {saveStatus === 'saving' && (
            <span className="save-indicator saving">
              <span className="save-spinner" aria-hidden="true">&#8987;</span>
              Saving...
            </span>
          )}
          {saveStatus === 'saved' && (
            <span className="save-indicator saved">
              <span aria-hidden="true">&#10003;</span>
              Saved!
            </span>
          )}
          {saveStatus === 'error' && (
            <span className="save-indicator error" title={saveError || undefined}>
              <span aria-hidden="true">&#10007;</span>
              Error saving
            </span>
          )}
        </div>
      </header>

      <main className="settings-content">
        <section className="settings-section">
          <h2 className="settings-section-title">
            <span aria-hidden="true">&#127908;</span>
            Voice Settings
          </h2>
          <p className="settings-section-description">
            Choose a voice and adjust how it sounds. Changes are saved automatically.
          </p>

          <div className="settings-voice-selector">
            <VoiceSelector
              selectedVoiceId={settings?.voiceId}
              onVoiceSelect={handleVoiceSelect}
              showChildFriendlyOnly={true}
            />
          </div>

          <div className="settings-voice-parameters">
            <VoiceParameterSliders
              voiceId={settings?.voiceId}
              initialSettings={settings ? {
                speed: settings.speed,
                stability: settings.stability,
                similarityBoost: settings.similarityBoost,
                style: settings.style,
                useSpeakerBoost: settings.useSpeakerBoost,
              } : undefined}
              onChange={handleParameterChange}
            />
          </div>
        </section>
      </main>

      {/* Toast notifications */}
      {saveStatus === 'error' && saveError && (
        <div className="settings-toast error" role="alert">
          <span className="toast-icon" aria-hidden="true">&#9888;</span>
          <span className="toast-message">{saveError}</span>
          <button
            type="button"
            className="toast-close"
            onClick={() => {
              setSaveStatus('idle')
              setSaveError(null)
            }}
            aria-label="Dismiss"
          >
            &times;
          </button>
        </div>
      )}
    </div>
  )
}
