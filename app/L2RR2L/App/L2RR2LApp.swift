import SwiftUI

@main
struct L2RR2LApp: App {
    @State private var services = AppServices.live()
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
                    if CommandLine.arguments.contains("-landscape"),
                       let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        scene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscapeRight))
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
