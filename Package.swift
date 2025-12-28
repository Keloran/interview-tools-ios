// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Interviews",
    platforms: [
      .iOS(.v26.1),
      .ipadOS(.v26.1)
    ]
    dependencies: [
        .package(url: "https://github.com/flags-gg/swift.git", from: "v1.0.2"),
        .package(url: "https://github.com/clerk/clerk-ios.git", from: "0.71.4")
    ],
    targets: [
      .target(name: "Interviews", dependencies: [
        "Flags.gg",
        "Clerk"
      ])
    ]
)
