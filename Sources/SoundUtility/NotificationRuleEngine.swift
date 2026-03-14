import AppKit
import Foundation

struct NotificationObservation: Equatable {
    let appName: String?
    let title: String?
    let subtitle: String?
    let body: String?
    let bundleIdentifier: String?
    let identifier: String?
}

enum NotificationSource: Equatable {
    case slack
    case standard(appName: String, bundleIdentifier: String?)
}

struct NotificationEvent: Equatable {
    let source: NotificationSource
    let title: String?
    let subtitle: String?
    let body: String?
    let dedupeKey: String
}

final class NotificationRuleEngine {
    private let workspace: NSWorkspace

    init(workspace: NSWorkspace = .shared) {
        self.workspace = workspace
    }

    func classify(_ observation: NotificationObservation) -> NotificationEvent? {
        let appName = normalize(observation.appName)
        let title = normalize(observation.title)
        let subtitle = normalize(observation.subtitle)
        let body = normalize(observation.body)
        let bundleIdentifier = normalize(observation.bundleIdentifier)

        guard appName != nil || bundleIdentifier != nil else {
            return nil
        }

        if isSlack(appName: appName, bundleIdentifier: bundleIdentifier) {
            return NotificationEvent(
                source: .slack,
                title: title,
                subtitle: subtitle,
                body: body,
                dedupeKey: makeDedupeKey(
                    appName: appName ?? "Slack",
                    title: title,
                    subtitle: subtitle,
                    body: body,
                    identifier: observation.identifier
                )
            )
        }

        guard let resolvedAppName = resolveAppName(appName: appName, bundleIdentifier: bundleIdentifier) else {
            return nil
        }

        let resolvedBundleID = bundleIdentifier ?? runningApplication(named: resolvedAppName)?.bundleIdentifier
        return NotificationEvent(
            source: .standard(appName: resolvedAppName, bundleIdentifier: resolvedBundleID),
            title: title,
            subtitle: subtitle,
            body: body,
            dedupeKey: makeDedupeKey(
                appName: resolvedAppName,
                title: title,
                subtitle: subtitle,
                body: body,
                identifier: observation.identifier
            )
        )
    }

    private func isSlack(appName: String?, bundleIdentifier: String?) -> Bool {
        if let bundleIdentifier, bundleIdentifier.caseInsensitiveCompare("com.tinyspeck.slackmacgap") == .orderedSame {
            return true
        }

        guard let appName else {
            return false
        }

        return appName.caseInsensitiveCompare("Slack") == .orderedSame
    }

    private func resolveAppName(appName: String?, bundleIdentifier: String?) -> String? {
        if let bundleIdentifier,
           let app = workspace.runningApplications.first(where: {
               $0.bundleIdentifier?.caseInsensitiveCompare(bundleIdentifier) == .orderedSame
           }),
           let localizedName = normalize(app.localizedName) {
            return localizedName
        }

        if let appName,
           let localizedName = runningApplication(named: appName)?.localizedName {
            return normalize(localizedName)
        }

        return nil
    }

    private func runningApplication(named appName: String) -> NSRunningApplication? {
        workspace.runningApplications.first { runningApp in
            guard let localizedName = runningApp.localizedName else {
                return false
            }

            return localizedName.caseInsensitiveCompare(appName) == .orderedSame
        }
    }

    private func makeDedupeKey(
        appName: String,
        title: String?,
        subtitle: String?,
        body: String?,
        identifier: String?
    ) -> String {
        [
            normalize(identifier),
            normalize(appName),
            title,
            subtitle,
            body
        ]
        .compactMap { $0 }
        .joined(separator: "|")
    }

    private func normalize(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return nil
        }

        return value
    }
}
