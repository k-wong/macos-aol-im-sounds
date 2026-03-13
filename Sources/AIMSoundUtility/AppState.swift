import Combine
import Foundation

final class AppState: ObservableObject {
    private enum Keys {
        static let enabled = "isEnabled"
        static let laptopCloseSoundEnabled = "isLaptopCloseSoundEnabled"
        static let laptopOpenSoundEnabled = "isLaptopOpenSoundEnabled"
    }

    @Published var enabled: Bool {
        didSet {
            UserDefaults.standard.set(enabled, forKey: Keys.enabled)
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
        laptopCloseSoundEnabled = userDefaults.object(forKey: Keys.laptopCloseSoundEnabled) as? Bool ?? true
        laptopOpenSoundEnabled = userDefaults.object(forKey: Keys.laptopOpenSoundEnabled) as? Bool ?? true
    }
}
