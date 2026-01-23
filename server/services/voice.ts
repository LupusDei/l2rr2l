import { ElevenLabsClient } from '@elevenlabs/elevenlabs-js'

// Child-friendly default voice (Rachel - clear, warm, and age-appropriate)
export const DEFAULT_VOICE_ID = 'EXAVITQu4vr4xnSDxMaL'

// Voice settings validation ranges
export const VOICE_SETTINGS_RANGES = {
  stability: { min: 0, max: 1 },
  similarityBoost: { min: 0, max: 1 },
  style: { min: 0, max: 1 },
  speed: { min: 0.5, max: 2.0 },
} as const

// Default voice settings for child-friendly TTS
export const VOICE_SETTINGS_DEFAULTS = {
  stability: 0.5,
  similarityBoost: 0.75,
  style: 0,
  speed: 1.0,
  useSpeakerBoost: true,
} as const

export interface VoiceSettings {
  stability?: number
  similarityBoost?: number
  style?: number
  speed?: number
  useSpeakerBoost?: boolean
}

export interface VoiceSettingsValidationError {
  field: string
  value: number
  min: number
  max: number
  message: string
}

/**
 * Validate voice settings values are within acceptable ranges
 * Returns an array of validation errors, empty if all valid
 */
export function validateVoiceSettings(settings: VoiceSettings): VoiceSettingsValidationError[] {
  const errors: VoiceSettingsValidationError[] = []

  const validateRange = (
    field: keyof typeof VOICE_SETTINGS_RANGES,
    value: number | undefined
  ) => {
    if (value === undefined) return
    const range = VOICE_SETTINGS_RANGES[field]
    if (value < range.min || value > range.max) {
      errors.push({
        field,
        value,
        min: range.min,
        max: range.max,
        message: `${field} must be between ${range.min} and ${range.max}, got ${value}`,
      })
    }
  }

  validateRange('stability', settings.stability)
  validateRange('similarityBoost', settings.similarityBoost)
  validateRange('style', settings.style)
  validateRange('speed', settings.speed)

  return errors
}

/**
 * Apply default values to voice settings
 */
export function applyVoiceSettingsDefaults(settings?: VoiceSettings): Required<VoiceSettings> {
  return {
    stability: settings?.stability ?? VOICE_SETTINGS_DEFAULTS.stability,
    similarityBoost: settings?.similarityBoost ?? VOICE_SETTINGS_DEFAULTS.similarityBoost,
    style: settings?.style ?? VOICE_SETTINGS_DEFAULTS.style,
    speed: settings?.speed ?? VOICE_SETTINGS_DEFAULTS.speed,
    useSpeakerBoost: settings?.useSpeakerBoost ?? VOICE_SETTINGS_DEFAULTS.useSpeakerBoost,
  }
}

export interface TextToSpeechOptions {
  voiceId: string
  text: string
  modelId?: string
  voiceSettings?: VoiceSettings
  outputFormat?: string
}

export interface VoiceCloneOptions {
  name: string
  files: File[] | Buffer[]
  description?: string
  labels?: Record<string, string>
}

export interface Voice {
  voiceId: string
  name: string
  category?: string
  description?: string
  previewUrl?: string
  labels?: Record<string, string>
}

export class VoiceServiceUnavailableError extends Error {
  constructor(message = 'Voice service is unavailable. ELEVENLABS_API_KEY is not configured.') {
    super(message)
    this.name = 'VoiceServiceUnavailableError'
  }
}

export class VoiceSettingsValidationFailedError extends Error {
  constructor(public errors: VoiceSettingsValidationError[]) {
    super(`Invalid voice settings: ${errors.map((e) => e.message).join('; ')}`)
    this.name = 'VoiceSettingsValidationFailedError'
  }
}

export class VoiceService {
  private client: ElevenLabsClient | null = null
  private readonly isConfigured: boolean

  constructor(apiKey?: string) {
    const key = apiKey || process.env.ELEVENLABS_API_KEY
    if (key) {
      this.client = new ElevenLabsClient({ apiKey: key })
      this.isConfigured = true
    } else {
      console.warn(
        'VoiceService: ELEVENLABS_API_KEY not configured. Voice features will be unavailable.'
      )
      this.isConfigured = false
    }
  }

  /**
   * Check if the voice service is available
   */
  isAvailable(): boolean {
    return this.isConfigured
  }

  /**
   * Ensure the service is available, throw if not
   */
  private ensureAvailable(): asserts this is { client: ElevenLabsClient } {
    if (!this.isConfigured || !this.client) {
      throw new VoiceServiceUnavailableError()
    }
  }

  /**
   * Validate and apply defaults to voice settings
   */
  private prepareVoiceSettings(settings?: VoiceSettings): Required<VoiceSettings> {
    if (settings) {
      const errors = validateVoiceSettings(settings)
      if (errors.length > 0) {
        throw new VoiceSettingsValidationFailedError(errors)
      }
    }
    return applyVoiceSettingsDefaults(settings)
  }

  /**
   * Convert text to speech audio
   */
  async textToSpeech(options: TextToSpeechOptions): Promise<Buffer> {
    this.ensureAvailable()
    const { voiceId, text, modelId, voiceSettings, outputFormat } = options
    const settings = this.prepareVoiceSettings(voiceSettings)

    const response = await this.client.textToSpeech.convert(voiceId || DEFAULT_VOICE_ID, {
      text,
      modelId: modelId || 'eleven_multilingual_v2',
      outputFormat: outputFormat || 'mp3_44100_128',
      voiceSettings: {
        stability: settings.stability,
        similarityBoost: settings.similarityBoost,
        style: settings.style,
        useSpeakerBoost: settings.useSpeakerBoost,
      },
    })

    return await streamToBuffer(response)
  }

  /**
   * Convert text to speech with streaming
   */
  async textToSpeechStream(options: TextToSpeechOptions): Promise<ReadableStream<Uint8Array>> {
    this.ensureAvailable()
    const { voiceId, text, modelId, voiceSettings, outputFormat } = options
    const settings = this.prepareVoiceSettings(voiceSettings)

    return await this.client.textToSpeech.stream(voiceId || DEFAULT_VOICE_ID, {
      text,
      modelId: modelId || 'eleven_multilingual_v2',
      outputFormat: outputFormat || 'mp3_44100_128',
      voiceSettings: {
        stability: settings.stability,
        similarityBoost: settings.similarityBoost,
        style: settings.style,
        useSpeakerBoost: settings.useSpeakerBoost,
      },
    })
  }

  /**
   * Clone a voice from audio samples
   */
  async cloneVoice(options: VoiceCloneOptions): Promise<{ voiceId: string }> {
    this.ensureAvailable()
    const { name, files, description, labels } = options

    const result = await this.client.voices.ivc.create({
      name,
      files: files as File[],
      description,
      labels: labels ? JSON.stringify(labels) : undefined,
    })

    return { voiceId: result.voiceId }
  }

  /**
   * List all available voices
   */
  async listVoices(): Promise<Voice[]> {
    this.ensureAvailable()
    const response = await this.client.voices.getAll()

    return response.voices.map((voice) => ({
      voiceId: voice.voiceId,
      name: voice.name ?? 'Unknown',
      category: voice.category,
      description: voice.description ?? undefined,
      previewUrl: voice.previewUrl ?? undefined,
      labels: voice.labels as Record<string, string> | undefined,
    }))
  }

  /**
   * Get a specific voice by ID
   */
  async getVoice(voiceId: string): Promise<Voice | null> {
    this.ensureAvailable()
    try {
      const voice = await this.client.voices.get(voiceId)

      return {
        voiceId: voice.voiceId,
        name: voice.name ?? 'Unknown',
        category: voice.category,
        description: voice.description ?? undefined,
        previewUrl: voice.previewUrl ?? undefined,
        labels: voice.labels as Record<string, string> | undefined,
      }
    } catch {
      return null
    }
  }

  /**
   * Delete a cloned voice
   */
  async deleteVoice(voiceId: string): Promise<boolean> {
    this.ensureAvailable()
    try {
      await this.client.voices.delete(voiceId)
      return true
    } catch {
      return false
    }
  }
}

/**
 * Convert a ReadableStream to a Buffer
 */
async function streamToBuffer(stream: ReadableStream<Uint8Array>): Promise<Buffer> {
  const reader = stream.getReader()
  const chunks: Uint8Array[] = []

  while (true) {
    const { done, value } = await reader.read()
    if (done) break
    if (value) chunks.push(value)
  }

  return Buffer.concat(chunks)
}

// Singleton instance
let voiceServiceInstance: VoiceService | null = null

export function getVoiceService(): VoiceService {
  if (!voiceServiceInstance) {
    voiceServiceInstance = new VoiceService()
  }
  return voiceServiceInstance
}
