import Foundation

enum AppSoundLibrary {
    private static let directoryName = "macOS Soundboard"
    private static let soundsDirectoryName = "Sounds"

    static func configuredSoundURL(for event: SoundEvent, fileManager: FileManager = .default) -> URL? {
        guard let soundsDirectory = try? soundsDirectory(fileManager: fileManager) else {
            return nil
        }

        let fileURL = soundsDirectory.appendingPathComponent(filename(for: event), isDirectory: false)
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        return fileURL
    }

    @discardableResult
    static func installSound(
        from sourceURL: URL,
        for event: SoundEvent,
        fileManager: FileManager = .default
    ) throws -> URL {
        let destinationURL = try soundsDirectory(fileManager: fileManager)
            .appendingPathComponent(filename(for: event), isDirectory: false)

        if sourceURL.standardizedFileURL == destinationURL.standardizedFileURL {
            return destinationURL
        }

        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }

        try fileManager.copyItem(at: sourceURL, to: destinationURL)
        return destinationURL
    }

    private static func soundsDirectory(fileManager: FileManager) throws -> URL {
        let applicationSupportDirectory = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let soundsDirectory = applicationSupportDirectory
            .appendingPathComponent(directoryName, isDirectory: true)
            .appendingPathComponent(soundsDirectoryName, isDirectory: true)

        try fileManager.createDirectory(
            at: soundsDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )
        return soundsDirectory
    }

    private static func filename(for event: SoundEvent) -> String {
        "\(event.rawValue).mp3"
    }
}
