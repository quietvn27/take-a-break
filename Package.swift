// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TakeABreak",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "TakeABreak",
            path: "TakeABreak",
            exclude: ["Info.plist", "Assets.xcassets"]
        )
    ]
)
