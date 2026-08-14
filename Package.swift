// swift-tools-version: 5.9

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "SpotBrief",
    platforms: [
        .iOS("17.0")
    ],
    products: [
        .iOSApplication(
            name: "SpotBrief",
            targets: ["SpotBrief"],
            bundleIdentifier: "ru.matwey.spotbrief",
            teamIdentifier: "",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .openBook),
            accentColor: .presetColor(.orange),
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown(.when(deviceFamilies: [.pad]))
            ]
        )
    ],
    targets: [
        .executableTarget(
            name: "SpotBrief"
        )
    ]
)
