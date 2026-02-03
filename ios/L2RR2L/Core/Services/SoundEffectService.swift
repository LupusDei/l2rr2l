import AVFoundation
import Foundation

// MARK: - Sound Effect Service

@MainActor
final class SoundEffectService: ObservableObject {
    static let shared = SoundEffectService()

    // MARK: - Sound Effects

    enum SoundEffect: String, CaseIterable {
        case correct
        case incorrect
        case flip
        case match
        case levelComplete
        case buttonTap
        case streak
        case confetti

        var filename: String {
            switch self {
            case .correct: return "correct"
            case .incorrect: return "incorrect"
            case .flip: return "flip"
            case .match: return "match"
            case .levelComplete: return "level_complete"
            case .buttonTap: return "button_tap"
            case .streak: return "streak"
            case .confetti: return "confetti"
            }
        }
    }

    // MARK: - Published Properties

    @Published private(set) var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: Self.enabledKey)
        }
    }

    // MARK: - Private Properties

    private var players: [SoundEffect: AVAudioPlayer] = [:]
    private static let enabledKey = "soundEffectsEnabled"

    // MARK: - Initialization

    private init() {
        self.isEnabled = UserDefaults.standard.object(forKey: Self.enabledKey) as? Bool ?? true
        configureAudioSession()
    }

    // For testing
    init(isEnabled: Bool) {
        self.isEnabled = isEnabled
        configureAudioSession()
    }

    // MARK: - Public Methods

    /// Preload all sound effects into memory for low-latency playback
    func preload() {
        for effect in SoundEffect.allCases {
            loadSound(effect)
        }
    }

    /// Play a sound effect
    /// - Parameter effect: The sound effect to play
    func play(_ effect: SoundEffect) {
        guard isEnabled else { return }
        guard !isDeviceSilent() else { return }

        if players[effect] == nil {
            loadSound(effect)
        }

        guard let player = players[effect] else { return }

        if player.isPlaying {
            player.currentTime = 0
        }
        player.play()
    }

    /// Enable or disable sound effects
    /// - Parameter enabled: Whether sound effects should be enabled
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }

    // MARK: - Private Methods

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(
                .ambient,
                mode: .default,
                options: [.mixWithOthers]
            )
        } catch {
            #if DEBUG
            print("[SoundEffectService] Failed to configure audio session: \(error)")
            #endif
        }
    }

    private func loadSound(_ effect: SoundEffect) {
        guard let url = Bundle.main.url(
            forResource: effect.filename,
            withExtension: "wav",
            subdirectory: "Sounds"
        ) ?? Bundle.main.url(
            forResource: effect.filename,
            withExtension: "mp3",
            subdirectory: "Sounds"
        ) else {
            #if DEBUG
            print("[SoundEffectService] Sound file not found: \(effect.filename)")
            #endif
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.volume = 1.0
            players[effect] = player
        } catch {
            #if DEBUG
            print("[SoundEffectService] Failed to load sound \(effect.filename): \(error)")
            #endif
        }
    }

    private func isDeviceSilent() -> Bool {
        // Check if device is in silent mode by checking the audio session category
        // When using .ambient category, audio respects the silent switch automatically
        // So we don't need additional checks - AVAudioPlayer handles this
        return false
    }
}
