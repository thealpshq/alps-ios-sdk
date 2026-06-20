// swift-tools-version:5.9
import PackageDescription

let package = Package(
  name: "AlpsSDK",
  platforms: [
    .iOS(.v15),
    .macOS(.v10_15)
  ],
  products: [
    .library(
      name: "AlpsSDK",
      targets: ["AlpsSDK"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/pusher/pusher-websocket-swift", from: "10.1.5")
  ],
  targets: [
    .target(
      name: "AlpsSDK",
      dependencies: [
        .product(name: "PusherSwift", package: "pusher-websocket-swift")
      ],
      path: "Sources/AlpsSDK"
    ),
    .executableTarget(
      name: "AlpsSDKExample",
      dependencies: ["AlpsSDK"],
      path: "Example/AlpsSDKExample"
    )
  ]
)
