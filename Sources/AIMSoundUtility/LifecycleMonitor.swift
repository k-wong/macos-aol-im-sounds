import AppKit
import CoreGraphics
import Foundation
import OSLog

protocol ScreenLockNotificationObserving: AnyObject {
    func addLockObserver(using block: @escaping @Sendable (Notification) -> Void) -> NSObjectProtocol
    func addUnlockObserver(using block: @escaping @Sendable (Notification) -> Void) -> NSObjectProtocol
    func removeObserver(_ observer: NSObjectProtocol)
}

final class DistributedScreenLockNotificationCenter: ScreenLockNotificationObserving {
    private enum Constants {
        static let screenLockedNotification = Notification.Name("com.apple.screenIsLocked")
        static let screenUnlockedNotification = Notification.Name("com.apple.screenIsUnlocked")
    }

    private let center: DistributedNotificationCenter

    init(center: DistributedNotificationCenter = .default()) {
        self.center = center
    }

    func addLockObserver(using block: @escaping @Sendable (Notification) -> Void) -> NSObjectProtocol {
        center.addObserver(
            forName: Constants.screenLockedNotification,
            object: nil,
            queue: .main,
            using: block
        )
    }

    func addUnlockObserver(using block: @escaping @Sendable (Notification) -> Void) -> NSObjectProtocol {
        center.addObserver(
            forName: Constants.screenUnlockedNotification,
            object: nil,
            queue: .main,
            using: block
        )
    }

    func removeObserver(_ observer: NSObjectProtocol) {
        center.removeObserver(observer)
    }
}

@MainActor
final class LifecycleMonitor {
    private enum Constants {
        static let suppressedModelName = "M1 MacBook Air"
    }

    private let onSignal: (LifecycleSignal) -> Void
    private let notificationCenter: NotificationCenter
    private let screenLockNotificationCenter: ScreenLockNotificationObserving
    private let lidAngleMonitor: LidAngleMonitor
    private let clamshellMonitor: ClamshellMonitor
    private let workspace: NSWorkspace
    private let suppressCloseSoundsOnLaptopClose: Bool
    private let logger = Logger(subsystem: "com.kev.mac-aim", category: "lifecycle.monitor")

    private var observers: [NSObjectProtocol] = []
    private var screenLockObservers: [NSObjectProtocol] = []

    init(
        workspace: NSWorkspace = .shared,
        notificationCenter: NotificationCenter = NSWorkspace.shared.notificationCenter,
        screenLockNotificationCenter: ScreenLockNotificationObserving = DistributedScreenLockNotificationCenter(),
        lidAngleMonitor: LidAngleMonitor = LidAngleMonitor(),
        clamshellMonitor: ClamshellMonitor = ClamshellMonitor(),
        suppressCloseSoundsOnLaptopClose: Bool = HardwareProfile.current.isM1MacBookAir,
        onSignal: @escaping (LifecycleSignal) -> Void
    ) {
        self.workspace = workspace
        self.notificationCenter = notificationCenter
        self.screenLockNotificationCenter = screenLockNotificationCenter
        self.lidAngleMonitor = lidAngleMonitor
        self.clamshellMonitor = clamshellMonitor
        self.suppressCloseSoundsOnLaptopClose = suppressCloseSoundsOnLaptopClose
        self.onSignal = onSignal
    }

    func start() {
        log("Starting lifecycle monitor")
        if suppressCloseSoundsOnLaptopClose {
            log("Suppressing lid-close sounds for \(Constants.suppressedModelName)")
        }

        observers.append(
            notificationCenter.addObserver(
                forName: NSWorkspace.willSleepNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.log("Received NSWorkspace.willSleepNotification")
                    guard let self else {
                        return
                    }
                    if self.shouldSuppressWillSleepForLaptopClose() {
                        self.log("Suppressing willSleep because lid close was detected on \(Constants.suppressedModelName)")
                        return
                    }
                    self.onSignal(.willSleep)
                }
            }
        )

        observers.append(
            notificationCenter.addObserver(
                forName: NSWorkspace.didWakeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.log("Received NSWorkspace.didWakeNotification")
                    self?.onSignal(.didWake)
                }
            }
        )

        observers.append(
            notificationCenter.addObserver(
                forName: NSWorkspace.sessionDidBecomeActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.log("Received NSWorkspace.sessionDidBecomeActiveNotification")
                    self?.onSignal(.sessionDidBecomeActive)
                }
            }
        )

        observers.append(
            notificationCenter.addObserver(
                forName: NSWorkspace.sessionDidResignActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.log("Received NSWorkspace.sessionDidResignActiveNotification")
                    self?.onSignal(.sessionDidResignActive)
                }
            }
        )

        screenLockObservers.append(
            screenLockNotificationCenter.addLockObserver { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.log("Received screen lock notification")
                    self?.onSignal(.sessionDidResignActive)
                }
            }
        )

        screenLockObservers.append(
            screenLockNotificationCenter.addUnlockObserver { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.log("Received screen unlock notification")
                    self?.onSignal(.sessionDidBecomeActive)
                }
            }
        )

        lidAngleMonitor.onCloseThresholdReached = { [weak self] in
            guard let self else {
                return
            }
            self.log("Lid angle crossed close threshold")
            if self.shouldSuppressCloseSignals() {
                self.log("Suppressing lid-angle close trigger on \(Constants.suppressedModelName)")
                return
            }
            self.onSignal(.lidAngleReachedCloseThreshold)
        }
        lidAngleMonitor.start()

        clamshellMonitor.onChange = { [weak self] isClosed in
            guard let self else {
                return
            }
            self.log("Clamshell state changed isClosed=\(isClosed)")
            if isClosed && self.shouldSuppressCloseSignals() {
                self.log("Suppressing clamshell-close trigger on \(Constants.suppressedModelName)")
                return
            }
            self.onSignal(isClosed ? .clamshellClosed : .clamshellOpened)
        }
        clamshellMonitor.start()
    }

    func stop() {
        log("Stopping lifecycle monitor")
        observers.forEach(notificationCenter.removeObserver(_:))
        observers.removeAll()
        screenLockObservers.forEach(screenLockNotificationCenter.removeObserver(_:))
        screenLockObservers.removeAll()
        lidAngleMonitor.stop()
        clamshellMonitor.stop()
    }

    var isSessionActive: Bool {
        Self.readCurrentSessionActive()
    }

    private static func readCurrentSessionActive() -> Bool {
        guard let session = CGSessionCopyCurrentDictionary() as? [String: Any] else {
            return true
        }

        if let loginDone = session[kCGSessionLoginDoneKey as String] as? Bool {
            return loginDone
        }

        return true
    }

    private func log(_ message: String) {
        logger.notice("\(message, privacy: .public)")
        NSLog("%@", message)
    }

    private func shouldSuppressCloseSignals() -> Bool {
        suppressCloseSoundsOnLaptopClose
    }

    private func shouldSuppressWillSleepForLaptopClose() -> Bool {
        guard suppressCloseSoundsOnLaptopClose else {
            return false
        }

        return lidAngleMonitor.isCurrentlyNearClosed() || clamshellMonitor.currentState() == true
    }
}
