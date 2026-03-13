import AppKit
import Combine

@MainActor
final class StatusItemController: NSObject, NSMenuDelegate {
    enum AccessibilityMenuState: Equatable {
        case allowed
        case needsAccess

        var title: String {
            switch self {
            case .allowed:
                return "Accessibility access: Allowed"
            case .needsAccess:
                return "Grant Accessibility Access..."
            }
        }

        var isActionable: Bool {
            switch self {
            case .allowed:
                return false
            case .needsAccess:
                return true
            }
        }
    }

    private let statusItem: NSStatusItem
    private let appState: AppState
    private let onToggle: () -> Void
    private let onOpenAccessibilitySettings: () -> Void
    private let onMenuWillOpen: () -> Void
    private let bundle: Bundle
    private let menu = NSMenu()
    private var stateCancellable: AnyCancellable?
    private var accessibilityMenuState: AccessibilityMenuState = .needsAccess

    private lazy var statusLabelItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private lazy var supportItem = makeInfoItem()
    private lazy var guidanceHeaderItem = makeInfoItem()
    private lazy var guidancePathItem = makeInfoItem()
    private lazy var guidanceToggleItem = makeInfoItem()
    private lazy var accessibilityHelpItem = makeInfoItem()
    private lazy var accessibilityItem = NSMenuItem(
        title: "",
        action: #selector(openAccessibilitySettings),
        keyEquivalent: ""
    )
    private lazy var quitItem = NSMenuItem(
        title: "Quit",
        action: #selector(quitSelected),
        keyEquivalent: "q"
    )

    init(
        appState: AppState,
        bundle: Bundle = .module,
        onToggle: @escaping () -> Void,
        onOpenAccessibilitySettings: @escaping () -> Void,
        onMenuWillOpen: @escaping () -> Void = {}
    ) {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.appState = appState
        self.bundle = bundle
        self.onToggle = onToggle
        self.onOpenAccessibilitySettings = onOpenAccessibilitySettings
        self.onMenuWillOpen = onMenuWillOpen
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
        menu.delegate = self
        quitItem.target = self
        statusLabelItem.isEnabled = false
        accessibilityItem.target = self

        menu.addItem(statusLabelItem)
        menu.addItem(.separator())
        menu.addItem(supportItem)
        menu.addItem(guidanceHeaderItem)
        menu.addItem(guidancePathItem)
        menu.addItem(guidanceToggleItem)
        menu.addItem(accessibilityHelpItem)
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
        accessibilityHelpItem.title = "Notification banner detection needs Accessibility access"
        accessibilityItem.title = accessibilityMenuState.title
        accessibilityItem.isEnabled = accessibilityMenuState.isActionable

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
        accessibilityMenuState = trusted ? .allowed : .needsAccess
        refreshUI(enabled: appState.enabled)
    }

    func menuWillOpen(_ menu: NSMenu) {
        onMenuWillOpen()
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

    @objc private func openAccessibilitySettings() {
        onOpenAccessibilitySettings()
    }
}
