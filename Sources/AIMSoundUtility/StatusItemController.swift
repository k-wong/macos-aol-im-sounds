import AppKit
import Combine

@MainActor
final class StatusItemController: NSObject {
    private let statusItem: NSStatusItem
    private let appState: AppState
    private let onToggle: () -> Void
    private let bundle: Bundle
    private let menu = NSMenu()
    private var stateCancellable: AnyCancellable?

    private lazy var statusLabelItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private lazy var quitItem = NSMenuItem(
        title: "Quit",
        action: #selector(quitSelected),
        keyEquivalent: "q"
    )

    init(appState: AppState, bundle: Bundle = .module, onToggle: @escaping () -> Void) {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.appState = appState
        self.bundle = bundle
        self.onToggle = onToggle
        super.init()

        configureButton()
        configureMenu()
        bindState()
        refreshUI(enabled: appState.enabled)
    }

    private func configureButton() {
        guard let button = statusItem.button else {
            return
        }

        button.target = self
        button.action = #selector(handleClick(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.toolTip = "Toggle AIM sounds"
    }

    private func configureMenu() {
        quitItem.target = self
        statusLabelItem.isEnabled = false

        menu.addItem(statusLabelItem)
        menu.addItem(.separator())
        menu.addItem(quitItem)
    }

    private func bindState() {
        stateCancellable = appState.$enabled
            .receive(on: RunLoop.main)
            .sink { [weak self] enabled in
                self?.refreshUI(enabled: enabled)
            }
    }

    private func refreshUI(enabled: Bool) {
        statusLabelItem.title = enabled ? "AIM sounds are On" : "AIM sounds are Off"

        guard let button = statusItem.button else {
            return
        }

        let imageName = enabled ? "aim-app-icon-on" : "aim-app-icon-off"
        let image = loadMenuBarImage(named: imageName) ?? fallbackImage(enabled: enabled)
        image?.isTemplate = true
        button.image = image
        button.imageScaling = .scaleProportionallyDown
    }

    private func loadMenuBarImage(named name: String) -> NSImage? {
        guard let url = bundle.url(forResource: name, withExtension: "svg") else {
            return nil
        }

        let image = NSImage(contentsOf: url)
        image?.accessibilityDescription = statusLabelItem.title
        return image
    }

    private func fallbackImage(enabled: Bool) -> NSImage? {
        let symbolName = enabled ? "speaker.wave.2.fill" : "speaker.slash.fill"
        return NSImage(
            systemSymbolName: symbolName,
            accessibilityDescription: statusLabelItem.title
        )
    }

    @objc private func handleClick(_ sender: AnyObject?) {
        guard let event = NSApp.currentEvent else {
            onToggle()
            return
        }

        switch event.type {
        case .rightMouseUp:
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        default:
            onToggle()
        }
    }

    @objc private func quitSelected() {
        NSApp.terminate(nil)
    }
}
