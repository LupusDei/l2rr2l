/* eslint-disable react-refresh/only-export-components */
import { createContext, useContext, useState, useCallback, useRef, useEffect, type ReactNode } from 'react'

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

interface ApiVoiceSettings {
  voiceId?: string
  stability?: number
  similarityBoost?: number
  style?: number
  speed?: number
  useSpeakerBoost?: boolean
}

const VoiceContext = createContext<VoiceContextValue | null>(null)

interface VoiceProviderProps {
  children: ReactNode
}

export function VoiceProvider({ children }: VoiceProviderProps) {
  const [settings, setSettings] = useState<VoiceSettings>(DEFAULT_SETTINGS)
  const [isLoading, setIsLoading] = useState(true)
  const [isSpeaking, setIsSpeaking] = useState(false)
  const audioRef = useRef<HTMLAudioElement | null>(null)
  const queueRef = useRef<string[]>([])
  const isProcessingRef = useRef(false)

  // Load voice settings from API on mount
  useEffect(() => {
    const loadSettings = async () => {
      try {
        const response = await fetch('/api/voice/settings')
        if (response.ok) {
          const data: ApiVoiceSettings = await response.json()
          setSettings(prev => ({
            ...prev,
            voiceId: data.voiceId ?? prev.voiceId,
            stability: data.stability ?? prev.stability,
            similarityBoost: data.similarityBoost ?? prev.similarityBoost,
          }))
        }
        // If response is not ok (404, 503, etc.), silently use defaults
      } catch {
        // Network error or API unavailable - silently use defaults
        console.debug('Voice settings API unavailable, using defaults')
      } finally {
        setIsLoading(false)
      }
    }

    loadSettings()
  }, [])

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

        const audioBlob = await response.blob()
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
