import AVFoundation
import Speech

/// Service for speech recognition and pronunciation checking using iOS Speech framework.
/// Provides real-time transcription, audio level visualization, and pronunciation accuracy comparison.
@MainActor
final class SpeechRecognitionService: ObservableObject {
    // MARK: - Singleton

    static let shared = SpeechRecognitionService()

    // MARK: - Published Properties

    /// Whether the service is currently recording audio
    @Published private(set) var isRecording = false

    /// Current audio input level (0.0 to 1.0) for UI visualization
    @Published private(set) var audioLevel: Float = 0

    /// The current transcription result
    @Published private(set) var transcription = ""

    /// Whether speech recognition is authorized
    @Published private(set) var isAuthorized = false

    /// Current error state
    @Published private(set) var error: SpeechRecognitionError?

    // MARK: - Private Properties

    private let speechRecognizer: SFSpeechRecognizer?
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioLevelTimer: Timer?

    // MARK: - Initialization

    private init() {
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    }

    // MARK: - Authorization

    /// Requests authorization for speech recognition and microphone access.
    /// - Returns: Whether both permissions were granted
    func requestAuthorization() async -> Bool {
        // Request speech recognition authorization
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        guard speechStatus == .authorized else {
            error = .speechRecognitionNotAuthorized
            isAuthorized = false
            return false
        }

        // Request microphone authorization
        let micStatus: Bool
        if #available(iOS 17.0, *) {
            micStatus = await AVAudioApplication.requestRecordPermission()
        } else {
            micStatus = await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }

        guard micStatus else {
            error = .microphoneNotAuthorized
            isAuthorized = false
            return false
        }

        isAuthorized = true
        error = nil
        return true
    }

    /// Checks current authorization status without prompting
    func checkAuthorizationStatus() -> Bool {
        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        let micStatus = AVAudioSession.sharedInstance().recordPermission

        isAuthorized = speechStatus == .authorized && micStatus == .granted
        return isAuthorized
    }

    // MARK: - Recording

    /// Starts recording and transcribing speech.
    /// - Throws: `SpeechRecognitionError` if recording cannot be started
    func startRecording() async throws {
        guard isAuthorized else {
            let authorized = await requestAuthorization()
            guard authorized else {
                throw error ?? .speechRecognitionNotAuthorized
            }
        }

        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            error = .speechRecognizerUnavailable
            throw SpeechRecognitionError.speechRecognizerUnavailable
        }

        // Cancel any existing task
        stopRecording()

        // Reset state
        transcription = ""
        error = nil

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            error = .failedToCreateRequest
            throw SpeechRecognitionError.failedToCreateRequest
        }

        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = false

        // Configure audio input
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        // Start recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                guard let self = self else { return }

                if let result = result {
                    self.transcription = result.bestTranscription.formattedString
                }

                if let error = error {
                    self.error = .recognitionFailed(error.localizedDescription)
                    self.stopRecording()
                }
            }
        }

        // Install audio tap for recording and level metering
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)

            // Calculate audio level
            let level = self?.calculateAudioLevel(buffer: buffer) ?? 0
            Task { @MainActor in
                self?.audioLevel = level
            }
        }

        // Start audio engine
        audioEngine.prepare()
        try audioEngine.start()

        isRecording = true
    }

    /// Stops recording and returns the final transcription.
    /// - Returns: The final transcription text
    @discardableResult
    func stopRecording() -> String {
        audioLevelTimer?.invalidate()
        audioLevelTimer = nil

        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        recognitionRequest?.endAudio()
        recognitionRequest = nil

        recognitionTask?.cancel()
        recognitionTask = nil

        isRecording = false
        audioLevel = 0

        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        return transcription
    }

    // MARK: - Pronunciation Checking

    /// Compares spoken text against expected text and returns a similarity score.
    /// - Parameters:
    ///   - expected: The expected/target text
    ///   - actual: The actual spoken/transcribed text
    /// - Returns: A score from 0.0 (no match) to 1.0 (perfect match)
    func checkPronunciation(expected: String, actual: String) -> Double {
        let expectedNormalized = normalizeForComparison(expected)
        let actualNormalized = normalizeForComparison(actual)

        // Exact match
        if expectedNormalized == actualNormalized {
            return 1.0
        }

        // Calculate Levenshtein distance-based similarity
        let distance = levenshteinDistance(expectedNormalized, actualNormalized)
        let maxLength = max(expectedNormalized.count, actualNormalized.count)

        guard maxLength > 0 else { return 0.0 }

        let similarity = 1.0 - (Double(distance) / Double(maxLength))
        return max(0.0, similarity)
    }

    /// Checks if the spoken word matches the expected word (with tolerance).
    /// - Parameters:
    ///   - expected: The expected word
    ///   - actual: The actual spoken word
    ///   - threshold: Minimum similarity score to consider a match (default 0.7)
    /// - Returns: Whether the pronunciation matches
    func isPronunciationCorrect(expected: String, actual: String, threshold: Double = 0.7) -> Bool {
        checkPronunciation(expected: expected, actual: actual) >= threshold
    }

    // MARK: - Private Methods

    /// Calculates the audio level from an audio buffer.
    private func calculateAudioLevel(buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return 0 }

        let channelDataValue = channelData.pointee
        let channelDataValueArray = stride(
            from: 0,
            to: Int(buffer.frameLength),
            by: buffer.stride
        ).map { channelDataValue[$0] }

        // Calculate RMS (root mean square) for audio level
        let rms = sqrt(channelDataValueArray.map { $0 * $0 }.reduce(0, +) / Float(buffer.frameLength))

        // Convert to decibels and normalize to 0-1 range
        let avgPower = 20 * log10(rms)
        let minDb: Float = -80
        let normalized = max(0, (avgPower - minDb) / -minDb)

        return min(1.0, normalized)
    }

    /// Normalizes text for pronunciation comparison.
    private func normalizeForComparison(_ text: String) -> String {
        text.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .punctuationCharacters)
            .joined()
    }

    /// Calculates Levenshtein distance between two strings.
    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1Array = Array(s1)
        let s2Array = Array(s2)
        let m = s1Array.count
        let n = s2Array.count

        if m == 0 { return n }
        if n == 0 { return m }

        var matrix = [[Int]](repeating: [Int](repeating: 0, count: n + 1), count: m + 1)

        for i in 0...m { matrix[i][0] = i }
        for j in 0...n { matrix[0][j] = j }

        for i in 1...m {
            for j in 1...n {
                let cost = s1Array[i - 1] == s2Array[j - 1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i - 1][j] + 1,      // deletion
                    matrix[i][j - 1] + 1,      // insertion
                    matrix[i - 1][j - 1] + cost // substitution
                )
            }
        }

        return matrix[m][n]
    }
}

// MARK: - Error Types

/// Errors that can occur during speech recognition
enum SpeechRecognitionError: LocalizedError {
    case speechRecognitionNotAuthorized
    case microphoneNotAuthorized
    case speechRecognizerUnavailable
    case failedToCreateRequest
    case recognitionFailed(String)

    var errorDescription: String? {
        switch self {
        case .speechRecognitionNotAuthorized:
            return "Speech recognition permission not granted. Please enable in Settings."
        case .microphoneNotAuthorized:
            return "Microphone permission not granted. Please enable in Settings."
        case .speechRecognizerUnavailable:
            return "Speech recognition is not available on this device."
        case .failedToCreateRequest:
            return "Failed to create speech recognition request."
        case .recognitionFailed(let message):
            return "Recognition failed: \(message)"
        }
    }
}
