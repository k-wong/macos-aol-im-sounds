import Foundation
import IOKit
import IOKit.pwr_mgt

@MainActor
final class ClamshellMonitor: NSObject {
    var onChange: ((Bool) -> Void)?

    private let pollInterval: TimeInterval
    private let stateProvider: () -> Bool?
    private var timer: Timer?
    private var lastKnownState: Bool?

    init(
        pollInterval: TimeInterval = 1.0,
        stateProvider: @escaping () -> Bool? = ClamshellMonitor.readCurrentState
    ) {
        self.pollInterval = pollInterval
        self.stateProvider = stateProvider
        super.init()
    }

    func start() {
        let initialState = stateProvider()
        lastKnownState = initialState

        let timer = Timer.scheduledTimer(
            timeInterval: pollInterval,
            target: self,
            selector: #selector(timerFired(_:)),
            userInfo: nil,
            repeats: true
        )
        self.timer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func poll() {
        guard let currentState = stateProvider() else {
            return
        }

        guard currentState != lastKnownState else {
            return
        }

        lastKnownState = currentState
        onChange?(currentState)
    }

    @objc private func timerFired(_ timer: Timer) {
        poll()
    }

    nonisolated static func readCurrentState() -> Bool? {
        guard let matching = IOServiceMatching("IOPMrootDomain") else {
            return nil
        }

        let service = IOServiceGetMatchingService(kIOMainPortDefault, matching)
        guard service != IO_OBJECT_NULL else {
            return nil
        }
        defer { IOObjectRelease(service) }

        let property = IORegistryEntryCreateCFProperty(
            service,
            "AppleClamshellState" as CFString,
            kCFAllocatorDefault,
            0
        )?.takeRetainedValue()

        return property as? Bool
    }
}
