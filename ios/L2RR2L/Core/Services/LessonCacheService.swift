import Foundation
import Network

/// Thread-safe caching service for lesson data with offline support.
/// Uses file-based storage for lesson data and UserDefaults for cache metadata.
public actor LessonCacheService {
    public static let shared = LessonCacheService()

    // MARK: - Configuration

    private let cacheTTL: TimeInterval = 5 * 60 // 5 minutes
    private let cacheDirectory: URL
    private let lessonsFileName = "cached_lessons.json"
    private let metadataKey = "LessonCacheMetadata"

    // MARK: - State

    private var cachedLessons: [Lesson] = []
    private var cachedLessonDetails: [String: Lesson] = [:]
    private var isInitialized = false

    // MARK: - Network Monitoring (Non-isolated)

    private let pathMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.l2rr2l.lessonCache.network")
    private var _isOnline = true

    // MARK: - Initialization

    init(cacheDirectory: URL? = nil) {
        if let dir = cacheDirectory {
            self.cacheDirectory = dir
        } else {
            self.cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
                .first!
                .appendingPathComponent("LessonCache", isDirectory: true)
        }

        // Start network monitoring
        pathMonitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            Task {
                await self.updateNetworkStatus(isOnline: path.status == .satisfied)
            }
        }
        pathMonitor.start(queue: monitorQueue)
    }

    deinit {
        pathMonitor.cancel()
    }

    // MARK: - Public API

    /// Returns cached lessons if available and valid, nil otherwise.
    public func getCachedLessons() async -> [Lesson]? {
        await initializeIfNeeded()

        guard isCacheValid() else {
            return nil
        }

        return cachedLessons.isEmpty ? nil : cachedLessons
    }

    /// Caches the provided lessons list.
    public func cacheLessons(_ lessons: [Lesson]) async {
        await initializeIfNeeded()

        cachedLessons = lessons
        updateCacheTimestamp()
        await persistLessons()

        // Also cache individual lessons for detail access
        for lesson in lessons {
            cachedLessonDetails[lesson.id] = lesson
        }
        await persistLessonDetails()
    }

    /// Returns a cached lesson by ID if available.
    public func getCachedLesson(id: String) async -> Lesson? {
        await initializeIfNeeded()
        return cachedLessonDetails[id]
    }

    /// Caches an individual lesson (useful for detail fetches).
    public func cacheLesson(_ lesson: Lesson) async {
        await initializeIfNeeded()

        cachedLessonDetails[lesson.id] = lesson
        await persistLessonDetails()
    }

    /// Invalidates all cached data.
    public func invalidateAll() async {
        cachedLessons = []
        cachedLessonDetails = [:]
        clearCacheTimestamp()

        // Remove persisted files
        try? FileManager.default.removeItem(at: lessonsFileURL)
        try? FileManager.default.removeItem(at: lessonDetailsFileURL)
    }

    /// Checks if the lesson list cache is valid (not expired).
    public func isCacheValid() -> Bool {
        guard let metadata = getCacheMetadata(),
              let timestamp = metadata.lessonsListTimestamp else {
            return false
        }

        return Date().timeIntervalSince(timestamp) < cacheTTL
    }

    /// Returns whether the device is currently online.
    public func isOnline() async -> Bool {
        return _isOnline
    }

    /// Returns cache statistics for debugging/UI.
    public func getCacheStats() async -> CacheStats {
        await initializeIfNeeded()

        let metadata = getCacheMetadata()
        let isValid = isCacheValid()
        let lessonsCount = cachedLessons.count
        let detailsCount = cachedLessonDetails.count

        var ageSeconds: TimeInterval?
        if let timestamp = metadata?.lessonsListTimestamp {
            ageSeconds = Date().timeIntervalSince(timestamp)
        }

        return CacheStats(
            lessonsCount: lessonsCount,
            lessonDetailsCount: detailsCount,
            isValid: isValid,
            ageSeconds: ageSeconds,
            ttlSeconds: cacheTTL,
            isOnline: _isOnline
        )
    }

    // MARK: - Private Methods

    private func initializeIfNeeded() async {
        guard !isInitialized else { return }

        // Ensure cache directory exists
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        // Load cached data from disk
        await loadPersistedLessons()
        await loadPersistedLessonDetails()

        isInitialized = true
    }

    private func updateNetworkStatus(isOnline: Bool) {
        _isOnline = isOnline
    }

    // MARK: - File URLs

    private var lessonsFileURL: URL {
        cacheDirectory.appendingPathComponent(lessonsFileName)
    }

    private var lessonDetailsFileURL: URL {
        cacheDirectory.appendingPathComponent("cached_lesson_details.json")
    }

    // MARK: - Persistence

    private func persistLessons() async {
        do {
            let data = try JSONEncoder().encode(cachedLessons)
            try data.write(to: lessonsFileURL)
        } catch {
            logError("Failed to persist lessons: \(error)")
        }
    }

    private func loadPersistedLessons() async {
        guard FileManager.default.fileExists(atPath: lessonsFileURL.path) else {
            return
        }

        do {
            let data = try Data(contentsOf: lessonsFileURL)
            cachedLessons = try JSONDecoder().decode([Lesson].self, from: data)
        } catch {
            logError("Failed to load persisted lessons: \(error)")
        }
    }

    private func persistLessonDetails() async {
        do {
            let data = try JSONEncoder().encode(cachedLessonDetails)
            try data.write(to: lessonDetailsFileURL)
        } catch {
            logError("Failed to persist lesson details: \(error)")
        }
    }

    private func loadPersistedLessonDetails() async {
        guard FileManager.default.fileExists(atPath: lessonDetailsFileURL.path) else {
            return
        }

        do {
            let data = try Data(contentsOf: lessonDetailsFileURL)
            cachedLessonDetails = try JSONDecoder().decode([String: Lesson].self, from: data)
        } catch {
            logError("Failed to load persisted lesson details: \(error)")
        }
    }

    // MARK: - Cache Metadata

    private func getCacheMetadata() -> CacheMetadata? {
        guard let data = UserDefaults.standard.data(forKey: metadataKey) else {
            return nil
        }
        return try? JSONDecoder().decode(CacheMetadata.self, from: data)
    }

    private func updateCacheTimestamp() {
        var metadata = getCacheMetadata() ?? CacheMetadata()
        metadata.lessonsListTimestamp = Date()

        if let data = try? JSONEncoder().encode(metadata) {
            UserDefaults.standard.set(data, forKey: metadataKey)
        }
    }

    private func clearCacheTimestamp() {
        UserDefaults.standard.removeObject(forKey: metadataKey)
    }

    // MARK: - Logging

    private func logError(_ message: String) {
        #if DEBUG
        print("[LessonCache] ERROR: \(message)")
        #endif
    }
}

// MARK: - Supporting Types

/// Metadata stored in UserDefaults for cache timing.
private struct CacheMetadata: Codable {
    var lessonsListTimestamp: Date?
}

/// Statistics about the current cache state.
public struct CacheStats: Equatable {
    public let lessonsCount: Int
    public let lessonDetailsCount: Int
    public let isValid: Bool
    public let ageSeconds: TimeInterval?
    public let ttlSeconds: TimeInterval
    public let isOnline: Bool

    /// Human-readable cache age.
    public var ageDescription: String {
        guard let age = ageSeconds else {
            return "Not cached"
        }

        if age < 60 {
            return "\(Int(age))s ago"
        } else if age < 3600 {
            return "\(Int(age / 60))m ago"
        } else {
            return "\(Int(age / 3600))h ago"
        }
    }

    /// Time remaining until cache expires.
    public var remainingTTL: TimeInterval? {
        guard let age = ageSeconds, isValid else {
            return nil
        }
        return ttlSeconds - age
    }
}
