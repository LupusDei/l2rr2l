import SwiftUI

/// Container view that manages the onboarding step sequence.
/// Shows each onboarding step in order and transitions to the main app when complete.
struct OnboardingFlow: View {
    @ObservedObject var onboardingService = OnboardingService.shared

    @State private var childName: String = ""
    @State private var childAge: Int = 5
    @State private var childAvatar: String = ""

    @State private var currentStep: OnboardingFlowStep = .name

    enum OnboardingFlowStep {
        case name
        case age
        case avatar
        case completion
    }

    var body: some View {
        ZStack {
            switch currentStep {
            case .name:
                NameEntryView { name in
                    childName = name
                    withAnimation(.easeInOut(duration: L2RTheme.Animation.slow)) {
                        currentStep = .age
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

            case .age:
                AgeSelectionView { age in
                    childAge = age
                    withAnimation(.easeInOut(duration: L2RTheme.Animation.slow)) {
                        currentStep = .avatar
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

            case .avatar:
                AvatarSelectionView { avatar in
                    childAvatar = avatar
                    withAnimation(.easeInOut(duration: L2RTheme.Animation.slow)) {
                        currentStep = .completion
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

            case .completion:
                OnboardingCompletionView(
                    childName: childName,
                    childAge: childAge,
                    childAvatar: childAvatar
                ) {
                    // Save child profile
                    let appState = AppState.shared
                    appState.currentChildName = childName

                    // Mark onboarding complete
                    onboardingService.completeOnboarding()
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .opacity
                ))
            }
        }
        .animation(.easeInOut(duration: L2RTheme.Animation.slow), value: currentStep)
    }
}

#Preview {
    OnboardingFlow()
}
