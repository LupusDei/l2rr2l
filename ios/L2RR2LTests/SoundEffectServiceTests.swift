import XCTest
@testable import L2RR2L

@MainActor
final class SoundEffectServiceTests: XCTestCase {
    var service: SoundEffectService!

    override func setUp() async throws {
        service = SoundEffectService(isEnabled: true)
    }

    // MARK: - Sound Effect Enum Tests

    func testSoundEffectFilenames() {
        XCTAssertEqual(SoundEffectService.SoundEffect.correct.filename, "correct")
        XCTAssertEqual(SoundEffectService.SoundEffect.incorrect.filename, "incorrect")
        XCTAssertEqual(SoundEffectService.SoundEffect.flip.filename, "flip")
        XCTAssertEqual(SoundEffectService.SoundEffect.match.filename, "match")
        XCTAssertEqual(SoundEffectService.SoundEffect.levelComplete.filename, "level_complete")
        XCTAssertEqual(SoundEffectService.SoundEffect.buttonTap.filename, "button_tap")
        XCTAssertEqual(SoundEffectService.SoundEffect.streak.filename, "streak")
        XCTAssertEqual(SoundEffectService.SoundEffect.confetti.filename, "confetti")
    }

    func testAllSoundEffectsExist() {
        XCTAssertEqual(SoundEffectService.SoundEffect.allCases.count, 8)
    }

    // MARK: - Enable/Disable Tests

    func testInitiallyEnabled() {
        let enabledService = SoundEffectService(isEnabled: true)
        XCTAssertTrue(enabledService.isEnabled)
    }

    func testInitiallyDisabled() {
        let disabledService = SoundEffectService(isEnabled: false)
        XCTAssertFalse(disabledService.isEnabled)
    }

    func testSetEnabledTrue() {
        service.setEnabled(false)
        XCTAssertFalse(service.isEnabled)
        service.setEnabled(true)
        XCTAssertTrue(service.isEnabled)
    }

    func testSetEnabledFalse() {
        service.setEnabled(true)
        XCTAssertTrue(service.isEnabled)
        service.setEnabled(false)
        XCTAssertFalse(service.isEnabled)
    }

    // MARK: - Preload Tests

    func testPreloadDoesNotCrash() {
        // Preload should not crash even if sound files don't exist
        service.preload()
    }

    // MARK: - Play Tests

    func testPlayWhenDisabledDoesNotCrash() {
        service.setEnabled(false)
        // Should not crash when disabled
        service.play(.correct)
    }

    func testPlayWhenEnabledDoesNotCrash() {
        service.setEnabled(true)
        // Should not crash even if sound file doesn't exist
        service.play(.correct)
    }

    func testPlayAllSoundsDoesNotCrash() {
        service.setEnabled(true)
        // Should not crash for any sound effect
        for effect in SoundEffectService.SoundEffect.allCases {
            service.play(effect)
        }
    }

    // MARK: - Singleton Tests

    func testSharedInstanceExists() {
        XCTAssertNotNil(SoundEffectService.shared)
    }
}
