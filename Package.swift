// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PySwiftKitDemoPlugin",
    platforms: [.macOS(.v10_15)],
    
    products: [
        .executable(
            name: "PySwiftKitDemo",
            targets: ["PySwiftKitDemo"]
        ),
        .library(
            name: "PythonToSwiftLib",
            targets: ["PythonToSwiftLib"]
        ),
        .library(
            name: "SwiftToPythonLib",
            targets: ["SwiftToPythonLib"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftwasm/JavaScriptKit", from: "0.19.0"),
        .package(url: "https://github.com/Py-Swift/PySwiftAST", branch: "master"),
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "601.0.0"),
    ],
    targets: [
        .target(
            name: "PythonToSwiftLib",
            dependencies: [
                .product(name: "PySwiftAST", package: "PySwiftAST"),
                .product(name: "PyAstVisitors", package: "PySwiftAST"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
            ],
            path: "Sources/PythonToSwiftLib"
        ),
        .target(
            name: "SwiftToPythonLib",
            dependencies: [
                .product(name: "PySwiftAST", package: "PySwiftAST"),
                .product(name: "PySwiftCodeGen", package: "PySwiftAST"),
                .product(name: "PyAstVisitors", package: "PySwiftAST"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
            ],
            path: "Sources/SwiftToPythonLib"
        ),
        .executableTarget(
            name: "PySwiftKitDemo",
            dependencies: [
                "PythonToSwiftLib",
                "SwiftToPythonLib",
                .product(name: "JavaScriptKit", package: "JavaScriptKit"),
            ],
            path: "Sources/PySwiftKitDemo"
        ),
        .executableTarget(
            name: "ParserTest",
            dependencies: [
                "PythonToSwiftLib",
            ],
            path: "Tests/ParserTest"
        ),
        .testTarget(
            name: "PythonToSwiftTests",
            dependencies: [
                "PythonToSwiftLib",
            ],
            path: "Tests/PythonToSwiftTests"
        ),
    ]
)
