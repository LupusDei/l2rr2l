import Foundation
import Combine

/// Global application state container.
/// Manages app-wide state that needs to be shared across multiple views and ViewModels.
@MainActor
final class AppState: ObservableObject {
    // MARK: - Singleton

    static let shared = AppState()

    // MARK: - Published Properties

    /// Current child profile ID
    @Published var currentChildId: String?

    /// Current child profile name
    @Published var currentChildName: String?

    /// Whether the app is in a learning session
    @Published private(set) var isInSession = false

    /// Network connectivity status
    @Published private(set) var isNetworkAvailable = true

    /// Current API base URL
    @Published var apiBaseURL: URL = URL(string: "http://localhost:8787/api")!

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    private init() {
        loadPersistedState()
        registerDependencies()
    }

    /// Registers application services in the dependency container
    private func registerDependencies() {
        let container = DependencyContainer.shared

        // Register AppState itself
        container.registerSingleton(AppState.self, instance: self)

        // Register additional services here as the app grows
    }

    // MARK: - State Updates

    /// Updates the session state
    /// - Parameter inSession: Whether a learning session is active
    func updateSessionState(_ inSession: Bool) {
        isInSession = inSession
    }

    /// Updates network availability
    /// - Parameter available: Whether network is available
    func updateNetworkAvailability(_ available: Bool) {
        isNetworkAvailable = available
    }

    /// Sets the current child profile
    /// - Parameters:
    ///   - id: The child's unique identifier
    ///   - name: The child's display name
    func setCurrentChild(id: String, name: String) {
        currentChildId = id
        currentChildName = name
        persistChildProfile()
    }

    /// Clears the current child profile
    func clearCurrentChild() {
        currentChildId = nil
        currentChildName = nil
        UserDefaults.standard.removeObject(forKey: "currentChildId")
        UserDefaults.standard.removeObject(forKey: "currentChildName")
    }

    // MARK: - Persistence

    private func loadPersistedState() {
        // Load child profile
        currentChildId = UserDefaults.standard.string(forKey: "currentChildId")
        currentChildName = UserDefaults.standard.string(forKey: "currentChildName")

        // Load API URL
        if let urlString = UserDefaults.standard.string(forKey: "apiBaseURL"),
           let url = URL(string: urlString) {
            apiBaseURL = url
        }

        // Set up persistence observers
        $apiBaseURL
            .dropFirst()
            .sink { url in
                UserDefaults.standard.set(url.absoluteString, forKey: "apiBaseURL")
            }
            .store(in: &cancellables)
    }

    private func persistChildProfile() {
        if let id = currentChildId {
            UserDefaults.standard.set(id, forKey: "currentChildId")
        }
        if let name = currentChildName {
            UserDefaults.standard.set(name, forKey: "currentChildName")
        }
    }
}
