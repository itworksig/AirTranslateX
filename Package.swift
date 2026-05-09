// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "AirTranslate",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .executable(name: "AirTranslate", targets: ["AirTranslate"])
    ],
    targets: [
        .executableTarget(
            name: "AirTranslate",
            linkerSettings: [
                .linkedFramework("AVFAudio"),
                .linkedFramework("ScreenCaptureKit"),
                .linkedFramework("Speech"),
                .linkedFramework("Translation")
            ]
        )
    ]
)
