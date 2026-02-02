import Foundation

@MainActor
final class OnboardingService: ObservableObject {
    static let shared = OnboardingService()

    @Published private(set) var isComplete = false
    @Published private(set) var currentStep: OnboardingStep = .welcome

    private let completedKey = "onboarding_completed"
    private let stepKey = "onboarding_step"

    private init() {
        loadState()
    }

    // MARK: - Public Methods

    func completeStep(_ step: OnboardingStep) {
        if step == currentStep {
            if let nextStep = step.next {
                currentStep = nextStep
                saveStep()
            } else {
                completeOnboarding()
            }
        }
    }

    func completeOnboarding() {
        isComplete = true
        UserDefaults.standard.set(true, forKey: completedKey)
    }

    func resetOnboarding() {
        isComplete = false
        currentStep = .welcome
        UserDefaults.standard.removeObject(forKey: completedKey)
        UserDefaults.standard.removeObject(forKey: stepKey)
    }

    // MARK: - Private Methods

    private func loadState() {
        isComplete = UserDefaults.standard.bool(forKey: completedKey)
        if let stepRaw = UserDefaults.standard.string(forKey: stepKey),
           let step = OnboardingStep(rawValue: stepRaw) {
            currentStep = step
        }
    }

    private func saveStep() {
        UserDefaults.standard.set(currentStep.rawValue, forKey: stepKey)
    }
}

// MARK: - Onboarding Step

enum OnboardingStep: String, CaseIterable {
    case welcome
    case nameEntry
    case voiceSetup
    case tutorial

    var next: OnboardingStep? {
        let allCases = OnboardingStep.allCases
        guard let currentIndex = allCases.firstIndex(of: self),
              currentIndex + 1 < allCases.count else {
            return nil
        }
        return allCases[currentIndex + 1]
    }

    var title: String {
        switch self {
        case .welcome:
            return "Welcome"
        case .nameEntry:
            return "What's Your Name?"
        case .voiceSetup:
            return "Voice Settings"
        case .tutorial:
            return "Quick Tour"
        }
    }
}
