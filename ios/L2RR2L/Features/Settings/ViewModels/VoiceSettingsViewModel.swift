import Foundation
import Combine
import AVFoundation

/// ViewModel for voice settings configuration
@MainActor
class VoiceSettingsViewModel: ObservableObject {
    // MARK: - Published Properties

    /// Available voices from the API
    @Published private(set) var voices: [Voice] = []

    /// Currently selected voice ID
    @Published var selectedVoiceId: String = VoiceSettingsDefaults.voiceId

    /// Stability parameter (0.0-1.0)
    @Published var stability: Double = VoiceSettingsDefaults.stability

    /// Similarity boost parameter (0.0-1.0)
    @Published var similarityBoost: Double = VoiceSettingsDefaults.similarityBoost

    /// Style parameter (0.0-1.0)
    @Published var style: Double = VoiceSettingsDefaults.style

    /// Speed parameter (0.5-2.0)
    @Published var speed: Double = VoiceSettingsDefaults.speed

    /// Speaker boost toggle
    @Published var useSpeakerBoost: Bool = VoiceSettingsDefaults.useSpeakerBoost

    /// Loading state for voices
    @Published private(set) var isLoadingVoices = false

    /// Loading state for preview
    @Published private(set) var isPreviewPlaying = false

    /// Error message to display
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private var audioPlayer: AVAudioPlayer?
    private var cancellables = Set<AnyCancellable>()
    private var autoSaveTask: Task<Void, Never>?

    // MARK: - Computed Properties

    /// The currently selected voice
    var selectedVoice: Voice? {
        voices.first { $0.id == selectedVoiceId }
    }

    /// Current settings as a VoiceSettings object
    var currentSettings: VoiceSettings {
        VoiceSettings(
            voiceId: selectedVoiceId,
            stability: stability,
            similarityBoost: similarityBoost,
            style: style,
            speed: speed,
            useSpeakerBoost: useSpeakerBoost
        )
    }

    // MARK: - Initialization

    init() {
        setupAutoSave()
    }

    // MARK: - Public Methods

    /// Loads available voices from the API
    func loadVoices() async {
        isLoadingVoices = true
        errorMessage = nil

        // Simulated API response for now
        // In production, this would call the API
        await MainActor.run {
            voices = [
                Voice(id: "pMsXgVXv3BLzUgSXRplE", name: "Rachel", category: "premade", description: "Calm and friendly female voice", previewUrl: nil),
                Voice(id: "21m00Tcm4TlvDq8ikWAM", name: "Adam", category: "premade", description: "Deep and clear male voice", previewUrl: nil),
                Voice(id: "AZnzlk1XvdvUeBnXmlld", name: "Domi", category: "premade", description: "Energetic female voice", previewUrl: nil),
                Voice(id: "EXAVITQu4vr4xnSDxMaL", name: "Bella", category: "premade", description: "Soft and gentle female voice", previewUrl: nil),
                Voice(id: "ErXwobaYiN019PkySvjV", name: "Antoni", category: "premade", description: "Warm male voice with slight accent", previewUrl: nil),
                Voice(id: "MF3mGyEYCl7XYWbV9V6O", name: "Elli", category: "premade", description: "Young female voice", previewUrl: nil)
            ]
            isLoadingVoices = false
        }
    }

    /// Previews the current voice settings with sample text
    func previewVoice() async {
        guard !isPreviewPlaying else { return }

        isPreviewPlaying = true
        errorMessage = nil

        // In production, this would call the TTS API
        // For now, we'll simulate a brief preview
        try? await Task.sleep(nanoseconds: 1_500_000_000)

        isPreviewPlaying = false
    }

    /// Resets all settings to defaults
    func resetToDefaults() {
        selectedVoiceId = VoiceSettingsDefaults.voiceId
        stability = VoiceSettingsDefaults.stability
        similarityBoost = VoiceSettingsDefaults.similarityBoost
        style = VoiceSettingsDefaults.style
        speed = VoiceSettingsDefaults.speed
        useSpeakerBoost = VoiceSettingsDefaults.useSpeakerBoost
    }

    /// Saves the current settings
    func saveSettings() async {
        // In production, this would call the API to save settings
        // For now, we'll just log it
        print("Saving voice settings: \(currentSettings)")
    }

    // MARK: - Private Methods

    private func setupAutoSave() {
        // Debounce changes and auto-save after 1 second of no changes
        Publishers.MergeMany(
            $selectedVoiceId.map { _ in () },
            $stability.map { _ in () },
            $similarityBoost.map { _ in () },
            $style.map { _ in () },
            $speed.map { _ in () },
            $useSpeakerBoost.map { _ in () }
        )
        .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.autoSaveTask?.cancel()
            self?.autoSaveTask = Task { [weak self] in
                await self?.saveSettings()
            }
        }
        .store(in: &cancellables)
    }
}

// MARK: - Default Values

enum VoiceSettingsDefaults {
    static let voiceId = "pMsXgVXv3BLzUgSXRplE"
    static let stability: Double = 0.5
    static let similarityBoost: Double = 0.75
    static let style: Double = 0.0
    static let speed: Double = 1.0
    static let useSpeakerBoost = true
}
