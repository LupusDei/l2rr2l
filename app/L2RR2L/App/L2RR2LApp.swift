import SwiftUI

@main
struct L2RR2LApp: App {
    @State private var services = AppServices.launch()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .withServices(services)
                .preferredColorScheme(.dark)
                .statusBarHidden()
                .persistentSystemOverlays(.hidden)
                .onAppear {
                    services.parallax.start()
                    #if DEBUG
                    // `-landscape` launch argument: rotate the simulator for screenshots.
                    // `-demoProgress`: placement done, Stage 1 words known, treats to feed,
                    // so the Sky Trial and treasure can be tried without playing for days.
                    if CommandLine.arguments.contains("-demoProgress") { DemoProgress.seed(services.progress) }
                    if CommandLine.arguments.contains("-uitest") {
                        // `-uitestGame readAlong` picks the game; Word Machine by default
                        let args = CommandLine.arguments
                        let game = args.firstIndex(of: "-uitestGame").flatMap { $0 + 1 < args.count ? GameID(rawValue: args[$0 + 1]) : nil }
                        services.router.open(.game(game ?? .wordMachine))
                    }
                    if CommandLine.arguments.contains("-openTreasure") { services.router.open(.treasure(fromSession: true)) }
                    if CommandLine.arguments.contains("-landscape") {
                        // asked once the scene is active, or the request is ignored
                        Task { @MainActor in
                            try? await Task.sleep(for: .seconds(1))
                            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
                            scene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscapeRight)) { print("landscape:", $0) }
                        }
                    }
                    #endif
                }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { services.progress.saveNow() }
        }
    }
}

extension View {
    /// Puts every shared service in the environment (app and previews).
    func withServices(_ services: AppServices) -> some View {
        environment(services)
            .environment(services.router)
            .environment(services.progress)
            .environment(services.mascot)
            .environment(services.voice)
            .environment(services.celebration)
            .environment(services.parallax)
    }
}

#if DEBUG
enum DemoProgress {
    @MainActor
    static func seed(_ progress: ProgressStore) {
        guard !progress.data.placementDone else { return }
        progress.completePlacement(startingStage: 1)
        let cal = Calendar(identifier: .gregorian)
        for daysAgo in [2, 1] {
            let date = cal.date(byAdding: .day, value: -daysAgo, to: .now)!
            for item in WordBank.items(in: 1) {
                progress.recordAnswer(game: .starCatch, word: item.word.text, correct: true, responseTime: 2, now: date)
            }
        }
        progress.awardStars(18, game: .starCatch)
    }
}
#endif
