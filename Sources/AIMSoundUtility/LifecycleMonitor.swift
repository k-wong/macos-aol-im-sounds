import AppKit
import Foundation

@MainActor
final class LifecycleMonitor {
    private let onSignal: (LifecycleSignal) -> Void
    private let notificationCenter: NotificationCenter
    private let clamshellMonitor: ClamshellMonitor

    private var observers: [NSObjectProtocol] = []

    init(
        notificationCenter: NotificationCenter = NSWorkspace.shared.notificationCenter,
        clamshellMonitor: ClamshellMonitor = ClamshellMonitor(),
        onSignal: @escaping (LifecycleSignal) -> Void
    ) {
        self.notificationCenter = notificationCenter
        self.clamshellMonitor = clamshellMonitor
        self.onSignal = onSignal
    }

    func start() {
        observers.append(
            notificationCenter.addObserver(
                forName: NSWorkspace.willSleepNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.onSignal(.willSleep)
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
                    self?.onSignal(.didWake)
                }
            }
        )

        clamshellMonitor.onChange = { [weak self] isClosed in
            self?.onSignal(isClosed ? .clamshellClosed : .clamshellOpened)
        }
        clamshellMonitor.start()
    }

    func stop() {
        observers.forEach(notificationCenter.removeObserver(_:))
        observers.removeAll()
        clamshellMonitor.stop()
    }
}
