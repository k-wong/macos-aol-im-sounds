import XCTest
@testable import AIMSoundUtility

final class LifecycleDecisionEngineTests: XCTestCase {
    func testWillSleepMapsToExitSound() {
        let engine = LifecycleDecisionEngine()

        let event = engine.handle(.willSleep, now: Date())

        XCTAssertEqual(event, .exit)
    }

    func testDisabledStatePreventsPlayback() {
        let engine = LifecycleDecisionEngine()
        engine.setEnabled(false)

        let event = engine.handle(.didWake, now: Date())

        XCTAssertNil(event)
    }

    func testDebouncePreventsDuplicateWakePlayback() {
        let engine = LifecycleDecisionEngine()
        let now = Date()

        let first = engine.handle(.didWake, now: now)
        let second = engine.handle(.didWake, now: now.addingTimeInterval(0.5))

        XCTAssertEqual(first, .open)
        XCTAssertNil(second)
    }

    func testClamshellOpenIsSuppressedImmediatelyAfterWake() {
        let engine = LifecycleDecisionEngine()
        let now = Date()

        _ = engine.handle(.didWake, now: now)
        let clamshell = engine.handle(.clamshellOpened, now: now.addingTimeInterval(1))

        XCTAssertNil(clamshell)
    }

    func testClamshellOpenCanPlayAfterWakeWindowExpires() {
        let engine = LifecycleDecisionEngine()
        let now = Date()

        _ = engine.handle(.didWake, now: now)
        let clamshell = engine.handle(.clamshellOpened, now: now.addingTimeInterval(5))

        XCTAssertEqual(clamshell, .open)
    }
}
