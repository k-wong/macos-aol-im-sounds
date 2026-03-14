import Foundation

enum AppResources {
    private static let bundleName = "AIMSoundUtility_AIMSoundUtility.bundle"

    static func bundle(mainBundle: Bundle = .main) -> Bundle {
        let candidateURLs = bundleSearchRoots(mainBundle: mainBundle).map {
            $0.appendingPathComponent(bundleName, isDirectory: true)
        }

        for candidateURL in candidateURLs.compactMap({ $0 }) {
            if let bundle = Bundle(url: candidateURL) {
                return bundle
            }
        }

        Swift.fatalError("could not locate resource bundle named \(bundleName)")
    }

    private static func bundleSearchRoots(mainBundle: Bundle) -> [URL] {
        var roots: [URL] = []

        if let resourceURL = mainBundle.resourceURL {
            roots.append(resourceURL)
        }

        roots.append(mainBundle.bundleURL)
        roots.append(mainBundle.bundleURL.deletingLastPathComponent())

        if let executableURL = mainBundle.executableURL {
            let executableDirectory = executableURL.deletingLastPathComponent()
            roots.append(executableDirectory)
            roots.append(executableDirectory.deletingLastPathComponent())
            roots.append(executableDirectory.deletingLastPathComponent().deletingLastPathComponent())
        }

        let workingDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
        roots.append(workingDirectory)
        roots.append(workingDirectory.appendingPathComponent(".build", isDirectory: true))

        var uniqueRoots: [URL] = []
        var seenPaths = Set<String>()

        for root in roots {
            let standardizedPath = root.standardizedFileURL.path
            if seenPaths.insert(standardizedPath).inserted {
                uniqueRoots.append(root)
            }
        }

        return uniqueRoots
    }
}
