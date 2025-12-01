// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PySwiftKitDemoPlugin",
    

    products: [
        .executable(
            name: "PySwiftKitDemo",
            targets: ["PySwiftKitDemo"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftwasm/JavaScriptKit", from: "0.19.0"),
        .package(url: "https://github.com/Py-Swift/PySwiftAST", branch: "master"),
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "601.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "PySwiftKitDemo",
            dependencies: [
                .product(name: "JavaScriptKit", package: "JavaScriptKit"),
                .product(name: "PySwiftAST", package: "PySwiftAST"),
                .product(name: "PySwiftCodeGen", package: "PySwiftAST"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
            ],
            path: "Sources"
        ),
    ]
)
