import AppKit
import Combine

@MainActor
final class StatusItemController: NSObject, NSMenuDelegate {
    enum NotificationSoundsMenuState: Equatable {
        case enabled
        case clickToEnable

        var title: String {
            switch self {
            case .enabled:
                return "Notification sounds: Enabled"
            case .clickToEnable:
                return "Notification sounds: Click to enable"
            }
        }

        var isActionable: Bool {
            switch self {
            case .enabled:
                return false
            case .clickToEnable:
                return true
            }
        }
    }

    private let statusItem: NSStatusItem
    private let appState: AppState
    private let onToggle: () -> Void
    private let onOpenAccessibilitySettings: () -> Void
    private let onToggleLaptopCloseSound: () -> Void
    private let onToggleLaptopOpenSound: () -> Void
    private let onMenuWillOpen: () -> Void
    private let bundle: Bundle
    private let menu = NSMenu()
    private var stateCancellable: AnyCancellable?
    private var notificationSoundsMenuState: NotificationSoundsMenuState = .clickToEnable

    private lazy var accessibilityHelpItem = makeInfoItem()
    private lazy var notificationSoundsItem = NSMenuItem(
        title: "",
        action: #selector(openAccessibilitySettings),
        keyEquivalent: ""
    )
    private lazy var laptopCloseSoundItem = NSMenuItem(
        title: "",
        action: #selector(toggleLaptopCloseSound),
        keyEquivalent: ""
    )
    private lazy var laptopOpenSoundItem = NSMenuItem(
        title: "",
        action: #selector(toggleLaptopOpenSound),
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
        onToggleLaptopCloseSound: @escaping () -> Void,
        onToggleLaptopOpenSound: @escaping () -> Void,
        onMenuWillOpen: @escaping () -> Void = {}
    ) {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.appState = appState
        self.bundle = bundle
        self.onToggle = onToggle
        self.onOpenAccessibilitySettings = onOpenAccessibilitySettings
        self.onToggleLaptopCloseSound = onToggleLaptopCloseSound
        self.onToggleLaptopOpenSound = onToggleLaptopOpenSound
        self.onMenuWillOpen = onMenuWillOpen
        super.init()

        configureButton()
        configureMenu()
        bindState()
        refreshUI(
            enabled: appState.enabled,
            laptopCloseSoundEnabled: appState.laptopCloseSoundEnabled,
            laptopOpenSoundEnabled: appState.laptopOpenSoundEnabled
        )
    }

    private func configureButton() {
        guard let button = statusItem.button else {
            return
        }

        button.target = self
        button.action = #selector(handleClick(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.toolTip = appState.enabled ? "Running" : "Off"
    }

    private func configureMenu() {
        menu.delegate = self
        quitItem.target = self
        notificationSoundsItem.target = self
        laptopCloseSoundItem.target = self
        laptopOpenSoundItem.target = self

        menu.addItem(accessibilityHelpItem)
        menu.addItem(notificationSoundsItem)
        menu.addItem(laptopCloseSoundItem)
        menu.addItem(laptopOpenSoundItem)
        menu.addItem(.separator())
        menu.addItem(quitItem)
    }

    private func bindState() {
        stateCancellable = Publishers.CombineLatest3(
            appState.$enabled,
            appState.$laptopCloseSoundEnabled,
            appState.$laptopOpenSoundEnabled
        )
            .receive(on: RunLoop.main)
            .sink { [weak self] enabled, laptopCloseSoundEnabled, laptopOpenSoundEnabled in
                self?.refreshUI(
                    enabled: enabled,
                    laptopCloseSoundEnabled: laptopCloseSoundEnabled,
                    laptopOpenSoundEnabled: laptopOpenSoundEnabled
                )
            }
    }

    private func refreshUI(
        enabled: Bool,
        laptopCloseSoundEnabled: Bool,
        laptopOpenSoundEnabled: Bool
    ) {
        accessibilityHelpItem.title = "Notification banner detection needs Accessibility access"
        accessibilityHelpItem.isHidden = notificationSoundsMenuState == .enabled
        notificationSoundsItem.title = notificationSoundsMenuState.title
        notificationSoundsItem.isEnabled = notificationSoundsMenuState.isActionable
        laptopCloseSoundItem.title = laptopCloseSoundEnabled
            ? "Laptop close sound: Enabled"
            : "Laptop close sound: Click to enable"
        laptopOpenSoundItem.title = laptopOpenSoundEnabled
            ? "Laptop open sound: Enabled"
            : "Laptop open sound: Click to enable"

        guard let button = statusItem.button else {
            return
        }

        let imageName = enabled ? "aim-app-icon-on" : "aim-app-icon-off"
        let image = loadMenuBarImage(named: imageName) ?? fallbackImage(enabled: enabled)
        image?.isTemplate = true
        button.image = image
        button.imageScaling = .scaleProportionallyDown
        button.toolTip = enabled ? "Running" : "Off"
    }

    func setAccessibilityTrusted(_ trusted: Bool) {
        notificationSoundsMenuState = trusted ? .enabled : .clickToEnable
        refreshUI(
            enabled: appState.enabled,
            laptopCloseSoundEnabled: appState.laptopCloseSoundEnabled,
            laptopOpenSoundEnabled: appState.laptopOpenSoundEnabled
        )
    }

    func menuWillOpen(_ menu: NSMenu) {
        onMenuWillOpen()
    }

    private func loadMenuBarImage(named name: String) -> NSImage? {
        guard let url = bundle.url(forResource: name, withExtension: "svg") else {
            return nil
        }

        let image = NSImage(contentsOf: url)
        image?.accessibilityDescription = enabledAccessibilityDescription()
        return image
    }

    private func fallbackImage(enabled: Bool) -> NSImage? {
        let symbolName = enabled ? "speaker.wave.2.fill" : "speaker.slash.fill"
        return NSImage(
            systemSymbolName: symbolName,
            accessibilityDescription: enabledAccessibilityDescription()
        )
    }

    private func enabledAccessibilityDescription() -> String {
        appState.enabled ? "AIM sounds are On" : "AIM sounds are Off"
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

    @objc private func toggleLaptopCloseSound() {
        onToggleLaptopCloseSound()
    }

    @objc private func toggleLaptopOpenSound() {
        onToggleLaptopOpenSound()
    }
}
