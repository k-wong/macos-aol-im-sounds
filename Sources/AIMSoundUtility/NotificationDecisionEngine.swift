import Foundation
import OSLog

final class NotificationDecisionEngine {
    private enum Constants {
        static let dedupeWindow: TimeInterval = 4
    }

    private let logger = AppLog.logger("notification.decision")
    private var enabled = true
    private var lastPlayedAtByDedupeKey: [String: Date] = [:]

    func setEnabled(_ enabled: Bool) {
        self.enabled = enabled
        log("Notification playback enabled set to \(enabled)")
    }

    func handle(_ event: NotificationEvent, now: Date) -> SoundEvent? {
        guard enabled else {
            log("Ignoring notification event because playback is disabled")
            return nil
        }

        evictStaleKeys(now: now)

        if let lastPlayedAt = lastPlayedAtByDedupeKey[event.dedupeKey],
           now.timeIntervalSince(lastPlayedAt) < Constants.dedupeWindow {
            log("Debouncing duplicate notification event \(event.dedupeKey)")
            return nil
        }

        lastPlayedAtByDedupeKey[event.dedupeKey] = now
        log("Emitting message playback for notification event \(event.dedupeKey)")
        return .message
    }

    private func evictStaleKeys(now: Date) {
        lastPlayedAtByDedupeKey = lastPlayedAtByDedupeKey.filter { now.timeIntervalSince($0.value) < Constants.dedupeWindow }
    }
}

private extension NotificationDecisionEngine {
    func log(_ message: String) {
        logger.notice("\(message, privacy: .public)")
    }
}
