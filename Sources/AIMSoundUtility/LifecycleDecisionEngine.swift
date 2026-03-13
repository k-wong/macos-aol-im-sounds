import Foundation

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
    case clamshellOpened
    case clamshellClosed
}

final class LifecycleDecisionEngine {
    private enum Constants {
        static let eventDebounce: TimeInterval = 1.5
        static let clamshellWakeSuppression: TimeInterval = 4
    }

    private var enabled = true
    private var lastPlayedAt: [SoundEvent: Date] = [:]
    private var lastWakeAt: Date?

    func setEnabled(_ enabled: Bool) {
        self.enabled = enabled
    }

    func handle(_ signal: LifecycleSignal, now: Date) -> SoundEvent? {
        guard enabled else {
            return nil
        }

        switch signal {
        case .willSleep:
            return emit(.exit, now: now)
        case .didWake:
            lastWakeAt = now
            return emit(.open, now: now)
        case .clamshellOpened:
            if let lastWakeAt, now.timeIntervalSince(lastWakeAt) < Constants.clamshellWakeSuppression {
                return nil
            }

            return emit(.open, now: now)
        case .clamshellClosed:
            return nil
        }
    }

    private func emit(_ event: SoundEvent, now: Date) -> SoundEvent? {
        if let lastPlayedAt = lastPlayedAt[event], now.timeIntervalSince(lastPlayedAt) < Constants.eventDebounce {
            return nil
        }

        self.lastPlayedAt[event] = now
        return event
    }
}
