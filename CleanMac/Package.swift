// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CleanMac",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "CleanMac", targets: ["CleanMac"])
    ],
    targets: [
        .executableTarget(
            name: "CleanMac",
            path: "Sources"
        ),
        .testTarget(
            name: "CleanMacTests",
            dependencies: ["CleanMac"],
            path: "Tests/CleanMacTests"
        )
    ]
)
