import Foundation
import OSLog

enum SoundEvent: String {
    case exit
    case open
    case message
}

enum NotificationOverrideCapability: Equatable {
    case supported
    case appSpecificSetupRequired
    case unsupported
}

enum LifecycleSignal: Equatable {
    case willSleep
    case didWake
    case lidAngleReachedCloseThreshold
    case clamshellOpened
    case clamshellClosed
    case sessionDidBecomeActive
    case sessionDidResignActive
}

final class LifecycleDecisionEngine {
    private enum Constants {
        static let eventDebounce: TimeInterval = 1.5
        static let wakeFollowupWindow: TimeInterval = 15
    }

    private let logger = AppLog.logger("lifecycle.decision")

    private var enabled = true
    private var lastPlayedAt: [SoundEvent: Date] = [:]
    private var lastWakeAt: Date?
    private var sessionActive = true
    private var pendingWakeOpen = false
    private var screenLockSoundsEnabled = true
    private var laptopCloseSoundEnabled = true
    private var laptopOpenSoundEnabled = true

    func setEnabled(_ enabled: Bool) {
        self.enabled = enabled
        log("Playback enabled set to \(enabled)")
    }

    func setSessionActive(_ sessionActive: Bool) {
        self.sessionActive = sessionActive
        log("Session active set to \(sessionActive)")
    }

    func setScreenLockSoundsEnabled(_ enabled: Bool) {
        screenLockSoundsEnabled = enabled
        log("Screen lock playback enabled set to \(enabled)")
    }

    func setLaptopCloseSoundEnabled(_ enabled: Bool) {
        laptopCloseSoundEnabled = enabled
        log("Laptop close playback enabled set to \(enabled)")
    }

    func setLaptopOpenSoundEnabled(_ enabled: Bool) {
        laptopOpenSoundEnabled = enabled
        log("Laptop open playback enabled set to \(enabled)")
    }

    func handle(_ signal: LifecycleSignal, now: Date) -> SoundEvent? {
        guard enabled else {
            log("Ignoring signal \(String(describing: signal)) because playback is disabled")
            return nil
        }

        log(
            """
            Handling signal \(String(describing: signal)) \
            sessionActive=\(self.sessionActive) \
            pendingWakeOpen=\(self.pendingWakeOpen)
            """
        )

        switch signal {
        case .willSleep:
            pendingWakeOpen = false
            return emit(.exit, now: now)
        case .didWake:
            lastWakeAt = now
            pendingWakeOpen = !sessionActive
            if pendingWakeOpen {
                return nil
            }

            return emit(.open, now: now)
        case .lidAngleReachedCloseThreshold:
            guard laptopCloseSoundEnabled else {
                log("Ignoring lid close because laptop close playback is disabled")
                pendingWakeOpen = false
                return nil
            }
            pendingWakeOpen = false
            return emit(.exit, now: now)
        case .clamshellOpened:
            guard laptopOpenSoundEnabled else {
                log("Ignoring clamshell open because laptop open playback is disabled")
                return nil
            }
            if let lastWakeAt, now.timeIntervalSince(lastWakeAt) < Constants.wakeFollowupWindow {
                log("Ignoring clamshellOpened because a wake was observed recently")
                return nil
            }

            pendingWakeOpen = false
            lastWakeAt = now
            return emit(.open, now: now)
        case .clamshellClosed:
            guard laptopCloseSoundEnabled else {
                log("Ignoring clamshell close because laptop close playback is disabled")
                pendingWakeOpen = false
                return nil
            }
            pendingWakeOpen = false
            return emit(.exit, now: now)
        case .sessionDidBecomeActive:
            sessionActive = true
            pendingWakeOpen = false
            guard screenLockSoundsEnabled else {
                log("Ignoring session activation because screen lock playback is disabled")
                return nil
            }
            return emit(.open, now: now)
        case .sessionDidResignActive:
            sessionActive = false
            pendingWakeOpen = false
            guard screenLockSoundsEnabled else {
                log("Ignoring session resign because screen lock playback is disabled")
                return nil
            }
            log("Session resigned active; emitting exit for plain lock or logout")
            return emit(.exit, now: now)
        }
    }

    private func emit(_ event: SoundEvent, now: Date) -> SoundEvent? {
        if let lastPlayedAt = lastPlayedAt[event], now.timeIntervalSince(lastPlayedAt) < Constants.eventDebounce {
            log("Debouncing \(event.rawValue) playback")
            return nil
        }

        self.lastPlayedAt[event] = now
        log("Emitting \(event.rawValue) playback")
        return event
    }
}

private extension LifecycleDecisionEngine {
    func log(_ message: String) {
        logger.notice("\(message, privacy: .public)")
    }
}
