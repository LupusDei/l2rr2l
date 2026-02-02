import Foundation
import Combine

/// Represents each step in the onboarding flow
enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case name = 1
    case age = 2
    case gender = 3
    case avatar = 4
    case completion = 5

    var title: String {
        switch self {
        case .welcome: return "Welcome"
        case .name: return "What's your name?"
        case .age: return "How old are you?"
        case .gender: return "Tell us about yourself"
        case .avatar: return "Choose your avatar"
        case .completion: return "You're all set!"
        }
    }

    var isSkippable: Bool {
        switch self {
        case .gender: return true
        default: return false
        }
    }
}

/// Data collected during onboarding
struct OnboardingData: Codable, Equatable {
    var name: String = ""
    var age: Int?
    var gender: String?
    var avatar: String?

    var isNameValid: Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 1 && trimmed.count <= 20
    }

    var isAgeValid: Bool {
        guard let age = age else { return false }
        return age >= 3 && age <= 12
    }

    var isAvatarValid: Bool {
        avatar != nil && !avatar!.isEmpty
    }
}

/// ViewModel managing the onboarding flow state and logic
@MainActor
class OnboardingViewModel: BaseViewModel {
    // MARK: - Published Properties

    @Published private(set) var currentStep: OnboardingStep = .welcome
    @Published var data = OnboardingData()
    @Published private(set) var isSubmitting = false
    @Published private(set) var isComplete = false

    // MARK: - Computed Properties

    var totalSteps: Int {
        OnboardingStep.allCases.count
    }

    var progress: Double {
        Double(currentStep.rawValue) / Double(totalSteps - 1)
    }

    var canProceed: Bool {
        switch currentStep {
        case .welcome:
            return true
        case .name:
            return data.isNameValid
        case .age:
            return data.isAgeValid
        case .gender:
            return true // Always can proceed (skippable)
        case .avatar:
            return data.isAvatarValid
        case .completion:
            return true
        }
    }

    var canGoBack: Bool {
        currentStep.rawValue > 0 && currentStep != .completion
    }

    var currentStepIndex: Int {
        currentStep.rawValue
    }

    // MARK: - Private Properties

    private let persistenceKey = "onboarding_progress"
    private let appState: AppState

    // MARK: - Initialization

    init(appState: AppState = .shared) {
        self.appState = appState
        super.init()
        loadProgress()
    }

    // MARK: - Navigation

    /// Advances to the next step if validation passes
    func nextStep() {
        guard canProceed else { return }

        if let next = OnboardingStep(rawValue: currentStep.rawValue + 1) {
            currentStep = next
            saveProgress()
        }
    }

    /// Returns to the previous step
    func previousStep() {
        guard canGoBack else { return }

        if let previous = OnboardingStep(rawValue: currentStep.rawValue - 1) {
            currentStep = previous
            saveProgress()
        }
    }

    /// Skips the current step if it's skippable
    func skip() {
        guard currentStep.isSkippable else { return }

        // Clear data for skipped step
        switch currentStep {
        case .gender:
            data.gender = nil
        default:
            break
        }

        nextStep()
    }

    /// Jumps to a specific step (for editing previous answers)
    func goToStep(_ step: OnboardingStep) {
        guard step.rawValue < currentStep.rawValue else { return }
        currentStep = step
        saveProgress()
    }

    // MARK: - Data Updates

    func setName(_ name: String) {
        data.name = name
        saveProgress()
    }

    func setAge(_ age: Int) {
        data.age = age
        saveProgress()
    }

    func setGender(_ gender: String?) {
        data.gender = gender
        saveProgress()
    }

    func setAvatar(_ avatar: String) {
        data.avatar = avatar
        saveProgress()
    }

    // MARK: - Completion

    /// Submits the onboarding data to complete the flow
    func complete() async throws {
        guard currentStep == .completion else { return }

        isSubmitting = true
        defer { isSubmitting = false }

        // Simulate API call - in production this would POST to /onboarding/:userId/complete
        try await submitOnboarding()

        // Update app state with the new child profile
        let childId = UUID().uuidString
        appState.setCurrentChild(id: childId, name: data.name)

        // Clear saved progress
        clearProgress()

        isComplete = true
    }

    // MARK: - Persistence

    private func saveProgress() {
        let progressData = OnboardingProgress(
            stepIndex: currentStep.rawValue,
            data: data
        )

        if let encoded = try? JSONEncoder().encode(progressData) {
            UserDefaults.standard.set(encoded, forKey: persistenceKey)
        }
    }

    private func loadProgress() {
        guard let savedData = UserDefaults.standard.data(forKey: persistenceKey),
              let progress = try? JSONDecoder().decode(OnboardingProgress.self, from: savedData) else {
            return
        }

        if let step = OnboardingStep(rawValue: progress.stepIndex) {
            currentStep = step
        }
        data = progress.data
    }

    private func clearProgress() {
        UserDefaults.standard.removeObject(forKey: persistenceKey)
    }

    /// Resets onboarding to start fresh
    func reset() {
        currentStep = .welcome
        data = OnboardingData()
        isComplete = false
        clearProgress()
    }

    // MARK: - API

    private func submitOnboarding() async throws {
        guard let baseURL = URL(string: appState.apiBaseURL.absoluteString) else {
            throw ServiceError.invalidResponse
        }

        let userId = appState.currentChildId ?? "new"
        let url = baseURL.appendingPathComponent("onboarding/\(userId)/complete")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = OnboardingPayload(
            name: data.name,
            age: data.age ?? 0,
            gender: data.gender,
            avatar: data.avatar ?? ""
        )

        request.httpBody = try JSONEncoder().encode(payload)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ServiceError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw ServiceError.unauthorized
        case 404:
            throw ServiceError.notFound
        default:
            throw ServiceError.serverError(statusCode: httpResponse.statusCode, message: nil)
        }
    }
}

// MARK: - Supporting Types

private struct OnboardingProgress: Codable {
    let stepIndex: Int
    let data: OnboardingData
}

private struct OnboardingPayload: Codable {
    let name: String
    let age: Int
    let gender: String?
    let avatar: String
}
