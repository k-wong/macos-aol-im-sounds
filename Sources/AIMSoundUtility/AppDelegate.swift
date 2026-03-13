import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let appState = AppState()
    private let soundPlayer = SoundPlayer()
    private let decisionEngine = LifecycleDecisionEngine()

    private var lifecycleMonitor: LifecycleMonitor?
    private var statusItemController: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        decisionEngine.setEnabled(appState.enabled)

        lifecycleMonitor = LifecycleMonitor { [weak self] signal in
            self?.handle(signal)
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
        guard let event = decisionEngine.handle(signal, now: Date()) else {
            return
        }

        soundPlayer.play(event)
    }
}
