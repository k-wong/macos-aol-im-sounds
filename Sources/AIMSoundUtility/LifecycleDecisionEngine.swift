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

    private let logger = Logger(subsystem: "com.kev.mac-aim", category: "lifecycle.decision")

    private var enabled = true
    private var lastPlayedAt: [SoundEvent: Date] = [:]
    private var lastWakeAt: Date?
    private var sessionActive = true
    private var pendingWakeOpen = false

    func setEnabled(_ enabled: Bool) {
        self.enabled = enabled
        log("Playback enabled set to \(enabled)")
    }

    func setSessionActive(_ sessionActive: Bool) {
        self.sessionActive = sessionActive
        log("Session active set to \(sessionActive)")
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
            pendingWakeOpen = false
            return emit(.exit, now: now)
        case .clamshellOpened:
            if let lastWakeAt, now.timeIntervalSince(lastWakeAt) < Constants.wakeFollowupWindow {
                log("Ignoring clamshellOpened because a wake was observed recently")
                return nil
            }

            pendingWakeOpen = false
            lastWakeAt = now
            return emit(.open, now: now)
        case .clamshellClosed:
            pendingWakeOpen = false
            return emit(.exit, now: now)
        case .sessionDidBecomeActive:
            sessionActive = true
            pendingWakeOpen = false
            return emit(.open, now: now)
        case .sessionDidResignActive:
            sessionActive = false
            pendingWakeOpen = false
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

    private func log(_ message: String) {
        logger.notice("\(message, privacy: .public)")
        NSLog("%@", message)
    }
}
