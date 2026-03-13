import AppKit
import OSLog

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let appState = AppState()
    private let soundPlayer = SoundPlayer()
    private let decisionEngine = LifecycleDecisionEngine()
    private let notificationDecisionEngine = NotificationDecisionEngine()
    private let notificationRuleEngine = NotificationRuleEngine()
    private let accessibilityPermissionCoordinator = AccessibilityPermissionCoordinator()
    private let logger = Logger(subsystem: "com.kev.mac-aim", category: "app")

    private var lifecycleMonitor: LifecycleMonitor?
    private var notificationMonitor: NotificationMonitor?
    private var statusItemController: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        log("Application finished launching")

        decisionEngine.setEnabled(appState.enabled)
        notificationDecisionEngine.setEnabled(appState.enabled)
        decisionEngine.setLaptopCloseSoundEnabled(appState.laptopCloseSoundEnabled)
        decisionEngine.setLaptopOpenSoundEnabled(appState.laptopOpenSoundEnabled)

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

        statusItemController = StatusItemController(
            appState: appState,
            onToggle: { [weak self] in self?.toggleEnabled() },
            onOpenAccessibilitySettings: { [weak self] in
                self?.openAccessibilitySettings()
            },
            onToggleLaptopCloseSound: { [weak self] in
                self?.toggleLaptopCloseSound()
            },
            onToggleLaptopOpenSound: { [weak self] in
                self?.toggleLaptopOpenSound()
            },
            onMenuWillOpen: { [weak self] in
                self?.syncAccessibilityState(requestPromptIfNeeded: false)
            }
        )
        syncAccessibilityState(requestPromptIfNeeded: true)
    }

    func applicationWillTerminate(_ notification: Notification) {
        lifecycleMonitor?.stop()
        notificationMonitor?.stop()
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        syncAccessibilityState(requestPromptIfNeeded: false)
    }

    private func toggleEnabled() {
        appState.enabled.toggle()
        decisionEngine.setEnabled(appState.enabled)
        notificationDecisionEngine.setEnabled(appState.enabled)
    }

    private func toggleLaptopCloseSound() {
        appState.laptopCloseSoundEnabled.toggle()
        decisionEngine.setLaptopCloseSoundEnabled(appState.laptopCloseSoundEnabled)
    }

    private func toggleLaptopOpenSound() {
        appState.laptopOpenSoundEnabled.toggle()
        decisionEngine.setLaptopOpenSoundEnabled(appState.laptopOpenSoundEnabled)
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

    private func syncAccessibilityState(requestPromptIfNeeded: Bool) {
        if requestPromptIfNeeded {
            accessibilityPermissionCoordinator.requestAccessIfNeeded()
        }

        let isTrusted = accessibilityPermissionCoordinator.isTrusted
        statusItemController?.setAccessibilityTrusted(isTrusted)

        if isTrusted {
            notificationMonitor?.start()
        } else {
            notificationMonitor?.stop()
            log("Accessibility permission is not granted; notification monitor will remain idle")
        }
    }

    private func openAccessibilitySettings() {
        accessibilityPermissionCoordinator.promptAndOpenSettings()
        syncAccessibilityState(requestPromptIfNeeded: false)
    }

    private func log(_ message: String) {
        logger.notice("\(message, privacy: .public)")
        NSLog("%@", message)
    }
}
