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

// Extend Window interface for SpeechRecognition
declare global {
  interface Window {
    SpeechRecognition: typeof SpeechRecognition
    webkitSpeechRecognition: typeof SpeechRecognition
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
  const [settings, setSettings] = useState<VoiceSettings>(DEFAULT_SETTINGS)
  const [isLoading] = useState(false)
  const [isSpeaking, setIsSpeaking] = useState(false)
  const [isRecording, setIsRecording] = useState(false)
  const audioRef = useRef<HTMLAudioElement | null>(null)
  const queueRef = useRef<string[]>([])
  const isProcessingRef = useRef(false)
  const mediaRecorderRef = useRef<MediaRecorder | null>(null)
  const audioChunksRef = useRef<Blob[]>([])

  // Browser speech recognition refs for fallback
  const speechRecognitionRef = useRef<SpeechRecognition | null>(null)
  const browserRecognitionResultRef = useRef<{ transcribed: string; confidence: number } | null>(null)

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
