import SwiftUI

struct ContentView: View {
    @ObservedObject private var onboardingService = OnboardingService.shared

    var body: some View {
        Group {
            if onboardingService.isComplete {
                MainTabView()
            } else {
                OnboardingFlow()
            }
        }
        .animation(.easeInOut(duration: L2RTheme.Animation.slow), value: onboardingService.isComplete)
    }
}

#Preview {
    ContentView()
}
