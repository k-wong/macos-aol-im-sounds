import AppKit
@preconcurrency import ApplicationServices
import Foundation

struct AccessibilitySettingsRoute {
    let directURL: URL
    let fallbackURL: URL

    static let `default` = AccessibilitySettingsRoute(
        directURL: URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!,
        fallbackURL: URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension")!
    )
}

protocol AccessibilityTrustChecking {
    var isTrusted: Bool { get }
    @discardableResult
    func promptForAccess() -> Bool
}

struct SystemAccessibilityTrustChecker: AccessibilityTrustChecking {
    var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    func promptForAccess() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
}

protocol AccessibilitySettingsOpening {
    func openSettings(using route: AccessibilitySettingsRoute) -> Bool
}

struct WorkspaceAccessibilitySettingsOpener: AccessibilitySettingsOpening {
    let workspace: NSWorkspace

    init(workspace: NSWorkspace = .shared) {
        self.workspace = workspace
    }

    func openSettings(using route: AccessibilitySettingsRoute) -> Bool {
        if workspace.open(route.directURL) {
            return true
        }

        return workspace.open(route.fallbackURL)
    }
}

@MainActor
final class AccessibilityPermissionCoordinator {
    enum Status: Equatable {
        case allowed
        case needsAccess
    }

    private let trustChecker: AccessibilityTrustChecking
    private let settingsOpener: AccessibilitySettingsOpening
    private let route: AccessibilitySettingsRoute

    init(
        trustChecker: AccessibilityTrustChecking = SystemAccessibilityTrustChecker(),
        settingsOpener: AccessibilitySettingsOpening = WorkspaceAccessibilitySettingsOpener(),
        route: AccessibilitySettingsRoute = .default
    ) {
        self.trustChecker = trustChecker
        self.settingsOpener = settingsOpener
        self.route = route
    }

    var status: Status {
        trustChecker.isTrusted ? .allowed : .needsAccess
    }

    var isTrusted: Bool {
        trustChecker.isTrusted
    }

    @discardableResult
    func requestAccessIfNeeded() -> Bool {
        guard !trustChecker.isTrusted else {
            return true
        }

        return trustChecker.promptForAccess()
    }

    @discardableResult
    func openSettings() -> Bool {
        settingsOpener.openSettings(using: route)
    }

    @discardableResult
    func promptAndOpenSettings() -> Bool {
        requestAccessIfNeeded()
        return openSettings()
    }
}
