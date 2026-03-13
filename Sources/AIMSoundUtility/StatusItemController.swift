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
    private var accessibilityTrusted = false

    private lazy var statusLabelItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private lazy var supportItem = makeInfoItem()
    private lazy var guidanceHeaderItem = makeInfoItem()
    private lazy var guidancePathItem = makeInfoItem()
    private lazy var guidanceToggleItem = makeInfoItem()
    private lazy var accessibilityItem = makeInfoItem()
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
        menu.addItem(supportItem)
        menu.addItem(guidanceHeaderItem)
        menu.addItem(guidancePathItem)
        menu.addItem(guidanceToggleItem)
        menu.addItem(accessibilityItem)
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
        supportItem.title = "Notification banners: Slack + macOS apps"
        guidanceHeaderItem.title = "For AIM-only alerts:"
        guidancePathItem.title = "System Settings > Notifications"
        guidanceToggleItem.title = "Turn off \"Play sound for notification\""
        accessibilityItem.title = accessibilityTrusted ? "Accessibility access: Allowed" : "Accessibility access: Needed"

        guard let button = statusItem.button else {
            return
        }

        let imageName = enabled ? "aim-app-icon-on" : "aim-app-icon-off"
        let image = loadMenuBarImage(named: imageName) ?? fallbackImage(enabled: enabled)
        image?.isTemplate = true
        button.image = image
        button.imageScaling = .scaleProportionallyDown
        button.toolTip = """
        Toggle AIM sounds
        For AIM-only alerts, turn off "Play sound for notification" in System Settings > Notifications.
        """
    }

    func setAccessibilityTrusted(_ trusted: Bool) {
        accessibilityTrusted = trusted
        refreshUI(enabled: appState.enabled)
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

    private func makeInfoItem() -> NSMenuItem {
        let item = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
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
