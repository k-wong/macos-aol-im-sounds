import Foundation
import OSLog

enum AppLog {
    private static let subsystem = "com.macossoundboard.app"

    static func logger(_ category: String) -> Logger {
        Logger(subsystem: subsystem, category: category)
    }
}
