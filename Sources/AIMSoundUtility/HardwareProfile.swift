import Foundation

struct HardwareProfile: Equatable {
    let modelIdentifier: String

    var isM1MacBookAir: Bool {
        modelIdentifier == "MacBookAir10,1"
    }

    static let current = HardwareProfile(modelIdentifier: Self.readModelIdentifier())

    private static func readModelIdentifier() -> String {
        var size = 0
        guard sysctlbyname("hw.model", nil, &size, nil, 0) == 0 else {
            return ""
        }

        var buffer = [CChar](repeating: 0, count: size)
        guard sysctlbyname("hw.model", &buffer, &size, nil, 0) == 0 else {
            return ""
        }

        let bytes = buffer.prefix { $0 != 0 }.map(UInt8.init(bitPattern:))
        return String(decoding: bytes, as: UTF8.self)
    }
}
