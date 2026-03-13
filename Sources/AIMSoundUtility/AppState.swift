import Combine
import Foundation

final class AppState: ObservableObject {
    private enum Keys {
        static let enabled = "isEnabled"
    }

    @Published var enabled: Bool {
        didSet {
            UserDefaults.standard.set(enabled, forKey: Keys.enabled)
        }
    }

    init(userDefaults: UserDefaults = .standard) {
        enabled = userDefaults.object(forKey: Keys.enabled) as? Bool ?? true
    }
}
