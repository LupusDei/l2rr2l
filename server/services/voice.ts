import { ElevenLabsClient } from '@elevenlabs/elevenlabs-js'

export interface VoiceSettings {
  stability?: number
  similarityBoost?: number
  style?: number
  useSpeakerBoost?: boolean
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

export class VoiceService {
  private client: ElevenLabsClient

  constructor(apiKey?: string) {
    this.client = new ElevenLabsClient({
      apiKey: apiKey || process.env.ELEVENLABS_API_KEY,
    })
  }

  /**
   * Convert text to speech audio
   */
  async textToSpeech(options: TextToSpeechOptions): Promise<Buffer> {
    const { voiceId, text, modelId, voiceSettings, outputFormat } = options

    const response = await this.client.textToSpeech.convert(voiceId, {
      text,
      modelId: modelId || 'eleven_multilingual_v2',
      outputFormat: outputFormat || 'mp3_44100_128',
      voiceSettings: voiceSettings
        ? {
            stability: voiceSettings.stability ?? 0.5,
            similarityBoost: voiceSettings.similarityBoost ?? 0.75,
            style: voiceSettings.style ?? 0,
            useSpeakerBoost: voiceSettings.useSpeakerBoost ?? true,
          }
        : undefined,
    })

    return await streamToBuffer(response)
  }

  /**
   * Convert text to speech with streaming
   */
  async textToSpeechStream(options: TextToSpeechOptions): Promise<ReadableStream<Uint8Array>> {
    const { voiceId, text, modelId, voiceSettings, outputFormat } = options

    return await this.client.textToSpeech.stream(voiceId, {
      text,
      modelId: modelId || 'eleven_multilingual_v2',
      outputFormat: outputFormat || 'mp3_44100_128',
      voiceSettings: voiceSettings
        ? {
            stability: voiceSettings.stability ?? 0.5,
            similarityBoost: voiceSettings.similarityBoost ?? 0.75,
            style: voiceSettings.style ?? 0,
            useSpeakerBoost: voiceSettings.useSpeakerBoost ?? true,
          }
        : undefined,
    })
  }

  /**
   * Clone a voice from audio samples
   */
  async cloneVoice(options: VoiceCloneOptions): Promise<{ voiceId: string }> {
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
