// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Ig2SQL",
    dependencies: [
        .package(
            url:  "https://github.com/IBM-Swift/Kitura.git",
            from: "1.0.0"
        )
    ],
    targets: [
        .testTarget(
            name: "Ig2SQLTests",
            dependencies: ["Ig2SQLCore"]
            ),
        
        .target(
            name: "Ig2SQL",
            dependencies: ["Ig2SQLCore"]
        ),
        .target(name: "Ig2SQLCore",
                dependencies: ["Kitura"])
    ]
)
