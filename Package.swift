// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Ig2SQL",
    targets: [
        .testTarget(
            name: "Ig2SQLTests",
            dependencies: ["Ig2SQLCore"]
            ),
        
        .target(
            name: "Ig2SQL",
            dependencies: ["Ig2SQLCore"]
        ),
        .target(name: "Ig2SQLCore")
    ]
)
