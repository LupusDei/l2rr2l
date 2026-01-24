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
  // Jessica - a clear, friendly voice good for children's learning
  voiceId: 'cgSgspJ2msm6clMCkdW9',
  stability: 0.5,
  similarityBoost: 0.75,
  enabled: true,
  encouragementEnabled: true,
}

// LocalStorage key for voice settings (must match Settings.tsx)
const STORAGE_KEY = 'l2rr2l_voice_settings_dev-child-1'

// Load settings from localStorage or use defaults
function loadSettingsFromStorage(): VoiceSettings {
  try {
    const cached = localStorage.getItem(STORAGE_KEY)
    if (cached) {
      const parsed = JSON.parse(cached)
      return {
        voiceId: parsed.voiceId || DEFAULT_SETTINGS.voiceId,
        stability: parsed.stability ?? DEFAULT_SETTINGS.stability,
        similarityBoost: parsed.similarityBoost ?? DEFAULT_SETTINGS.similarityBoost,
        enabled: parsed.enabled ?? DEFAULT_SETTINGS.enabled,
        encouragementEnabled: parsed.encouragementEnabled ?? DEFAULT_SETTINGS.encouragementEnabled,
      }
    }
  } catch {
    // Ignore localStorage errors
  }
  return DEFAULT_SETTINGS
}

const VoiceContext = createContext<VoiceContextValue | null>(null)

// Web Speech API types
interface SpeechRecognitionEvent extends Event {
  results: SpeechRecognitionResultList
}

interface SpeechRecognitionErrorEvent extends Event {
  error: string
}

interface SpeechRecognitionResultList {
  readonly length: number
  [index: number]: SpeechRecognitionResult
}

interface SpeechRecognitionResult {
  readonly length: number
  [index: number]: SpeechRecognitionAlternative
}

interface SpeechRecognitionAlternative {
  transcript: string
  confidence: number
}

interface SpeechRecognitionInstance extends EventTarget {
  continuous: boolean
  interimResults: boolean
  lang: string
  maxAlternatives: number
  onresult: ((event: SpeechRecognitionEvent) => void) | null
  onerror: ((event: SpeechRecognitionErrorEvent) => void) | null
  start(): void
  stop(): void
  abort(): void
}

interface SpeechRecognitionConstructor {
  new (): SpeechRecognitionInstance
}

// Extend Window interface for SpeechRecognition
declare global {
  interface Window {
    SpeechRecognition?: SpeechRecognitionConstructor
    webkitSpeechRecognition?: SpeechRecognitionConstructor
  }
}

interface VoiceProviderProps {
  children: ReactNode
}

// Feedback message helpers
function getPositiveFeedback(): string {
  const messages = ['Great job!', 'Perfect!', 'You said it!', 'Excellent!', 'Wonderful!', 'Amazing!']
  return messages[Math.floor(Math.random() * messages.length)]
}

function getEncouragingFeedback(word: string): string {
  const messages = [
    `Try again! Say "${word}"`,
    `Almost! Try saying "${word}" again`,
    `Good try! Can you say "${word}"?`,
    `Let's try "${word}" one more time!`,
  ]
  return messages[Math.floor(Math.random() * messages.length)]
}

export function VoiceProvider({ children }: VoiceProviderProps) {
  // Load settings from localStorage on mount (lazy initialization)
  const [settings, setSettings] = useState<VoiceSettings>(loadSettingsFromStorage)
  const [isLoading] = useState(false)
  const [isSpeaking, setIsSpeaking] = useState(false)
  const [isRecording, setIsRecording] = useState(false)
  const audioRef = useRef<HTMLAudioElement | null>(null)
  const queueRef = useRef<string[]>([])
  const isProcessingRef = useRef(false)
  const mediaRecorderRef = useRef<MediaRecorder | null>(null)
  const audioChunksRef = useRef<Blob[]>([])
  const audioUnlockedRef = useRef(false)

  // Browser speech recognition refs for fallback
  const speechRecognitionRef = useRef<SpeechRecognitionInstance | null>(null)
  const browserRecognitionResultRef = useRef<{ transcribed: string; confidence: number } | null>(null)

  // iOS/Safari requires audio to be "unlocked" with a user gesture
  // This runs a silent utterance on first touch to enable audio playback
  useEffect(() => {
    const unlockAudio = () => {
      if (audioUnlockedRef.current) return
      audioUnlockedRef.current = true

      // Unlock Web Speech API on iOS
      if ('speechSynthesis' in window) {
        const utterance = new SpeechSynthesisUtterance('')
        utterance.volume = 0
        window.speechSynthesis.speak(utterance)
      }

      // Unlock Audio context by playing a silent sound
      const silentAudio = new Audio('data:audio/mp3;base64,SUQzBAAAAAAAI1RTU0UAAAAPAAADTGF2ZjU4Ljc2LjEwMAAAAAAAAAAAAAAA//tQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWGluZwAAAA8AAAACAAABhgC7u7u7u7u7u7u7u7u7u7u7u7u7u7u7u7u7u7u7u7u7u7u7u7u7u7u7u7u7u7u7u7u7u7u7//////////////////////////////////////////////////////////////////8AAAAATGF2YzU4LjEzAAAAAAAAAAAAAAAAJAAAAAAAAAAAAYYoRwmHAAAAAAD/+1DEAAAGAAGn9AAAIgAANP8AAARMQAABNAAAAAAANIAAAAAA0gAAAAAMCAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICA//tQxAADwAABpAAAACAAADSAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP/7UMQ/g8AAAaQAAAAgAAA0gAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA')
      silentAudio.play().catch(() => {
        // Ignore errors - this is just to unlock
      })

      // Remove listeners after unlocking
      document.removeEventListener('touchstart', unlockAudio)
      document.removeEventListener('click', unlockAudio)
    }

    // Add listeners for first user interaction
    document.addEventListener('touchstart', unlockAudio, { once: true })
    document.addEventListener('click', unlockAudio, { once: true })

    return () => {
      document.removeEventListener('touchstart', unlockAudio)
      document.removeEventListener('click', unlockAudio)
    }
  }, [])

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
      if (speechRecognitionRef.current) {
        speechRecognitionRef.current.abort()
        speechRecognitionRef.current = null
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

      // iOS Safari fix: cancel any pending speech and resume if paused
      const synth = window.speechSynthesis
      synth.cancel()

      // iOS sometimes needs a small delay after cancel
      setTimeout(() => {
        const utterance = new SpeechSynthesisUtterance(text)
        utterance.rate = 0.9 // Slightly slower for children
        utterance.pitch = 1.0
        utterance.volume = 1.0
        utterance.lang = 'en-US'

        // Set a timeout in case onend never fires (iOS bug)
        const timeoutId = setTimeout(() => {
          console.warn('Speech synthesis timeout, resolving')
          resolve()
        }, 10000) // 10 second max

        utterance.onend = () => {
          clearTimeout(timeoutId)
          resolve()
        }

        utterance.onerror = (event) => {
          clearTimeout(timeoutId)
          console.warn('Browser speech synthesis failed:', event)
          resolve()
        }

        synth.speak(utterance)

        // iOS Safari fix: resume if paused (happens on backgrounding)
        if (synth.paused) {
          synth.resume()
        }
      }, 50)
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
            console.warn('Audio playback failed, trying browser TTS')
            // Fall back to browser TTS on iOS when audio fails
            speakWithBrowserFallback(text).then(resolve)
          }

          audio.play().catch(async () => {
            URL.revokeObjectURL(audioUrl)
            audioRef.current = null
            console.warn('Audio play rejected (iOS?), using browser TTS')
            // Fall back to browser TTS when play() is rejected (common on iOS)
            await speakWithBrowserFallback(text)
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

  // Start browser speech recognition in parallel with MediaRecorder for fallback
  const startBrowserSpeechRecognition = useCallback(() => {
    const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition
    if (!SpeechRecognition) {
      console.info('Browser speech recognition not available')
      return
    }

    // Clear previous result
    browserRecognitionResultRef.current = null

    const recognition = new SpeechRecognition()
    recognition.continuous = false
    recognition.interimResults = false
    recognition.lang = 'en-US'
    recognition.maxAlternatives = 1

    recognition.onresult = (event) => {
      const result = event.results[0]
      browserRecognitionResultRef.current = {
        transcribed: result[0].transcript,
        confidence: result[0].confidence,
      }
    }

    recognition.onerror = (event) => {
      // Store error info for fallback to provide appropriate feedback
      if (event.error === 'no-speech') {
        browserRecognitionResultRef.current = { transcribed: '', confidence: 0 }
      }
      console.info('Browser speech recognition error (will use for fallback):', event.error)
    }

    speechRecognitionRef.current = recognition

    try {
      recognition.start()
    } catch (error) {
      console.info('Failed to start browser speech recognition:', error)
    }
  }, [])

  // Stop browser speech recognition
  const stopBrowserSpeechRecognition = useCallback(() => {
    if (speechRecognitionRef.current) {
      try {
        speechRecognitionRef.current.stop()
      } catch {
        // Ignore errors when stopping
      }
      speechRecognitionRef.current = null
    }
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

      // Also start browser speech recognition in parallel for fallback
      startBrowserSpeechRecognition()

      setIsRecording(true)
    } catch (error) {
      console.error('Failed to start recording:', error)
      throw error
    }
  }, [startBrowserSpeechRecognition])

  const stopRecording = useCallback(async (): Promise<Blob | null> => {
    // Stop browser speech recognition
    stopBrowserSpeechRecognition()

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
  }, [stopBrowserSpeechRecognition])

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
        // Server API unavailable - fall back to browser speech recognition result
        console.info('Pronunciation API unavailable, using browser speech recognition fallback')
        return getBrowserRecognitionFallback(expectedWord)
      }

      return await response.json()
    } catch (error) {
      // Network error or other failure - fall back to browser speech recognition result
      console.info('Pronunciation check error, using browser fallback:', error)
      return getBrowserRecognitionFallback(expectedWord)
    }

    function getBrowserRecognitionFallback(expectedWord: string): PronunciationResult {
      const browserResult = browserRecognitionResultRef.current

      // Check if browser speech recognition is even available
      const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition
      if (!SpeechRecognition) {
        return {
          isCorrect: false,
          transcribed: '',
          expected: expectedWord,
          confidence: 0,
          feedback: 'Speech recognition is not available in your browser. Try using Chrome or Edge.',
        }
      }

      if (!browserResult || browserResult.transcribed === '') {
        return {
          isCorrect: false,
          transcribed: '',
          expected: expectedWord,
          confidence: 0,
          feedback: `I didn't hear anything. Try saying "${expectedWord}" again.`,
        }
      }

      // Normalize for comparison
      const transcribedNormalized = browserResult.transcribed.toLowerCase().trim()
      const expectedNormalized = expectedWord.toLowerCase().trim()

      const isCorrect =
        transcribedNormalized === expectedNormalized ||
        transcribedNormalized.includes(expectedNormalized)

      return {
        isCorrect,
        transcribed: browserResult.transcribed,
        expected: expectedWord,
        confidence: browserResult.confidence,
        feedback: isCorrect ? getPositiveFeedback() : getEncouragingFeedback(expectedWord),
      }
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
