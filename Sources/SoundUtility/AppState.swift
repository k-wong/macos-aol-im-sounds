import Combine
import Foundation

final class AppState: ObservableObject {
    private enum Keys {
        static let enabled = "isEnabled"
        static let notificationSoundsEnabled = "isNotificationSoundsEnabled"
        static let screenLockSoundsEnabled = "isScreenLockSoundsEnabled"
        static let laptopCloseSoundEnabled = "isLaptopCloseSoundEnabled"
        static let laptopOpenSoundEnabled = "isLaptopOpenSoundEnabled"
    }

    @Published var enabled: Bool {
        didSet {
            UserDefaults.standard.set(enabled, forKey: Keys.enabled)
        }
    }

    @Published var notificationSoundsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationSoundsEnabled, forKey: Keys.notificationSoundsEnabled)
        }
    }

    @Published var screenLockSoundsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(screenLockSoundsEnabled, forKey: Keys.screenLockSoundsEnabled)
        }
    }

    @Published var laptopCloseSoundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(laptopCloseSoundEnabled, forKey: Keys.laptopCloseSoundEnabled)
        }
    }

    @Published var laptopOpenSoundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(laptopOpenSoundEnabled, forKey: Keys.laptopOpenSoundEnabled)
        }
    }

    init(userDefaults: UserDefaults = .standard) {
        enabled = userDefaults.object(forKey: Keys.enabled) as? Bool ?? true
        notificationSoundsEnabled = userDefaults.object(forKey: Keys.notificationSoundsEnabled) as? Bool ?? true
        screenLockSoundsEnabled = userDefaults.object(forKey: Keys.screenLockSoundsEnabled) as? Bool ?? true
        laptopCloseSoundEnabled = userDefaults.object(forKey: Keys.laptopCloseSoundEnabled) as? Bool ?? true
        laptopOpenSoundEnabled = userDefaults.object(forKey: Keys.laptopOpenSoundEnabled) as? Bool ?? true
    }
}
