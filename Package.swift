// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

/*
 unfortunately I can not get MySQLDriver to link when referenced as a remote package
 instead I have copied in the sources and made a few fixes to accommodate swift 4
 dependencies: [
 .package(
 url:  "https://github.com/mcorega/MySqlSwiftNative",
 from: "1.0.0"
 )
 .target(name: "Ig2SQLCore",
 dependencies: ["Kitura","MySQLDriver"])
 */

import PackageDescription

let package = Package(
    name: "Ig2SQL",
    dependencies: [
      .package(url: "https://github.com/IBM-Swift/Kitura.git", from: "1.0.0"),
        .package(url: "https://github.com/IBM-Swift/Health.git",  from: "0.0.0"),
        .package(url: "https://github.com/IBM-Swift/HeliumLogger.git", from: "1.0.0")
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
                dependencies: ["Kitura","Health"])//,"FLogger"])
    ]
)
