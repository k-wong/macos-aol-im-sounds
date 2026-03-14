import AppKit
import ApplicationServices
import Foundation
import OSLog

@MainActor
final class NotificationMonitor {
    private enum Constants {
        static let notificationCenterBundleIdentifier = "com.apple.notificationcenterui"
        static let scanInterval: TimeInterval = 0.75
        static let maxTextDepth = 8
    }

    private let workspace: NSWorkspace
    private let ruleEngine: NotificationRuleEngine
    private let onEvent: (NotificationEvent) -> Void
    private let logger = AppLog.logger("notification.monitor")

    private var timer: Timer?
    private var visibleBannerKeys: Set<String> = []

    init(
        workspace: NSWorkspace = .shared,
        ruleEngine: NotificationRuleEngine = NotificationRuleEngine(),
        onEvent: @escaping (NotificationEvent) -> Void
    ) {
        self.workspace = workspace
        self.ruleEngine = ruleEngine
        self.onEvent = onEvent
    }

    var isAccessibilityTrusted: Bool {
        AXIsProcessTrusted()
    }

    func start() {
        log("Starting notification monitor")
        guard isAccessibilityTrusted else {
            log("Accessibility permission is not granted; notification monitor will remain idle")
            visibleBannerKeys.removeAll()
            return
        }

        stop()
        scanForNotifications()

        let timer = Timer(timeInterval: Constants.scanInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.scanForNotifications()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        visibleBannerKeys.removeAll()
    }

    private func scanForNotifications() {
        guard let application = notificationCenterApplication() else {
            visibleBannerKeys.removeAll()
            return
        }

        let appElement = AXUIElementCreateApplication(application.processIdentifier)
        let windows = copyElementArrayAttribute(kAXWindowsAttribute as CFString, from: appElement)
        let events = windows.compactMap(extractNotificationEvent(from:))
        let currentKeys = Set(events.map(\.dedupeKey))

        for event in events where !visibleBannerKeys.contains(event.dedupeKey) {
            log("Detected notification banner \(event.dedupeKey)")
            onEvent(event)
        }

        visibleBannerKeys = currentKeys
    }

    private func notificationCenterApplication() -> NSRunningApplication? {
        workspace.runningApplications.first {
            $0.bundleIdentifier == Constants.notificationCenterBundleIdentifier
        }
    }

    private func extractNotificationEvent(from window: AXUIElement) -> NotificationEvent? {
        let texts = uniqueNonEmptyTexts(in: window, depthRemaining: Constants.maxTextDepth)
        guard texts.count >= 2 else {
            return nil
        }

        let appName = texts.first
        let title = texts.dropFirst().first
        let subtitle = texts.count > 2 ? texts[2] : nil
        let body = texts.count > 3 ? Array(texts.dropFirst(3)).joined(separator: " ") : nil
        let identifier = copyStringAttribute("AXIdentifier" as CFString, from: window)

        return ruleEngine.classify(
            NotificationObservation(
                appName: appName,
                title: title,
                subtitle: subtitle,
                body: body,
                bundleIdentifier: appName.flatMap(bundleIdentifier(forAppName:)),
                identifier: identifier
            )
        )
    }

    private func bundleIdentifier(forAppName appName: String) -> String? {
        workspace.runningApplications.first { runningApp in
            guard let localizedName = runningApp.localizedName else {
                return false
            }

            return localizedName.caseInsensitiveCompare(appName) == .orderedSame
        }?.bundleIdentifier
    }

    private func uniqueNonEmptyTexts(in element: AXUIElement, depthRemaining: Int) -> [String] {
        guard depthRemaining > 0 else {
            return []
        }

        var texts: [String] = []

        if let title = copyStringAttribute(kAXTitleAttribute as CFString, from: element) {
            texts.append(title)
        }

        if let description = copyStringAttribute(kAXDescriptionAttribute as CFString, from: element) {
            texts.append(description)
        }

        if let value = copyStringAttribute(kAXValueAttribute as CFString, from: element) {
            texts.append(value)
        }

        let childAttributes = [kAXChildrenAttribute as CFString, kAXContentsAttribute as CFString]
        for attribute in childAttributes {
            for child in copyElementArrayAttribute(attribute, from: element) {
                texts.append(contentsOf: uniqueNonEmptyTexts(in: child, depthRemaining: depthRemaining - 1))
            }
        }

        var seen = Set<String>()
        return texts.compactMap { text in
            let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !normalized.isEmpty, seen.insert(normalized).inserted else {
                return nil
            }

            return normalized
        }
    }

    private func copyStringAttribute(_ attribute: CFString, from element: AXUIElement) -> String? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute, &value)
        guard result == .success else {
            return nil
        }

        return value as? String
    }

    private func copyElementArrayAttribute(_ attribute: CFString, from element: AXUIElement) -> [AXUIElement] {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute, &value)
        guard result == .success, let elements = value as? [AXUIElement] else {
            return []
        }

        return elements
    }
}

private extension NotificationMonitor {
    func log(_ message: String) {
        logger.notice("\(message, privacy: .public)")
    }
}
