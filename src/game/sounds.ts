// Sound effects using Web Audio API
// Generates simple tones without requiring audio files

let audioContext: AudioContext | null = null

function getAudioContext(): AudioContext {
  if (!audioContext) {
    audioContext = new AudioContext()
  }
  return audioContext
}

// Play a pleasant "correct" chime - ascending tones
export function playCorrectSound(): void {
  try {
    const ctx = getAudioContext()
    const now = ctx.currentTime

    // Play two quick ascending notes for a cheerful "ding-ding!"
    const frequencies = [523.25, 659.25] // C5, E5

    frequencies.forEach((freq, i) => {
      const oscillator = ctx.createOscillator()
      const gainNode = ctx.createGain()

      oscillator.connect(gainNode)
      gainNode.connect(ctx.destination)

      oscillator.type = 'sine'
      oscillator.frequency.value = freq

      // Quick attack, medium decay
      const startTime = now + i * 0.1
      gainNode.gain.setValueAtTime(0, startTime)
      gainNode.gain.linearRampToValueAtTime(0.3, startTime + 0.02)
      gainNode.gain.exponentialRampToValueAtTime(0.01, startTime + 0.3)

      oscillator.start(startTime)
      oscillator.stop(startTime + 0.35)
    })
  } catch {
    // Silently fail if audio isn't available
  }
}

// Play a gentle "wrong" sound - descending tone
export function playWrongSound(): void {
  try {
    const ctx = getAudioContext()
    const now = ctx.currentTime

    // Two quick descending notes for a gentle "nope"
    const frequencies = [392, 330] // G4, E4

    frequencies.forEach((freq, i) => {
      const oscillator = ctx.createOscillator()
      const gainNode = ctx.createGain()

      oscillator.connect(gainNode)
      gainNode.connect(ctx.destination)

      oscillator.type = 'sine'
      oscillator.frequency.value = freq

      const startTime = now + i * 0.12
      gainNode.gain.setValueAtTime(0, startTime)
      gainNode.gain.linearRampToValueAtTime(0.15, startTime + 0.02)
      gainNode.gain.exponentialRampToValueAtTime(0.01, startTime + 0.2)

      oscillator.start(startTime)
      oscillator.stop(startTime + 0.25)
    })
  } catch {
    // Silently fail if audio isn't available
  }
}

// Play a celebratory sound for word completion
export function playWordCompleteSound(): void {
  try {
    const ctx = getAudioContext()
    const now = ctx.currentTime

    // Major arpeggio: C-E-G-C (cheerful!)
    const frequencies = [523.25, 659.25, 783.99, 1046.5]

    frequencies.forEach((freq, i) => {
      const oscillator = ctx.createOscillator()
      const gainNode = ctx.createGain()

      oscillator.connect(gainNode)
      gainNode.connect(ctx.destination)

      oscillator.type = 'sine'
      oscillator.frequency.value = freq

      const startTime = now + i * 0.1
      gainNode.gain.setValueAtTime(0, startTime)
      gainNode.gain.linearRampToValueAtTime(0.25, startTime + 0.02)
      gainNode.gain.exponentialRampToValueAtTime(0.01, startTime + 0.4)

      oscillator.start(startTime)
      oscillator.stop(startTime + 0.45)
    })
  } catch {
    // Silently fail if audio isn't available
  }
}
