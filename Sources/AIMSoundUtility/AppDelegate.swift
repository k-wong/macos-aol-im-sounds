import AppKit
import OSLog

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let appState = AppState()
    private let soundPlayer = SoundPlayer()
    private let decisionEngine = LifecycleDecisionEngine()
    private let logger = Logger(subsystem: "com.kev.mac-aim", category: "app")

    private var lifecycleMonitor: LifecycleMonitor?
    private var statusItemController: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        log("Application finished launching")

        decisionEngine.setEnabled(appState.enabled)

        lifecycleMonitor = LifecycleMonitor { [weak self] signal in
            self?.handle(signal)
        }
        if let lifecycleMonitor {
            decisionEngine.setSessionActive(lifecycleMonitor.isSessionActive)
            log("Initial session active state is \(lifecycleMonitor.isSessionActive)")
        }
        lifecycleMonitor?.start()

        statusItemController = StatusItemController(
            appState: appState,
            onToggle: { [weak self] in self?.toggleEnabled() }
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        lifecycleMonitor?.stop()
    }

    private func toggleEnabled() {
        appState.enabled.toggle()
        decisionEngine.setEnabled(appState.enabled)
    }

    private func handle(_ signal: LifecycleSignal) {
        log("App delegate received signal \(String(describing: signal))")
        guard let event = decisionEngine.handle(signal, now: Date()) else {
            log("Signal \(String(describing: signal)) produced no sound event")
            return
        }

        log("Playing sound event \(event.rawValue)")
        soundPlayer.play(event)
    }

    private func log(_ message: String) {
        logger.notice("\(message, privacy: .public)")
        NSLog("%@", message)
    }
}
