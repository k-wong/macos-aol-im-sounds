// swift-tools-version: 6.2
import PackageDescription
import Foundation

let executableName = "MacOSSoundboardUtility"

var targets: [Target] = [
    .executableTarget(
        name: executableName,
        path: ".",
        exclude: [
            "build-local-dmg.command",
            "build-local-zip.command",
            "dist",
            "LICENSE",
            "README.md",
            "scripts"
        ],
        sources: ["Sources/SoundUtility"],
        resources: [
            .copy("app-icon-on.svg"),
            .copy("app-icon-off.svg")
        ],
        linkerSettings: [
            .linkedFramework("AppKit"),
            .linkedFramework("ApplicationServices"),
            .linkedFramework("AVFoundation"),
            .linkedFramework("IOKit"),
            .linkedFramework("SwiftUI")
        ]
    )
]

if FileManager.default.fileExists(atPath: "Tests/SoundUtilityTests") {
    targets.append(
        .testTarget(
            name: "MacOSSoundboardUtilityTests",
            dependencies: [
                .target(name: executableName)
            ],
            path: "Tests/SoundUtilityTests"
        )
    )
}

let package = Package(
    name: "MacOSSoundboardUtility",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: executableName,
            targets: [executableName]
        )
    ],
    targets: targets
)
