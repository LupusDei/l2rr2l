/* eslint-disable react-refresh/only-export-components */
import { createContext, useContext, useState, useCallback, useRef, useEffect, type ReactNode } from 'react'

export interface VoiceSettings {
  voiceId: string
  stability: number
  similarityBoost: number
  enabled: boolean
  encouragementEnabled: boolean
}

export interface PronunciationResult {
  isCorrect: boolean
  transcribed: string
  expected: string
  confidence: number
  feedback: string
}

interface VoiceContextValue {
  settings: VoiceSettings
  isLoading: boolean
  isSpeaking: boolean
  isRecording: boolean
  speak: (text: string) => Promise<void>
  updateSettings: (settings: Partial<VoiceSettings>) => void
  startRecording: () => Promise<void>
  stopRecording: () => Promise<Blob | null>
  checkPronunciation: (expectedWord: string) => Promise<PronunciationResult | null>
}

const DEFAULT_SETTINGS: VoiceSettings = {
  // Rachel - a friendly, warm voice good for children's content
  voiceId: 'EXAVITQu4vr4xnSDxMaL',
  stability: 0.5,
  similarityBoost: 0.75,
  enabled: true,
  encouragementEnabled: true,
}

const VoiceContext = createContext<VoiceContextValue | null>(null)

interface VoiceProviderProps {
  children: ReactNode
}

export function VoiceProvider({ children }: VoiceProviderProps) {
  const [settings, setSettings] = useState<VoiceSettings>(DEFAULT_SETTINGS)
  const [isLoading] = useState(false)
  const [isSpeaking, setIsSpeaking] = useState(false)
  const [isRecording, setIsRecording] = useState(false)
  const audioRef = useRef<HTMLAudioElement | null>(null)
  const queueRef = useRef<string[]>([])
  const isProcessingRef = useRef(false)
  const mediaRecorderRef = useRef<MediaRecorder | null>(null)
  const audioChunksRef = useRef<Blob[]>([])

  // Clean up audio element and speech synthesis on unmount
  useEffect(() => {
    return () => {
      if (audioRef.current) {
        audioRef.current.pause()
        audioRef.current = null
      }
      if (mediaRecorderRef.current && mediaRecorderRef.current.state !== 'inactive') {
        mediaRecorderRef.current.stop()
      }
      // Cancel any ongoing browser speech synthesis
      if ('speechSynthesis' in window) {
        window.speechSynthesis.cancel()
      }
    }
  }, [])

  // Fallback to browser's Web Speech API when server API is unavailable
  const speakWithBrowserFallback = useCallback((text: string): Promise<void> => {
    return new Promise((resolve) => {
      if (!('speechSynthesis' in window)) {
        console.warn('Web Speech API not available')
        resolve()
        return
      }

      const utterance = new SpeechSynthesisUtterance(text)
      utterance.rate = 0.9 // Slightly slower for children
      utterance.pitch = 1.0
      utterance.volume = 1.0

      utterance.onend = () => resolve()
      utterance.onerror = () => {
        console.warn('Browser speech synthesis failed')
        resolve()
      }

      window.speechSynthesis.speak(utterance)
    })
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
          // Server API unavailable - fall back to browser speech synthesis
          console.info('Voice API unavailable, using browser speech synthesis')
          await speakWithBrowserFallback(text)
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
        // Network error or other failure - fall back to browser speech synthesis
        console.info('Voice synthesis error, using browser fallback:', error)
        await speakWithBrowserFallback(text)
      }
    }

    isProcessingRef.current = false
    setIsSpeaking(false)
  }, [settings, speakWithBrowserFallback])

  const speak = useCallback(async (text: string) => {
    queueRef.current.push(text)
    await processQueue()
  }, [processQueue])

  const updateSettings = useCallback((newSettings: Partial<VoiceSettings>) => {
    setSettings(prev => ({ ...prev, ...newSettings }))
  }, [])

  const startRecording = useCallback(async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
      audioChunksRef.current = []

      const mediaRecorder = new MediaRecorder(stream, {
        mimeType: 'audio/webm;codecs=opus'
      })

      mediaRecorder.ondataavailable = (event) => {
        if (event.data.size > 0) {
          audioChunksRef.current.push(event.data)
        }
      }

      mediaRecorderRef.current = mediaRecorder
      mediaRecorder.start()
      setIsRecording(true)
    } catch (error) {
      console.error('Failed to start recording:', error)
      throw error
    }
  }, [])

  const stopRecording = useCallback(async (): Promise<Blob | null> => {
    return new Promise((resolve) => {
      const mediaRecorder = mediaRecorderRef.current
      if (!mediaRecorder || mediaRecorder.state === 'inactive') {
        setIsRecording(false)
        resolve(null)
        return
      }

      mediaRecorder.onstop = () => {
        const audioBlob = new Blob(audioChunksRef.current, { type: 'audio/webm' })

        // Stop all tracks to release the microphone
        mediaRecorder.stream.getTracks().forEach(track => track.stop())

        setIsRecording(false)
        mediaRecorderRef.current = null
        resolve(audioBlob)
      }

      mediaRecorder.stop()
    })
  }, [])

  const checkPronunciation = useCallback(async (expectedWord: string): Promise<PronunciationResult | null> => {
    const audioBlob = await stopRecording()
    if (!audioBlob) {
      return null
    }

    try {
      const formData = new FormData()
      formData.append('audio', audioBlob, 'recording.webm')
      formData.append('expectedWord', expectedWord)

      const response = await fetch('/api/voice/pronunciation-check', {
        method: 'POST',
        body: formData,
      })

      if (!response.ok) {
        console.warn('Pronunciation check failed')
        return null
      }

      return await response.json()
    } catch (error) {
      console.error('Pronunciation check error:', error)
      return null
    }
  }, [stopRecording])

  const value: VoiceContextValue = {
    settings,
    isLoading,
    isSpeaking,
    isRecording,
    speak,
    updateSettings,
    startRecording,
    stopRecording,
    checkPronunciation,
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
