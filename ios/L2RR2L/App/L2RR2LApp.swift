import SwiftUI
import SwiftData

@main
struct L2RR2LApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: L2RR2LModelSchema.all)
    }
}

/// SwiftData model schema for L2RR2L app.
/// This provides the schema types needed for the model container.
enum L2RR2LModelSchema {
    static var all: [any PersistentModel.Type] {
        [
            CachedChild.self,
            CachedLesson.self,
            LocalProgress.self,
            LocalVoiceSettings.self,
            LocalOnboardingState.self
        ]
    }
}
