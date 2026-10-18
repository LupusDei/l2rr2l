import Foundation
@testable import L2RR2L

/// A mock voice service for testing TTS functionality without actual audio playback
/// Note: This mock is designed to be used when the full app types are available.
@MainActor
final class MockVoiceService: ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var isSpeaking = false
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?

    // MARK: - Test Configuration

    /// Error to throw on speak
    var speakError: Error?

    /// Track all spoken text
    private(set) var spokenTexts: [String] = []

    /// Simulated speech duration in seconds
    var speechDuration: TimeInterval = 0.1

    /// Whether to simulate successful speech
    var shouldSucceed = true

    // MARK: - Initialization

    init() {}

    // MARK: - Public Methods

    func speak(_ text: String) async {
        spokenTexts.append(text)

        if let error = speakError {
            self.error = error
            return
        }

        guard shouldSucceed else {
            error = MockVoiceError.playbackFailed
            return
        }

        isLoading = true
        try? await Task.sleep(nanoseconds: UInt64(speechDuration * 500_000_000))

        isLoading = false
        isSpeaking = true

        try? await Task.sleep(nanoseconds: UInt64(speechDuration * 500_000_000))

        isSpeaking = false
    }

    func stop() {
        isSpeaking = false
        isLoading = false
    }

    // MARK: - Test Helpers

    func clearHistory() {
        spokenTexts.removeAll()
    }

    func reset() {
        spokenTexts.removeAll()
        speakError = nil
        shouldSucceed = true
        isSpeaking = false
        isLoading = false
        error = nil
    }
}

// MARK: - Mock Voice Error

enum MockVoiceError: Error, LocalizedError {
    case playbackFailed
    case synthesisError(String)

    var errorDescription: String? {
        switch self {
        case .playbackFailed:
            return "Audio playback failed"
        case .synthesisError(let message):
            return "Speech synthesis failed: \(message)"
        }
    }
}
