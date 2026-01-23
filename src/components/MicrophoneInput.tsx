import { useState, useCallback, useRef, useEffect } from 'react'
import './MicrophoneInput.css'

export interface MicrophoneInputProps {
  onRecordingComplete: (audioBlob: Blob) => void
  onRecordingStart?: () => void
  onRecordingStop?: () => void
  disabled?: boolean
  maxDuration?: number // in milliseconds, default 30000 (30 seconds)
}

type RecordingState = 'idle' | 'requesting' | 'recording' | 'stopped'

export default function MicrophoneInput({
  onRecordingComplete,
  onRecordingStart,
  onRecordingStop,
  disabled = false,
  maxDuration = 30000,
}: MicrophoneInputProps) {
  const [state, setState] = useState<RecordingState>('idle')
  const [error, setError] = useState<string | null>(null)
  const [audioLevel, setAudioLevel] = useState(0)
  const [recordingTime, setRecordingTime] = useState(0)

  const mediaRecorderRef = useRef<MediaRecorder | null>(null)
  const audioContextRef = useRef<AudioContext | null>(null)
  const analyserRef = useRef<AnalyserNode | null>(null)
  const streamRef = useRef<MediaStream | null>(null)
  const chunksRef = useRef<Blob[]>([])
  const animationFrameRef = useRef<number | null>(null)
  const timerRef = useRef<number | null>(null)
  const maxDurationTimerRef = useRef<number | null>(null)

  // Use refs to break circular dependencies
  const stopRecordingRef = useRef<() => void>(() => {})

  // Clean up on unmount
  useEffect(() => {
    return () => {
      if (animationFrameRef.current) {
        cancelAnimationFrame(animationFrameRef.current)
      }
      if (timerRef.current) {
        clearInterval(timerRef.current)
      }
      if (maxDurationTimerRef.current) {
        clearTimeout(maxDurationTimerRef.current)
      }
      if (streamRef.current) {
        streamRef.current.getTracks().forEach(track => track.stop())
      }
      if (audioContextRef.current) {
        audioContextRef.current.close()
      }
    }
  }, [])

  // Audio level update loop using regular function to avoid dependency issues
  const startAudioLevelLoop = useCallback(() => {
    const updateLevel = () => {
      if (!analyserRef.current) return

      const dataArray = new Uint8Array(analyserRef.current.frequencyBinCount)
      analyserRef.current.getByteFrequencyData(dataArray)

      // Calculate average level
      const average = dataArray.reduce((sum, value) => sum + value, 0) / dataArray.length
      // Normalize to 0-1 range
      const normalizedLevel = Math.min(average / 128, 1)
      setAudioLevel(normalizedLevel)

      animationFrameRef.current = requestAnimationFrame(updateLevel)
    }
    updateLevel()
  }, [])

  const stopRecording = useCallback(() => {
    if (animationFrameRef.current) {
      cancelAnimationFrame(animationFrameRef.current)
      animationFrameRef.current = null
    }

    if (timerRef.current) {
      clearInterval(timerRef.current)
      timerRef.current = null
    }

    if (maxDurationTimerRef.current) {
      clearTimeout(maxDurationTimerRef.current)
      maxDurationTimerRef.current = null
    }

    if (mediaRecorderRef.current && mediaRecorderRef.current.state === 'recording') {
      mediaRecorderRef.current.stop()
    }

    if (streamRef.current) {
      streamRef.current.getTracks().forEach(track => track.stop())
      streamRef.current = null
    }

    if (audioContextRef.current) {
      audioContextRef.current.close()
      audioContextRef.current = null
    }

    setAudioLevel(0)
    setState('stopped')
    onRecordingStop?.()

    // Reset to idle after a brief moment
    setTimeout(() => {
      setState('idle')
      setRecordingTime(0)
    }, 500)
  }, [onRecordingStop])

  // Keep ref updated with latest stopRecording
  useEffect(() => {
    stopRecordingRef.current = stopRecording
  }, [stopRecording])

  const startRecording = useCallback(async () => {
    setError(null)
    setState('requesting')

    try {
      const stream = await navigator.mediaDevices.getUserMedia({
        audio: {
          echoCancellation: true,
          noiseSuppression: true,
          sampleRate: 44100,
        },
      })

      streamRef.current = stream

      // Set up audio analysis for level visualization
      const audioContext = new AudioContext()
      audioContextRef.current = audioContext
      const source = audioContext.createMediaStreamSource(stream)
      const analyser = audioContext.createAnalyser()
      analyser.fftSize = 256
      source.connect(analyser)
      analyserRef.current = analyser

      // Set up media recorder
      const mediaRecorder = new MediaRecorder(stream, {
        mimeType: MediaRecorder.isTypeSupported('audio/webm')
          ? 'audio/webm'
          : 'audio/mp4',
      })
      mediaRecorderRef.current = mediaRecorder
      chunksRef.current = []

      mediaRecorder.ondataavailable = (event) => {
        if (event.data.size > 0) {
          chunksRef.current.push(event.data)
        }
      }

      mediaRecorder.onstop = () => {
        const audioBlob = new Blob(chunksRef.current, {
          type: mediaRecorder.mimeType,
        })
        onRecordingComplete(audioBlob)
      }

      mediaRecorder.start()
      setState('recording')
      setRecordingTime(0)
      onRecordingStart?.()

      // Start audio level visualization
      startAudioLevelLoop()

      // Start recording timer
      timerRef.current = window.setInterval(() => {
        setRecordingTime(prev => prev + 100)
      }, 100)

      // Set max duration timeout - use ref to avoid dependency cycle
      maxDurationTimerRef.current = window.setTimeout(() => {
        stopRecordingRef.current()
      }, maxDuration)
    } catch (err) {
      setState('idle')
      if (err instanceof Error) {
        if (err.name === 'NotAllowedError') {
          setError('Microphone access was denied. Please allow microphone access to record.')
        } else if (err.name === 'NotFoundError') {
          setError('No microphone found. Please connect a microphone.')
        } else {
          setError('Could not access microphone. Please try again.')
        }
      } else {
        setError('Could not access microphone. Please try again.')
      }
    }
  }, [maxDuration, onRecordingComplete, onRecordingStart, startAudioLevelLoop])

  const handleClick = useCallback(() => {
    if (state === 'recording') {
      stopRecording()
    } else if (state === 'idle') {
      startRecording()
    }
  }, [state, startRecording, stopRecording])

  const formatTime = (ms: number): string => {
    const seconds = Math.floor(ms / 1000)
    const tenths = Math.floor((ms % 1000) / 100)
    return `${seconds}.${tenths}s`
  }

  // Generate bars for audio visualization
  const bars = Array.from({ length: 5 }, (_, i) => {
    const threshold = (i + 1) / 5
    const isActive = audioLevel >= threshold * 0.8
    return (
      <div
        key={i}
        className={`mic-input-bar ${isActive ? 'mic-input-bar-active' : ''}`}
        style={{
          height: `${20 + i * 15}%`,
          animationDelay: `${i * 0.1}s`,
        }}
      />
    )
  })

  return (
    <div className={`mic-input ${disabled ? 'mic-input-disabled' : ''}`}>
      {error && (
        <div className="mic-input-error" role="alert">
          <span className="mic-input-error-icon" aria-hidden="true">
            &#128542;
          </span>
          <span>{error}</span>
          <button
            type="button"
            className="mic-input-error-dismiss"
            onClick={() => setError(null)}
            aria-label="Dismiss error"
          >
            &#10005;
          </button>
        </div>
      )}

      <button
        type="button"
        className={`mic-input-button ${state === 'recording' ? 'mic-input-button-recording' : ''} ${state === 'requesting' ? 'mic-input-button-requesting' : ''}`}
        onClick={handleClick}
        disabled={disabled || state === 'requesting' || state === 'stopped'}
        aria-label={state === 'recording' ? 'Stop recording' : 'Start recording'}
      >
        {state === 'requesting' ? (
          <span className="mic-input-spinner" aria-hidden="true">
            &#127908;
          </span>
        ) : state === 'recording' ? (
          <span className="mic-input-stop" aria-hidden="true">
            &#9632;
          </span>
        ) : (
          <span className="mic-input-mic" aria-hidden="true">
            &#127908;
          </span>
        )}
      </button>

      {state === 'recording' && (
        <div className="mic-input-visualizer" aria-hidden="true">
          {bars}
        </div>
      )}

      <div className="mic-input-status">
        {state === 'idle' && (
          <span className="mic-input-hint">Tap to record</span>
        )}
        {state === 'requesting' && (
          <span className="mic-input-hint">Requesting microphone...</span>
        )}
        {state === 'recording' && (
          <span className="mic-input-time">{formatTime(recordingTime)}</span>
        )}
        {state === 'stopped' && (
          <span className="mic-input-hint">Recording complete!</span>
        )}
      </div>
    </div>
  )
}
