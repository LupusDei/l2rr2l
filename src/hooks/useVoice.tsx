/* eslint-disable react-refresh/only-export-components */
import { createContext, useContext, useState, useCallback, useRef, useEffect, type ReactNode } from 'react'
import {
  getCachedAudio,
  setCachedAudio,
  clearAllCache,
  preCacheCommonPhrases,
} from '../services/audioCache'

export interface VoiceSettings {
  voiceId: string
  stability: number
  similarityBoost: number
  enabled: boolean
}

interface VoiceContextValue {
  settings: VoiceSettings
  isLoading: boolean
  isSpeaking: boolean
  isCaching: boolean
  speak: (text: string) => Promise<void>
  updateSettings: (settings: Partial<VoiceSettings>) => void
}

const DEFAULT_SETTINGS: VoiceSettings = {
  // Rachel - a friendly, warm voice good for children's content
  voiceId: 'EXAVITQu4vr4xnSDxMaL',
  stability: 0.5,
  similarityBoost: 0.75,
  enabled: true,
}

const VoiceContext = createContext<VoiceContextValue | null>(null)

interface VoiceProviderProps {
  children: ReactNode
}

export function VoiceProvider({ children }: VoiceProviderProps) {
  const [settings, setSettings] = useState<VoiceSettings>(DEFAULT_SETTINGS)
  const [isLoading] = useState(false)
  const [isSpeaking, setIsSpeaking] = useState(false)
  const [isCaching, setIsCaching] = useState(false)
  const audioRef = useRef<HTMLAudioElement | null>(null)
  const queueRef = useRef<string[]>([])
  const isProcessingRef = useRef(false)
  const prevSettingsRef = useRef<VoiceSettings>(DEFAULT_SETTINGS)

  // Pre-cache common phrases on mount
  useEffect(() => {
    const doPreCache = async () => {
      setIsCaching(true)
      try {
        await preCacheCommonPhrases({
          voiceId: settings.voiceId,
          stability: settings.stability,
          similarityBoost: settings.similarityBoost,
        })
      } catch {
        // Pre-caching is optional, continue without it
      } finally {
        setIsCaching(false)
      }
    }
    doPreCache()
    // Only run on mount
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  // Invalidate cache when voice settings change
  useEffect(() => {
    const prev = prevSettingsRef.current
    const settingsChanged =
      prev.voiceId !== settings.voiceId ||
      prev.stability !== settings.stability ||
      prev.similarityBoost !== settings.similarityBoost

    if (settingsChanged) {
      // Clear cache and re-cache for new settings
      const doInvalidateAndReCache = async () => {
        setIsCaching(true)
        try {
          await clearAllCache()
          await preCacheCommonPhrases({
            voiceId: settings.voiceId,
            stability: settings.stability,
            similarityBoost: settings.similarityBoost,
          })
        } catch {
          // Continue without caching
        } finally {
          setIsCaching(false)
        }
      }
      doInvalidateAndReCache()
    }
    prevSettingsRef.current = settings
  }, [settings])

  // Clean up audio element on unmount
  useEffect(() => {
    return () => {
      if (audioRef.current) {
        audioRef.current.pause()
        audioRef.current = null
      }
    }
  }, [])

  const processQueue = useCallback(async () => {
    if (isProcessingRef.current || queueRef.current.length === 0) {
      return
    }

    isProcessingRef.current = true
    setIsSpeaking(true)

    while (queueRef.current.length > 0) {
      const text = queueRef.current.shift()!

      if (!settings.enabled) {
        continue
      }

      try {
        // Check cache first
        let audioBlob = await getCachedAudio(
          settings.voiceId,
          settings.stability,
          settings.similarityBoost,
          text
        )

        // Fetch from API if not cached
        if (!audioBlob) {
          const response = await fetch('/api/voice/tts', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({
              voiceId: settings.voiceId,
              text,
              voiceSettings: {
                stability: settings.stability,
                similarityBoost: settings.similarityBoost,
              },
            }),
          })

          if (!response.ok) {
            console.warn('Voice API failed, continuing silently')
            continue
          }

          audioBlob = await response.blob()

          // Cache for future use
          await setCachedAudio(
            settings.voiceId,
            settings.stability,
            settings.similarityBoost,
            text,
            audioBlob
          )
        }

        const audioUrl = URL.createObjectURL(audioBlob)

        await new Promise<void>((resolve) => {
          const audio = new Audio(audioUrl)
          audioRef.current = audio

          audio.onended = () => {
            URL.revokeObjectURL(audioUrl)
            audioRef.current = null
            resolve()
          }

          audio.onerror = () => {
            URL.revokeObjectURL(audioUrl)
            audioRef.current = null
            console.warn('Audio playback failed')
            resolve()
          }

          audio.play().catch(() => {
            URL.revokeObjectURL(audioUrl)
            audioRef.current = null
            console.warn('Audio playback failed')
            resolve()
          })
        })
      } catch (error) {
        console.warn('Voice synthesis failed, continuing silently:', error)
      }
    }

    isProcessingRef.current = false
    setIsSpeaking(false)
  }, [settings])

  const speak = useCallback(async (text: string) => {
    queueRef.current.push(text)
    await processQueue()
  }, [processQueue])

  const updateSettings = useCallback((newSettings: Partial<VoiceSettings>) => {
    setSettings(prev => ({ ...prev, ...newSettings }))
  }, [])

  const value: VoiceContextValue = {
    settings,
    isLoading,
    isSpeaking,
    isCaching,
    speak,
    updateSettings,
  }

  return (
    <VoiceContext.Provider value={value}>
      {children}
    </VoiceContext.Provider>
  )
}

export function useVoice(): VoiceContextValue {
  const context = useContext(VoiceContext)
  if (!context) {
    throw new Error('useVoice must be used within a VoiceProvider')
  }
  return context
}
