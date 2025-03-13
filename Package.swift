// swift-tools-version: 5.9
// This is a Skip (https://skip.tools) package,
// containing a Swift Package Manager project
// that will use the Skip build plugin to transpile the
// Swift Package, Sources, and Tests into an
// Android Gradle Project with Kotlin sources and JUnit tests.
import PackageDescription

let package = Package(
    name: "skip-webrtc",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14), .tvOS(.v17), .watchOS(.v10), .macCatalyst(.v17)],
    products: [
        .library(name: "SkipWebRTC", type: .dynamic, targets: ["SkipWebRTC"]),
    ],
    dependencies: [
        .package(url: "https://source.skip.tools/skip.git", from: "1.3.2"),
        .package(url: "https://source.skip.tools/skip-foundation.git", from: "1.0.0"),
	.package(url: "https://github.com/stasel/WebRTC.git", .upToNextMajor(from: "134.0.0"))
    ],
    targets: [
        .target(name: "SkipWebRTC", dependencies: [
            .product(name: "WebRTC", package: "WebRTC"),
            .product(name: "SkipFoundation", package: "skip-foundation")
        ], resources: [.process("Resources")], plugins: [.plugin(name: "skipstone", package: "skip")]),
        .testTarget(name: "SkipWebRTCTests", dependencies: [
            "SkipWebRTC",
            .product(name: "SkipTest", package: "skip")
        ], resources: [.process("Resources")], plugins: [.plugin(name: "skipstone", package: "skip")]),
    ]
)
