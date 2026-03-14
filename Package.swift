// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "AIMSoundUtility",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "AIMSoundUtility",
            targets: ["AIMSoundUtility"]
        )
    ],
    targets: [
        .executableTarget(
            name: "AIMSoundUtility",
            path: ".",
            exclude: [
                "build-local-dmg.command",
                "dist",
                "LICENSE",
                "README.md",
                "scripts",
                "Tests"
            ],
            sources: ["Sources/SoundUtility"],
            resources: [
                .copy("exit.mp3"),
                .copy("open.mp3"),
                .copy("message.mp3"),
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
        ),
        .testTarget(
            name: "AIMSoundUtilityTests",
            dependencies: ["AIMSoundUtility"],
            path: "Tests/SoundUtilityTests"
        )
    ]
)
