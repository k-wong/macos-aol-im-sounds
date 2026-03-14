import AppKit
import Combine

@MainActor
final class StatusItemController: NSObject, NSMenuDelegate {
    enum NotificationSoundsStatus: Equatable {
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

    }

    private let statusItem: NSStatusItem
    private let appState: AppState
    private let onToggle: () -> Void
    private let onToggleNotificationSounds: () -> Void
    private let onToggleScreenLockSounds: () -> Void
    private let onOpenAccessibilitySettings: () -> Void
    private let onToggleLaptopCloseSound: () -> Void
    private let onToggleLaptopOpenSound: () -> Void
    private let onMenuWillOpen: () -> Void
    private let bundle: Bundle
    private let menu = NSMenu()
    private var stateCancellable: AnyCancellable?
    private var accessibilityTrusted = false

    private lazy var notificationSoundsItem = NSMenuItem(
        title: "",
        action: #selector(toggleNotificationSounds),
        keyEquivalent: ""
    )
    private lazy var accessibilityPermissionsItem = NSMenuItem(
        title: "Grant accessibility permissions",
        action: #selector(openAccessibilitySettings),
        keyEquivalent: ""
    )
    private lazy var screenLockSoundsItem = NSMenuItem(
        title: "",
        action: #selector(toggleScreenLockSounds),
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
        onToggleNotificationSounds: @escaping () -> Void,
        onToggleScreenLockSounds: @escaping () -> Void,
        onOpenAccessibilitySettings: @escaping () -> Void,
        onToggleLaptopCloseSound: @escaping () -> Void,
        onToggleLaptopOpenSound: @escaping () -> Void,
        onMenuWillOpen: @escaping () -> Void = {}
    ) {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.appState = appState
        self.bundle = bundle
        self.onToggle = onToggle
        self.onToggleNotificationSounds = onToggleNotificationSounds
        self.onToggleScreenLockSounds = onToggleScreenLockSounds
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
            notificationSoundsEnabled: appState.notificationSoundsEnabled,
            screenLockSoundsEnabled: appState.screenLockSoundsEnabled,
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
        accessibilityPermissionsItem.target = self
        screenLockSoundsItem.target = self
        laptopCloseSoundItem.target = self
        laptopOpenSoundItem.target = self

        menu.addItem(notificationSoundsItem)
        menu.addItem(accessibilityPermissionsItem)
        menu.addItem(screenLockSoundsItem)
        menu.addItem(laptopCloseSoundItem)
        menu.addItem(laptopOpenSoundItem)
        menu.addItem(.separator())
        menu.addItem(quitItem)
    }

    private func bindState() {
        stateCancellable = Publishers.CombineLatest(
            Publishers.CombineLatest4(
                appState.$enabled,
                appState.$notificationSoundsEnabled,
                appState.$screenLockSoundsEnabled,
                appState.$laptopCloseSoundEnabled
            ),
            appState.$laptopOpenSoundEnabled
        )
            .receive(on: RunLoop.main)
            .sink { [weak self] state, laptopOpenSoundEnabled in
                let (enabled, notificationSoundsEnabled, screenLockSoundsEnabled, laptopCloseSoundEnabled) = state
                self?.refreshUI(
                    enabled: enabled,
                    notificationSoundsEnabled: notificationSoundsEnabled,
                    screenLockSoundsEnabled: screenLockSoundsEnabled,
                    laptopCloseSoundEnabled: laptopCloseSoundEnabled,
                    laptopOpenSoundEnabled: laptopOpenSoundEnabled
                )
            }
    }

    private func refreshUI(
        enabled: Bool,
        notificationSoundsEnabled: Bool,
        screenLockSoundsEnabled: Bool,
        laptopCloseSoundEnabled: Bool,
        laptopOpenSoundEnabled: Bool
    ) {
        let notificationSoundsStatus = notificationSoundsStatus(
            appEnabled: enabled,
            notificationSoundsEnabled: notificationSoundsEnabled,
            accessibilityTrusted: accessibilityTrusted
        )
        notificationSoundsItem.title = notificationSoundsStatus.title
        accessibilityPermissionsItem.isHidden = accessibilityTrusted
        screenLockSoundsItem.title = screenLockSoundsEnabled
            ? "Lock/unlock sound: Enabled"
            : "Lock/unlock sound: Click to enable"
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
        // These SVGs intentionally differ by their own fills, so keep AppKit
        // from flattening them into the same monochrome template image.
        image?.isTemplate = false
        button.image = image
        button.imageScaling = .scaleProportionallyDown
        button.toolTip = enabled ? "Running" : "Off"
    }

    func setAccessibilityTrusted(_ trusted: Bool) {
        accessibilityTrusted = trusted
        refreshUI(
            enabled: appState.enabled,
            notificationSoundsEnabled: appState.notificationSoundsEnabled,
            screenLockSoundsEnabled: appState.screenLockSoundsEnabled,
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

    private func notificationSoundsStatus(
        appEnabled: Bool,
        notificationSoundsEnabled: Bool,
        accessibilityTrusted: Bool
    ) -> NotificationSoundsStatus {
        if appEnabled && notificationSoundsEnabled && accessibilityTrusted {
            return .enabled
        }

        return .clickToEnable
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

    @objc private func toggleNotificationSounds() {
        onToggleNotificationSounds()
    }

    @objc private func toggleScreenLockSounds() {
        onToggleScreenLockSounds()
    }

    @objc private func toggleLaptopCloseSound() {
        onToggleLaptopCloseSound()
    }

    @objc private func toggleLaptopOpenSound() {
        onToggleLaptopOpenSound()
    }
}
