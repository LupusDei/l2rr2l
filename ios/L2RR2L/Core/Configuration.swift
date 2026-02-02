import Foundation

/// Application environment configuration
/// Reads values from Info.plist which are set via build configuration
enum AppEnvironment: String {
    case development
    case staging
    case production

    /// Current app environment based on build configuration
    static var current: AppEnvironment {
        #if DEBUG
        return .development
        #else
        guard let envString = Bundle.main.infoDictionary?["APP_ENVIRONMENT"] as? String,
              let env = AppEnvironment(rawValue: envString) else {
            return .production
        }
        return env
        #endif
    }

    /// Whether this is a development build
    static var isDevelopment: Bool {
        current == .development
    }

    /// Whether this is a production build
    static var isProduction: Bool {
        current == .production
    }
}

/// Application configuration providing environment-aware settings
enum Configuration {

    // MARK: - API Configuration

    /// Base URL for API requests
    static var apiBaseURL: URL {
        if let urlString = Bundle.main.infoDictionary?["API_BASE_URL"] as? String,
           let url = URL(string: urlString) {
            return url
        }

        // Fallback based on environment
        switch AppEnvironment.current {
        case .development:
            return URL(string: "http://localhost:8787/api")!
        case .staging:
            return URL(string: "https://staging.l2rr2l.pages.dev/api")!
        case .production:
            return URL(string: "https://l2rr2l.pages.dev/api")!
        }
    }

    // MARK: - App Info

    /// App version string (e.g., "1.0")
    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    /// Build number (e.g., "1")
    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    /// Full version string (e.g., "1.0 (1)")
    static var fullVersionString: String {
        "\(appVersion) (\(buildNumber))"
    }

    /// Bundle identifier
    static var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "com.l2rr2l.app"
    }

    // MARK: - Feature Flags

    /// Whether debug logging is enabled
    static var isDebugLoggingEnabled: Bool {
        #if DEBUG
        return true
        #else
        return Bundle.main.infoDictionary?["ENABLE_DEBUG_LOGGING"] as? Bool ?? false
        #endif
    }

    /// Whether analytics are enabled
    static var isAnalyticsEnabled: Bool {
        #if DEBUG
        return false
        #else
        return Bundle.main.infoDictionary?["ENABLE_ANALYTICS"] as? Bool ?? true
        #endif
    }

    /// Whether crash reporting is enabled
    static var isCrashReportingEnabled: Bool {
        #if DEBUG
        return false
        #else
        return Bundle.main.infoDictionary?["ENABLE_CRASH_REPORTING"] as? Bool ?? true
        #endif
    }

    // MARK: - Timeouts

    /// Default network request timeout in seconds
    static var networkTimeout: TimeInterval {
        30.0
    }

    /// Audio playback timeout in seconds
    static var audioTimeout: TimeInterval {
        10.0
    }
}
