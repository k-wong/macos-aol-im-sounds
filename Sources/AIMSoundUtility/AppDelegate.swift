import AppKit
import OSLog

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let appState = AppState()
    private let soundPlayer = SoundPlayer()
    private let decisionEngine = LifecycleDecisionEngine()
    private let notificationDecisionEngine = NotificationDecisionEngine()
    private let notificationRuleEngine = NotificationRuleEngine()
    private let logger = Logger(subsystem: "com.kev.mac-aim", category: "app")

    private var lifecycleMonitor: LifecycleMonitor?
    private var notificationMonitor: NotificationMonitor?
    private var statusItemController: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        log("Application finished launching")

        decisionEngine.setEnabled(appState.enabled)
        notificationDecisionEngine.setEnabled(appState.enabled)

        lifecycleMonitor = LifecycleMonitor { [weak self] signal in
            self?.handle(signal)
        }
        if let lifecycleMonitor {
            decisionEngine.setSessionActive(lifecycleMonitor.isSessionActive)
            log("Initial session active state is \(lifecycleMonitor.isSessionActive)")
        }
        lifecycleMonitor?.start()

        notificationMonitor = NotificationMonitor(ruleEngine: notificationRuleEngine) { [weak self] event in
            self?.handleNotification(event)
        }
        notificationMonitor?.start()

        statusItemController = StatusItemController(
            appState: appState,
            onToggle: { [weak self] in self?.toggleEnabled() }
        )
        statusItemController?.setAccessibilityTrusted(notificationMonitor?.isAccessibilityTrusted ?? false)
    }

    func applicationWillTerminate(_ notification: Notification) {
        lifecycleMonitor?.stop()
        notificationMonitor?.stop()
    }

    private func toggleEnabled() {
        appState.enabled.toggle()
        decisionEngine.setEnabled(appState.enabled)
        notificationDecisionEngine.setEnabled(appState.enabled)
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

    private func handleNotification(_ event: NotificationEvent) {
        log("App delegate received notification event \(event.dedupeKey)")
        guard let soundEvent = notificationDecisionEngine.handle(event, now: Date()) else {
            log("Notification event \(event.dedupeKey) produced no sound event")
            return
        }

        log("Playing sound event \(soundEvent.rawValue)")
        soundPlayer.play(soundEvent)
    }

    private func log(_ message: String) {
        logger.notice("\(message, privacy: .public)")
        NSLog("%@", message)
    }
}
