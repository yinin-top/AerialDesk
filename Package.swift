// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AerialDesk",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "AerialDesk", path: "Sources/AerialDesk"),
        .testTarget(name: "AerialDeskTests", dependencies: ["AerialDesk"], path: "Tests/AerialDeskTests"),
    ]
)
