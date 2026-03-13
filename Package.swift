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
                "README.md",
                "Tests"
            ],
            sources: ["Sources/AIMSoundUtility"],
            resources: [
                .copy("aim-exit.mp3"),
                .copy("aim-open.mp3"),
                .copy("aim-message.mp3"),
                .copy("aim-app-icon-on.svg"),
                .copy("aim-app-icon-off.svg")
            ],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("IOKit"),
                .linkedFramework("SwiftUI")
            ]
        ),
        .testTarget(
            name: "AIMSoundUtilityTests",
            dependencies: ["AIMSoundUtility"],
            path: "Tests/AIMSoundUtilityTests"
        )
    ]
)
