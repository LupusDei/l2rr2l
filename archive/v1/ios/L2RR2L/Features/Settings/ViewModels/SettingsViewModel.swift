import Foundation
import Combine

/// ViewModel for the main settings screen
@MainActor
class SettingsViewModel: ObservableObject {
    // MARK: - Published Properties

    /// Current selected voice
    @Published private(set) var selectedVoice: Voice?

    /// Sound effects enabled state
    @Published var soundEffectsEnabled: Bool {
        didSet {
            SoundEffectService.shared.setEnabled(soundEffectsEnabled)
            if soundEffectsEnabled {
                SoundEffectService.shared.play(.buttonTap)
            }
        }
    }

    /// Haptics enabled state
    @Published var hapticsEnabled: Bool {
        didSet {
            HapticService.shared.isEnabled = hapticsEnabled
            if hapticsEnabled {
                HapticService.shared.selectionFeedback()
            }
        }
    }

    /// Available voices
    @Published private(set) var voices: [Voice] = []

    /// Loading state for voices
    @Published private(set) var isLoadingVoices = false

    /// Error message
    @Published var errorMessage: String?

    // MARK: - Services

    private let voiceService: VoiceService
    private let authService: AuthService
    private let childProfileService: ChildProfileService

    // MARK: - Computed Properties

    /// Current authenticated user
    var currentUser: User? {
        authService.currentUser
    }

    /// Active child profile
    var activeChild: Child? {
        childProfileService.activeChild
    }

    /// All child profiles
    var children: [Child] {
        childProfileService.children
    }

    // MARK: - Initialization

    init(
        voiceService: VoiceService = .shared,
        authService: AuthService = .shared,
        childProfileService: ChildProfileService = .shared
    ) {
        self.voiceService = voiceService
        self.authService = authService
        self.childProfileService = childProfileService
        self.soundEffectsEnabled = SoundEffectService.shared.isEnabled
        self.hapticsEnabled = HapticService.shared.isEnabled
    }

    // MARK: - Public Methods

    /// Load initial data
    func loadData() async {
        await loadVoices()
        await loadChildren()
    }

    /// Load available voices
    func loadVoices() async {
        isLoadingVoices = true
        errorMessage = nil

        do {
            voices = try await voiceService.getAvailableVoices()
            // Set selected voice based on current service settings
            selectedVoice = voices.first { $0.id == voiceService.settings.voiceId }
        } catch {
            // Use default voices if API fails
            voices = Self.defaultVoices
            selectedVoice = voices.first { $0.id == voiceService.settings.voiceId }
        }

        isLoadingVoices = false
    }

    /// Load child profiles
    func loadChildren() async {
        do {
            try await childProfileService.fetchChildren()
        } catch {
            // Silently fail - children may already be loaded
        }
    }

    /// Update the selected voice
    func selectVoice(_ voice: Voice) {
        selectedVoice = voice
        var newSettings = voiceService.settings
        newSettings.voiceId = voice.id
        voiceService.settings = newSettings
    }

    /// Logout the current user
    func logout() {
        Task {
            await authService.logout()
        }
    }

    // MARK: - Private Helpers

    private static let defaultVoices: [Voice] = {
        let voiceData: [(voiceId: String, name: String, category: String, description: String)] = [
            ("pMsXgVXv3BLzUgSXRplE", "Rachel", "premade", "Calm and friendly female voice"),
            ("21m00Tcm4TlvDq8ikWAM", "Adam", "premade", "Deep and clear male voice"),
            ("AZnzlk1XvdvUeBnXmlld", "Domi", "premade", "Energetic female voice"),
            ("EXAVITQu4vr4xnSDxMaL", "Bella", "premade", "Soft and gentle female voice")
        ]

        return voiceData.compactMap { data -> Voice? in
            let json = """
            {
                "voiceId": "\(data.voiceId)",
                "name": "\(data.name)",
                "category": "\(data.category)",
                "description": "\(data.description)"
            }
            """
            guard let jsonData = json.data(using: .utf8) else { return nil }
            return try? JSONDecoder().decode(Voice.self, from: jsonData)
        }
    }()
}
