import Foundation

// MARK: - Auth Endpoints

public enum AuthEndpoints {
    /// POST /api/auth/register
    public static func register(email: String, password: String, name: String) -> Endpoint {
        Endpoint(
            path: "auth/register",
            method: .post,
            body: RegisterRequest(email: email, password: password, name: name)
        )
    }

    /// POST /api/auth/login
    public static func login(email: String, password: String) -> Endpoint {
        Endpoint(
            path: "auth/login",
            method: .post,
            body: LoginRequest(email: email, password: password)
        )
    }

    /// GET /api/auth/me
    public static var me: Endpoint {
        Endpoint(path: "auth/me", method: .get)
    }
}

// MARK: - Children Endpoints

public enum ChildrenEndpoints {
    /// GET /api/children
    public static var list: Endpoint {
        Endpoint(path: "children", method: .get)
    }

    /// POST /api/children
    public static func create(_ child: CreateChildRequest) -> Endpoint {
        Endpoint(path: "children", method: .post, body: child)
    }

    /// GET /api/children/:id
    public static func get(id: String) -> Endpoint {
        Endpoint(path: "children/\(id)", method: .get)
    }

    /// PUT /api/children/:id
    public static func update(id: String, _ update: UpdateChildRequest) -> Endpoint {
        Endpoint(path: "children/\(id)", method: .put, body: update)
    }

    /// DELETE /api/children/:id
    public static func delete(id: String) -> Endpoint {
        Endpoint(path: "children/\(id)", method: .delete)
    }
}

// MARK: - Lessons Endpoints

public enum LessonsEndpoints {
    /// GET /api/lessons
    public static func list(
        subject: String? = nil,
        gradeLevel: String? = nil,
        difficulty: String? = nil,
        source: String? = nil,
        limit: Int = 20,
        offset: Int = 0
    ) -> Endpoint {
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset))
        ]
        if let subject { queryItems.append(URLQueryItem(name: "subject", value: subject)) }
        if let gradeLevel { queryItems.append(URLQueryItem(name: "gradeLevel", value: gradeLevel)) }
        if let difficulty { queryItems.append(URLQueryItem(name: "difficulty", value: difficulty)) }
        if let source { queryItems.append(URLQueryItem(name: "source", value: source)) }

        return Endpoint(path: "lessons", method: .get, queryItems: queryItems)
    }

    /// GET /api/lessons/subjects
    public static var subjects: Endpoint {
        Endpoint(path: "lessons/subjects", method: .get)
    }

    /// GET /api/lessons/filters
    public static var filters: Endpoint {
        Endpoint(path: "lessons/filters", method: .get)
    }

    /// GET /api/lessons/search
    public static func search(query: String, limit: Int = 20, offset: Int = 0) -> Endpoint {
        Endpoint(
            path: "lessons/search",
            method: .get,
            queryItems: [
                URLQueryItem(name: "q", value: query),
                URLQueryItem(name: "limit", value: String(limit)),
                URLQueryItem(name: "offset", value: String(offset))
            ]
        )
    }

    /// GET /api/lessons/:id
    public static func get(id: String) -> Endpoint {
        Endpoint(path: "lessons/\(id)", method: .get)
    }

    /// POST /api/lessons/:id/rate
    public static func rate(lessonId: String, rating: Int, feedback: String? = nil, childId: String? = nil) -> Endpoint {
        Endpoint(
            path: "lessons/\(lessonId)/rate",
            method: .post,
            body: RateLessonRequest(rating: rating, feedback: feedback, childId: childId)
        )
    }

    /// POST /api/lessons/:id/engagement
    public static func trackEngagement(lessonId: String, childId: String, action: String, timeSeconds: Int? = nil) -> Endpoint {
        Endpoint(
            path: "lessons/\(lessonId)/engagement",
            method: .post,
            body: EngagementRequest(childId: childId, action: action, timeSeconds: timeSeconds)
        )
    }

    /// GET /api/lessons/:id/recommendations
    public static func recommendations(lessonId: String) -> Endpoint {
        Endpoint(path: "lessons/\(lessonId)/recommendations", method: .get)
    }
}

// MARK: - Progress Endpoints

public enum ProgressEndpoints {
    /// GET /api/progress/child/:childId
    public static func forChild(childId: String) -> Endpoint {
        Endpoint(path: "progress/child/\(childId)", method: .get)
    }

    /// GET /api/progress/child/:childId/summary
    public static func summary(childId: String) -> Endpoint {
        Endpoint(path: "progress/child/\(childId)/summary", method: .get)
    }

    /// GET /api/progress/child/:childId/stats
    public static func stats(childId: String) -> Endpoint {
        Endpoint(path: "progress/child/\(childId)/stats", method: .get)
    }

    /// GET /api/progress/child/:childId/recent
    public static func recent(childId: String) -> Endpoint {
        Endpoint(path: "progress/child/\(childId)/recent", method: .get)
    }

    /// GET /api/progress/child/:childId/lesson/:lessonId
    public static func forLesson(childId: String, lessonId: String) -> Endpoint {
        Endpoint(path: "progress/child/\(childId)/lesson/\(lessonId)", method: .get)
    }

    /// POST /api/progress/child/:childId/lesson/:lessonId/start
    public static func startLesson(childId: String, lessonId: String) -> Endpoint {
        Endpoint(path: "progress/child/\(childId)/lesson/\(lessonId)/start", method: .post)
    }

    /// POST /api/progress/child/:childId/lesson/:lessonId/complete
    public static func completeLesson(childId: String, lessonId: String, score: Int? = nil, timeSpent: Int? = nil) -> Endpoint {
        Endpoint(
            path: "progress/child/\(childId)/lesson/\(lessonId)/complete",
            method: .post,
            body: CompleteLessonRequest(score: score, timeSpent: timeSpent)
        )
    }

    /// PUT /api/progress/child/:childId/lesson/:lessonId
    public static func update(childId: String, lessonId: String, status: String? = nil, score: Int? = nil, timeSpent: Int? = nil) -> Endpoint {
        Endpoint(
            path: "progress/child/\(childId)/lesson/\(lessonId)",
            method: .put,
            body: UpdateProgressRequest(status: status, score: score, timeSpent: timeSpent)
        )
    }

    /// POST /api/progress/child/:childId/lesson/:lessonId/activity
    public static func saveActivity(
        childId: String,
        lessonId: String,
        activityId: String,
        completed: Bool,
        score: Int? = nil,
        attempts: Int? = nil,
        timeSpentSeconds: Int? = nil,
        currentActivityIndex: Int? = nil
    ) -> Endpoint {
        Endpoint(
            path: "progress/child/\(childId)/lesson/\(lessonId)/activity",
            method: .post,
            body: ActivityProgressRequest(
                activityId: activityId,
                completed: completed,
                score: score,
                attempts: attempts,
                timeSpentSeconds: timeSpentSeconds,
                currentActivityIndex: currentActivityIndex
            )
        )
    }

    /// GET /api/progress/child/:childId/lesson/:lessonId/activities
    public static func activities(childId: String, lessonId: String) -> Endpoint {
        Endpoint(path: "progress/child/\(childId)/lesson/\(lessonId)/activities", method: .get)
    }
}

// MARK: - Voice Endpoints

public enum VoiceEndpoints {
    /// GET /api/voice/voices
    public static var listVoices: Endpoint {
        Endpoint(path: "voice/voices", method: .get)
    }

    /// GET /api/voice/voices/:voiceId
    public static func getVoice(id: String) -> Endpoint {
        Endpoint(path: "voice/voices/\(id)", method: .get)
    }

    /// POST /api/voice/tts
    public static func textToSpeech(
        text: String,
        voiceId: String? = nil,
        modelId: String? = nil,
        voiceSettings: VoiceSettings? = nil
    ) -> Endpoint {
        Endpoint(
            path: "voice/tts",
            method: .post,
            body: TTSRequest(
                text: text,
                voiceId: voiceId,
                modelId: modelId,
                voiceSettings: voiceSettings
            )
        )
    }

    /// GET /api/voice/settings/:childId
    public static func getSettings(childId: String) -> Endpoint {
        Endpoint(path: "voice/settings/\(childId)", method: .get)
    }

    /// PUT /api/voice/settings/:childId
    public static func updateSettings(childId: String, settings: VoiceSettingsUpdate) -> Endpoint {
        Endpoint(path: "voice/settings/\(childId)", method: .put, body: settings)
    }
}

// MARK: - Onboarding Endpoints

public enum OnboardingEndpoints {
    /// GET /api/onboarding
    public static var get: Endpoint {
        Endpoint(path: "onboarding", method: .get)
    }

    /// PUT /api/onboarding
    public static func update(step: Int? = nil, data: [String: Any]? = nil, completed: Bool? = nil) -> Endpoint {
        Endpoint(
            path: "onboarding",
            method: .put,
            body: OnboardingUpdateRequest(step: step, completed: completed)
        )
    }

    /// POST /api/onboarding/complete
    public static var complete: Endpoint {
        Endpoint(path: "onboarding/complete", method: .post)
    }
}

// MARK: - Request Types
// Note: RegisterRequest, LoginRequest, CreateChildRequest, UpdateChildRequest are defined in APIModels.swift

public struct RateLessonRequest: Encodable {
    public let rating: Int
    public let feedback: String?
    public let childId: String?
}

public struct EngagementRequest: Encodable {
    public let childId: String
    public let action: String
    public let timeSeconds: Int?
}

public struct CompleteLessonRequest: Encodable {
    public let score: Int?
    public let timeSpent: Int?
}

public struct UpdateProgressRequest: Encodable {
    public let status: String?
    public let score: Int?
    public let timeSpent: Int?
}

public struct ActivityProgressRequest: Encodable {
    public let activityId: String
    public let completed: Bool
    public let score: Int?
    public let attempts: Int?
    public let timeSpentSeconds: Int?
    public let currentActivityIndex: Int?
}

public struct VoiceSettings: Encodable {
    public let stability: Double?
    public let similarityBoost: Double?
    public let style: Double?
    public let speed: Double?
    public let useSpeakerBoost: Bool?

    public init(
        stability: Double? = nil,
        similarityBoost: Double? = nil,
        style: Double? = nil,
        speed: Double? = nil,
        useSpeakerBoost: Bool? = nil
    ) {
        self.stability = stability
        self.similarityBoost = similarityBoost
        self.style = style
        self.speed = speed
        self.useSpeakerBoost = useSpeakerBoost
    }
}

public struct TTSRequest: Encodable {
    public let text: String
    public let voiceId: String?
    public let modelId: String?
    public let voiceSettings: VoiceSettings?
}

public struct VoiceSettingsUpdate: Encodable {
    public let voiceId: String?
    public let speed: Double?
    public let stability: Double?
    public let similarityBoost: Double?

    public init(
        voiceId: String? = nil,
        speed: Double? = nil,
        stability: Double? = nil,
        similarityBoost: Double? = nil
    ) {
        self.voiceId = voiceId
        self.speed = speed
        self.stability = stability
        self.similarityBoost = similarityBoost
    }
}

public struct OnboardingUpdateRequest: Encodable {
    public let step: Int?
    public let completed: Bool?
}
