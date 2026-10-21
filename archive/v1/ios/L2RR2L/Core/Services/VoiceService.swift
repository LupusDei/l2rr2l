import AVFoundation
import Foundation

// MARK: - Voice Service

@MainActor
final class VoiceService: NSObject, ObservableObject {
    static let shared = VoiceService()

    // MARK: - Published Properties

    @Published private(set) var isSpeaking = false
    @Published private(set) var isLoading = false
    @Published var settings: VoiceServiceSettings
    @Published private(set) var availableVoices: [Voice] = []
    @Published private(set) var error: Error?

    // MARK: - Private Properties

    private let apiClient: APIClient
    private var audioPlayer: AVAudioPlayer?
    private var speechQueue: [SpeechItem] = []
    private var currentTask: Task<Void, Never>?
    private var isProcessingQueue = false

    // MARK: - Initialization

    private override init() {
        self.apiClient = APIClient.shared
        self.settings = .default
        super.init()
        configureAudioSession()
    }

    // For testing
    init(apiClient: APIClient) {
        self.apiClient = apiClient
        self.settings = .default
        super.init()
        configureAudioSession()
    }

    // MARK: - Public Methods

    /// Speak the given text using TTS
    /// - Parameters:
    ///   - text: The text to speak
    ///   - priority: Priority level for the speech (normal or high)
    func speak(_ text: String, priority: SpeechPriority = .normal) async {
        let item = SpeechItem(text: text, priority: priority)

        if priority == .high {
            // High priority: cancel current and insert at front
            stop()
            speechQueue.insert(item, at: 0)
        } else {
            speechQueue.append(item)
        }

        await processQueue()
    }

    /// Stop current playback and clear the queue
    func stop() {
        currentTask?.cancel()
        currentTask = nil
        audioPlayer?.stop()
        audioPlayer = nil
        speechQueue.removeAll()
        isSpeaking = false
        isLoading = false
        isProcessingQueue = false
    }

    /// Stop current playback but keep remaining queue items
    func skipCurrent() {
        audioPlayer?.stop()
        audioPlayer = nil
        isSpeaking = false
    }

    /// Fetch available voices from the API
    func getAvailableVoices() async throws -> [Voice] {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let endpoint = VoiceEndpoints.listVoices
            let response: VoicesResponse = try await apiClient.request(endpoint)
            availableVoices = response.voices
            return response.voices
        } catch {
            self.error = error
            throw error
        }
    }

    /// Get details for a specific voice
    func getVoice(id: String) async throws -> Voice {
        let endpoint = VoiceEndpoints.getVoice(id: id)
        return try await apiClient.request(endpoint)
    }

    /// Update voice settings for a child
    func updateSettings(childId: String, settings: VoiceSettingsUpdate) async throws {
        let endpoint = VoiceEndpoints.updateSettings(childId: childId, settings: settings)
        try await apiClient.requestVoid(endpoint)
    }

    /// Get voice settings for a child
    func getSettings(childId: String) async throws -> VoiceSettingsResponse {
        let endpoint = VoiceEndpoints.getSettings(childId: childId)
        return try await apiClient.request(endpoint)
    }

    // MARK: - Private Methods

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(
                .playback,
                mode: .spokenAudio,
                options: [.duckOthers, .allowBluetooth]
            )
            try session.setActive(true)
        } catch {
            #if DEBUG
            print("[VoiceService] Failed to configure audio session: \(error)")
            #endif
        }
    }

    private func processQueue() async {
        guard !isProcessingQueue else { return }
        isProcessingQueue = true

        while !speechQueue.isEmpty {
            let item = speechQueue.removeFirst()

            do {
                try await synthesizeAndPlay(text: item.text)
            } catch {
                if !(error is CancellationError) {
                    self.error = error
                    #if DEBUG
                    print("[VoiceService] TTS error: \(error)")
                    #endif
                }
            }
        }

        isProcessingQueue = false
    }

    private func synthesizeAndPlay(text: String) async throws {
        isLoading = true
        error = nil

        // Build TTS request with current settings
        // Note: Uses VoiceSettings from Endpoints.swift for API requests
        let voiceSettings = VoiceSettings(
            stability: settings.stability,
            similarityBoost: settings.similarityBoost,
            style: settings.style,
            speed: settings.speed,
            useSpeakerBoost: settings.useSpeakerBoost
        )

        let endpoint = VoiceEndpoints.textToSpeech(
            text: text,
            voiceId: settings.voiceId,
            modelId: nil,
            voiceSettings: voiceSettings
        )

        // Fetch audio data
        let audioData = try await apiClient.requestData(endpoint)

        try Task.checkCancellation()

        isLoading = false

        // Play audio
        try await playAudio(data: audioData)
    }

    private func playAudio(data: Data) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                audioPlayer = try AVAudioPlayer(data: data)
                audioPlayer?.delegate = self
                audioPlayer?.prepareToPlay()

                // Store continuation for delegate callback
                playbackContinuation = continuation
                isSpeaking = true

                if audioPlayer?.play() != true {
                    playbackContinuation = nil
                    isSpeaking = false
                    continuation.resume(throwing: VoiceError.playbackFailed)
                }
            } catch {
                continuation.resume(throwing: VoiceError.audioInitFailed(error))
            }
        }
    }

    private var playbackContinuation: CheckedContinuation<Void, Error>?
}

// MARK: - AVAudioPlayerDelegate

extension VoiceService: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            isSpeaking = false
            let continuation = playbackContinuation
            playbackContinuation = nil

            if flag {
                continuation?.resume()
            } else {
                continuation?.resume(throwing: VoiceError.playbackFailed)
            }
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            isSpeaking = false
            let continuation = playbackContinuation
            playbackContinuation = nil
            continuation?.resume(throwing: VoiceError.decodingFailed(error))
        }
    }
}

// MARK: - Supporting Types

struct VoiceServiceSettings: Equatable {
    var voiceId: String
    var stability: Double
    var similarityBoost: Double
    var style: Double
    var speed: Double
    var useSpeakerBoost: Bool

    static let `default` = VoiceServiceSettings(
        voiceId: "pMsXgVXv3BLzUgSXRplE",
        stability: 0.5,
        similarityBoost: 0.75,
        style: 0,
        speed: 1.0,
        useSpeakerBoost: true
    )
}

enum SpeechPriority {
    case normal
    case high
}

private struct SpeechItem {
    let text: String
    let priority: SpeechPriority
}

enum VoiceError: Error, LocalizedError {
    case playbackFailed
    case audioInitFailed(Error)
    case decodingFailed(Error?)
    case synthesisError(String)

    var errorDescription: String? {
        switch self {
        case .playbackFailed:
            return "Audio playback failed"
        case .audioInitFailed(let error):
            return "Failed to initialize audio player: \(error.localizedDescription)"
        case .decodingFailed(let error):
            return "Audio decoding failed: \(error?.localizedDescription ?? "unknown error")"
        case .synthesisError(let message):
            return "Speech synthesis failed: \(message)"
        }
    }
}

// MARK: - Voice Settings Response

struct VoiceSettingsResponse: Codable {
    let voiceId: String
    let speed: Double
    let stability: Double
    let similarityBoost: Double

    enum CodingKeys: String, CodingKey {
        case voiceId = "voice_id"
        case speed, stability
        case similarityBoost = "similarity_boost"
    }
}
