import Foundation
import IOKit.hid

protocol LidAngleReading: AnyObject {
    func readAngle() -> Double?
    func close()
}

private final class HIDLidAngleSensor: LidAngleReading {
    private enum Constants {
        static let vendorID = 0x05AC
        static let productID = 0x8104
        static let usagePage = 0x0020
        static let usage = 0x008A
        static let reportID: CFIndex = 1
        static let reportLength = 8
        static let maxAngleDegrees = 360.0
    }

    private let manager: IOHIDManager
    private let device: IOHIDDevice

    private init(manager: IOHIDManager, device: IOHIDDevice) {
        self.manager = manager
        self.device = device
    }

    static func makeDefault() -> LidAngleReading? {
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        let matching: [String: Int] = [
            kIOHIDVendorIDKey as String: Constants.vendorID,
            kIOHIDProductIDKey as String: Constants.productID,
            kIOHIDPrimaryUsagePageKey as String: Constants.usagePage,
            kIOHIDPrimaryUsageKey as String: Constants.usage
        ]

        IOHIDManagerSetDeviceMatching(manager, matching as CFDictionary)

        guard IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone)) == kIOReturnSuccess else {
            return nil
        }

        guard let devices = IOHIDManagerCopyDevices(manager) else {
            IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
            return nil
        }

        let deviceSet = devices as NSSet
        guard let firstDevice = deviceSet.allObjects.first else {
            IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
            return nil
        }

        let device = firstDevice as! IOHIDDevice
        guard IOHIDDeviceOpen(device, IOOptionBits(kIOHIDOptionsTypeNone)) == kIOReturnSuccess else {
            IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
            return nil
        }

        return HIDLidAngleSensor(manager: manager, device: device)
    }

    func readAngle() -> Double? {
        var report = [UInt8](repeating: 0, count: Constants.reportLength)
        var length = report.count

        let result = IOHIDDeviceGetReport(
            device,
            kIOHIDReportTypeFeature,
            Constants.reportID,
            &report,
            &length
        )

        guard result == kIOReturnSuccess, length >= 3 else {
            return nil
        }

        // Reverse-engineered sensors report a little-endian centidegree value.
        let centidegrees = UInt16(report[1]) | (UInt16(report[2]) << 8)
        let angle = Double(centidegrees) / 100.0

        guard angle >= 0, angle <= Constants.maxAngleDegrees else {
            return nil
        }

        return angle
    }

    func close() {
        IOHIDDeviceClose(device, IOOptionBits(kIOHIDOptionsTypeNone))
        IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
    }
}

final class LidAngleMonitor {
    var onCloseThresholdReached: (@MainActor @Sendable () -> Void)?

    private let pollInterval: TimeInterval
    private let closeThresholdDegrees: Double
    private let queue: DispatchQueue
    private let sensorFactory: () -> LidAngleReading?

    private var timer: DispatchSourceTimer?
    private var sensor: LidAngleReading?
    private var isBelowCloseThreshold = false

    init(
        pollInterval: TimeInterval = 0.05,
        closeThresholdDegrees: Double = 60,
        queue: DispatchQueue = DispatchQueue(label: "aim.lid-angle.monitor", qos: .userInteractive),
        sensorFactory: @escaping () -> LidAngleReading? = HIDLidAngleSensor.makeDefault
    ) {
        self.pollInterval = pollInterval
        self.closeThresholdDegrees = closeThresholdDegrees
        self.queue = queue
        self.sensorFactory = sensorFactory
    }

    func start() {
        stop()

        guard let sensor = sensorFactory() else {
            return
        }

        self.sensor = sensor
        if let angle = sensor.readAngle() {
            isBelowCloseThreshold = angle < closeThresholdDegrees
        }

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
        sensor?.close()
        sensor = nil
        isBelowCloseThreshold = false
    }

    func isCurrentlyNearClosed() -> Bool {
        guard let angle = sensor?.readAngle() else {
            return isBelowCloseThreshold
        }

        isBelowCloseThreshold = angle < closeThresholdDegrees
        return isBelowCloseThreshold
    }

    private func poll() {
        guard let angle = sensor?.readAngle() else {
            return
        }

        let wasBelowCloseThreshold = isBelowCloseThreshold
        isBelowCloseThreshold = angle < closeThresholdDegrees

        guard isBelowCloseThreshold, !wasBelowCloseThreshold else {
            return
        }

        let onCloseThresholdReached = self.onCloseThresholdReached
        DispatchQueue.main.async {
            onCloseThresholdReached?()
        }
    }
}
