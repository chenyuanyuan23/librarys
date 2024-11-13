// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "TXLiteAVSDK_Player",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "TXFFmpeg",
            targets: ["TXFFmpeg"]),
        .library(
            name: "TXLiteAVSDK_Player",
            targets: ["TXLiteAVSDK_Player"]),
        .library(
            name: "TXSoundTouch",
            targets: ["TXSoundTouch"])
    ],
    targets: [
        .binaryTarget(
            name: "TXFFmpeg",
            path: "TXFFmpeg.xcframework"),
        .binaryTarget(
            name: "TXLiteAVSDK_Player",
            path: "TXLiteAVSDK_Player.xcframework"),
        .binaryTarget(
            name: "TXSoundTouch",
            path: "TXSoundTouch.xcframework")
    ]
)