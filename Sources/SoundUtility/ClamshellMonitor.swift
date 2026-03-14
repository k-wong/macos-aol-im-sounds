import Foundation
import IOKit
import IOKit.pwr_mgt

final class ClamshellMonitor: NSObject {
    var onChange: (@MainActor @Sendable (Bool) -> Void)?

    private let pollInterval: TimeInterval
    private let stateProvider: () -> Bool?
    private let queue: DispatchQueue
    private var timer: DispatchSourceTimer?
    private var lastKnownState: Bool?

    init(
        pollInterval: TimeInterval = 0.05,
        queue: DispatchQueue = DispatchQueue(label: "aim.clamshell.monitor", qos: .userInteractive),
        stateProvider: @escaping () -> Bool? = ClamshellMonitor.readCurrentState
    ) {
        self.pollInterval = pollInterval
        self.queue = queue
        self.stateProvider = stateProvider
        super.init()
    }

    func start() {
        stop()
        lastKnownState = stateProvider()

        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(
            deadline: .now() + pollInterval,
            repeating: pollInterval,
            leeway: .milliseconds(20)
        )
        timer.setEventHandler { [weak self] in
            self?.poll()
        }
        timer.resume()
        self.timer = timer
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }

    func currentState() -> Bool? {
        stateProvider()
    }

    nonisolated private func poll() {
        guard let currentState = stateProvider() else {
            return
        }

        guard currentState != lastKnownState else {
            return
        }

        lastKnownState = currentState
        let onChange = self.onChange
        DispatchQueue.main.async {
            onChange?(currentState)
        }
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
