import XCTest
@testable import L2RR2LCore

final class LessonCacheServiceTests: XCTestCase {
    var cacheService: LessonCacheService!
    var testCacheDirectory: URL!

    override func setUp() async throws {
        try await super.setUp()
        testCacheDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("LessonCacheTests-\(UUID().uuidString)")
        cacheService = LessonCacheService(cacheDirectory: testCacheDirectory)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: testCacheDirectory)
        cacheService = nil
        try await super.tearDown()
    }

    // MARK: - Cache Lessons List Tests

    func testCacheLessonsAndRetrieve() async {
        let lessons = createTestLessons(count: 3)

        await cacheService.cacheLessons(lessons)
        let cached = await cacheService.getCachedLessons()

        XCTAssertNotNil(cached)
        XCTAssertEqual(cached?.count, 3)
        XCTAssertEqual(cached?.first?.id, lessons.first?.id)
    }

    func testGetCachedLessonsReturnsNilWhenEmpty() async {
        let cached = await cacheService.getCachedLessons()
        XCTAssertNil(cached)
    }

    func testCacheValidityAfterCaching() async {
        let lessons = createTestLessons(count: 1)

        await cacheService.cacheLessons(lessons)
        let isValid = await cacheService.isCacheValid()

        XCTAssertTrue(isValid)
    }

    // MARK: - Cache Individual Lesson Tests

    func testCacheAndRetrieveIndividualLesson() async {
        let lesson = createTestLesson(id: "test-lesson-1")

        await cacheService.cacheLesson(lesson)
        let cached = await cacheService.getCachedLesson(id: "test-lesson-1")

        XCTAssertNotNil(cached)
        XCTAssertEqual(cached?.id, "test-lesson-1")
        XCTAssertEqual(cached?.title, lesson.title)
    }

    func testGetCachedLessonReturnsNilForUnknownId() async {
        let cached = await cacheService.getCachedLesson(id: "unknown-id")
        XCTAssertNil(cached)
    }

    func testCachingLessonsListAlsoCachesIndividualLessons() async {
        let lessons = createTestLessons(count: 3)

        await cacheService.cacheLessons(lessons)

        for lesson in lessons {
            let cached = await cacheService.getCachedLesson(id: lesson.id)
            XCTAssertNotNil(cached)
            XCTAssertEqual(cached?.id, lesson.id)
        }
    }

    // MARK: - Invalidation Tests

    func testInvalidateAllClearsCache() async {
        let lessons = createTestLessons(count: 3)
        await cacheService.cacheLessons(lessons)

        await cacheService.invalidateAll()

        let cachedList = await cacheService.getCachedLessons()
        let cachedDetail = await cacheService.getCachedLesson(id: lessons.first!.id)
        let isValid = await cacheService.isCacheValid()

        XCTAssertNil(cachedList)
        XCTAssertNil(cachedDetail)
        XCTAssertFalse(isValid)
    }

    // MARK: - Cache Stats Tests

    func testGetCacheStatsReturnsCorrectCounts() async {
        let lessons = createTestLessons(count: 5)
        await cacheService.cacheLessons(lessons)

        let stats = await cacheService.getCacheStats()

        XCTAssertEqual(stats.lessonsCount, 5)
        XCTAssertEqual(stats.lessonDetailsCount, 5)
        XCTAssertTrue(stats.isValid)
        XCTAssertNotNil(stats.ageSeconds)
        XCTAssertEqual(stats.ttlSeconds, 5 * 60)
    }

    func testCacheStatsAgeDescription() {
        let recentStats = CacheStats(
            lessonsCount: 1,
            lessonDetailsCount: 1,
            isValid: true,
            ageSeconds: 30,
            ttlSeconds: 300,
            isOnline: true
        )
        XCTAssertEqual(recentStats.ageDescription, "30s ago")

        let minutesStats = CacheStats(
            lessonsCount: 1,
            lessonDetailsCount: 1,
            isValid: true,
            ageSeconds: 120,
            ttlSeconds: 300,
            isOnline: true
        )
        XCTAssertEqual(minutesStats.ageDescription, "2m ago")

        let noCacheStats = CacheStats(
            lessonsCount: 0,
            lessonDetailsCount: 0,
            isValid: false,
            ageSeconds: nil,
            ttlSeconds: 300,
            isOnline: true
        )
        XCTAssertEqual(noCacheStats.ageDescription, "Not cached")
    }

    func testCacheStatsRemainingTTL() {
        let validStats = CacheStats(
            lessonsCount: 1,
            lessonDetailsCount: 1,
            isValid: true,
            ageSeconds: 60,
            ttlSeconds: 300,
            isOnline: true
        )
        XCTAssertEqual(validStats.remainingTTL, 240)

        let invalidStats = CacheStats(
            lessonsCount: 1,
            lessonDetailsCount: 1,
            isValid: false,
            ageSeconds: 400,
            ttlSeconds: 300,
            isOnline: true
        )
        XCTAssertNil(invalidStats.remainingTTL)
    }

    // MARK: - Network Status Tests

    func testIsOnlineReturnsStatus() async {
        let isOnline = await cacheService.isOnline()
        // Network status depends on actual device state
        XCTAssertNotNil(isOnline)
    }

    // MARK: - Test Helpers

    private func createTestLessons(count: Int) -> [Lesson] {
        return (0..<count).map { createTestLesson(id: "lesson-\($0)") }
    }

    private func createTestLesson(id: String) -> Lesson {
        Lesson(
            id: id,
            title: "Test Lesson \(id)",
            description: "A test lesson for unit testing",
            subject: .phonics,
            difficulty: .beginner,
            objectives: ["Learn something"],
            activities: [],
            durationMinutes: 10,
            prerequisites: nil,
            tags: ["test"],
            thumbnailUrl: nil,
            ageRange: Lesson.AgeRange(min: 4, max: 6),
            createdAt: "2026-01-01T00:00:00Z",
            updatedAt: "2026-01-01T00:00:00Z"
        )
    }
}
