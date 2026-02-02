import Foundation

// MARK: - Voice Settings

struct VoiceSettings: Codable, Equatable {
    let voiceId: String
    let stability: Double
    let similarityBoost: Double
    let style: Double
    let speed: Double
    let useSpeakerBoost: Bool

    static let `default` = VoiceSettings(
        voiceId: "pMsXgVXv3BLzUgSXRplE",
        stability: 0.5,
        similarityBoost: 0.75,
        style: 0,
        speed: 1.0,
        useSpeakerBoost: true
    )
}

// MARK: - Voice Info

struct Voice: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let category: String?
    let description: String?
    let previewUrl: String?

    enum CodingKeys: String, CodingKey {
        case id = "voice_id"
        case name, category, description
        case previewUrl = "preview_url"
    }
}

struct VoicesResponse: Codable, Equatable {
    let voices: [Voice]
}
