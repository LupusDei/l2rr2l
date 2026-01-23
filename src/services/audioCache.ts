/**
 * Audio cache service using IndexedDB for storing TTS audio blobs.
 * Reduces API calls by caching common phrases.
 */

const DB_NAME = 'spellcraft-audio-cache'
const DB_VERSION = 1
const STORE_NAME = 'audio'

interface CachedAudio {
  key: string // voiceId:stability:similarityBoost:text
  blob: Blob
  voiceId: string
  stability: number
  similarityBoost: number
  text: string
  createdAt: number
}

let dbPromise: Promise<IDBDatabase> | null = null

function openDatabase(): Promise<IDBDatabase> {
  if (dbPromise) return dbPromise

  dbPromise = new Promise((resolve, reject) => {
    const request = indexedDB.open(DB_NAME, DB_VERSION)

    request.onerror = () => {
      console.warn('IndexedDB failed to open:', request.error)
      reject(request.error)
    }

    request.onsuccess = () => {
      resolve(request.result)
    }

    request.onupgradeneeded = (event) => {
      const db = (event.target as IDBOpenDBRequest).result
      if (!db.objectStoreNames.contains(STORE_NAME)) {
        const store = db.createObjectStore(STORE_NAME, { keyPath: 'key' })
        store.createIndex('voiceId', 'voiceId', { unique: false })
        store.createIndex('createdAt', 'createdAt', { unique: false })
      }
    }
  })

  return dbPromise
}

function generateCacheKey(voiceId: string, stability: number, similarityBoost: number, text: string): string {
  return `${voiceId}:${stability}:${similarityBoost}:${text}`
}

export async function getCachedAudio(
  voiceId: string,
  stability: number,
  similarityBoost: number,
  text: string
): Promise<Blob | null> {
  try {
    const db = await openDatabase()
    const key = generateCacheKey(voiceId, stability, similarityBoost, text)

    return new Promise((resolve) => {
      const transaction = db.transaction(STORE_NAME, 'readonly')
      const store = transaction.objectStore(STORE_NAME)
      const request = store.get(key)

      request.onsuccess = () => {
        const result = request.result as CachedAudio | undefined
        resolve(result?.blob ?? null)
      }

      request.onerror = () => {
        console.warn('Failed to get cached audio:', request.error)
        resolve(null)
      }
    })
  } catch {
    return null
  }
}

export async function setCachedAudio(
  voiceId: string,
  stability: number,
  similarityBoost: number,
  text: string,
  blob: Blob
): Promise<void> {
  try {
    const db = await openDatabase()
    const key = generateCacheKey(voiceId, stability, similarityBoost, text)

    const entry: CachedAudio = {
      key,
      blob,
      voiceId,
      stability,
      similarityBoost,
      text,
      createdAt: Date.now(),
    }

    return new Promise((resolve) => {
      const transaction = db.transaction(STORE_NAME, 'readwrite')
      const store = transaction.objectStore(STORE_NAME)
      const request = store.put(entry)

      request.onsuccess = () => resolve()
      request.onerror = () => {
        console.warn('Failed to cache audio:', request.error)
        resolve()
      }
    })
  } catch {
    // Silently fail - caching is optional
  }
}

export async function invalidateCacheForVoice(voiceId: string): Promise<void> {
  try {
    const db = await openDatabase()

    return new Promise((resolve) => {
      const transaction = db.transaction(STORE_NAME, 'readwrite')
      const store = transaction.objectStore(STORE_NAME)
      const index = store.index('voiceId')
      const request = index.openCursor(IDBKeyRange.only(voiceId))

      request.onsuccess = () => {
        const cursor = request.result
        if (cursor) {
          cursor.delete()
          cursor.continue()
        } else {
          resolve()
        }
      }

      request.onerror = () => {
        console.warn('Failed to invalidate cache:', request.error)
        resolve()
      }
    })
  } catch {
    // Silently fail
  }
}

export async function clearAllCache(): Promise<void> {
  try {
    const db = await openDatabase()

    return new Promise((resolve) => {
      const transaction = db.transaction(STORE_NAME, 'readwrite')
      const store = transaction.objectStore(STORE_NAME)
      const request = store.clear()

      request.onsuccess = () => resolve()
      request.onerror = () => {
        console.warn('Failed to clear cache:', request.error)
        resolve()
      }
    })
  } catch {
    // Silently fail
  }
}

// Common phrases to pre-cache
export const COMMON_PHRASES = [
  // Celebration messages
  'Great Job!',
  'Amazing!',
  'Awesome!',
  'Super!',
  'Fantastic!',
  'Wonderful!',
  // Streak messages
  'On Fire!',
  'Unstoppable!',
  'Legendary!',
  'Champion!',
]

export interface PreCacheOptions {
  voiceId: string
  stability: number
  similarityBoost: number
  onProgress?: (completed: number, total: number) => void
}

export async function preCacheCommonPhrases(options: PreCacheOptions): Promise<void> {
  const { voiceId, stability, similarityBoost, onProgress } = options
  const total = COMMON_PHRASES.length
  let completed = 0

  for (const text of COMMON_PHRASES) {
    // Check if already cached
    const cached = await getCachedAudio(voiceId, stability, similarityBoost, text)
    if (cached) {
      completed++
      onProgress?.(completed, total)
      continue
    }

    // Fetch and cache
    try {
      const response = await fetch('/api/voice/tts', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          voiceId,
          text,
          voiceSettings: { stability, similarityBoost },
        }),
      })

      if (response.ok) {
        const blob = await response.blob()
        await setCachedAudio(voiceId, stability, similarityBoost, text, blob)
      }
    } catch {
      // Skip failed phrases - they'll be fetched live when needed
    }

    completed++
    onProgress?.(completed, total)
  }
}
