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
        .executable(
            name: "SwiftToPythonDemo",
            targets: ["SwiftToPythonDemo"]
        ),
        .executable(
            name: "PythonToSwiftDemo",
            targets: ["PythonToSwiftDemo"]
        ),
        .executable(
            name: "PyDataModelDemo",
            targets: ["PyDataModelDemo"]
        ),
        .library(
            name: "PythonToSwiftLib",
            targets: ["PythonToSwiftLib"]
        ),
        .library(
            name: "SwiftToPythonLib",
            targets: ["SwiftToPythonLib"]
        ),
        .library(
            name: "PyDataModels",
            targets: ["PyDataModels"]
        ),
        .library(
            name: "PySwiftTypeConverter",
            targets: ["PySwiftTypeConverter"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftwasm/JavaScriptKit", from: "0.19.0"),
        .package(url: "https://github.com/Py-Swift/PySwiftAST", branch: "master"),
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "601.0.0"),
    ],
    targets: [
        .target(
            name: "PySwiftTypeConverter",
            dependencies: [
                .product(name: "PySwiftAST", package: "PySwiftAST"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
            ],
            path: "Sources/PySwiftTypeConverter"
        ),
        .target(
            name: "PythonToSwiftLib",
            dependencies: [
                "PySwiftTypeConverter",
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
        .target(
            name: "PyDataModels",
            dependencies: [
                "PySwiftTypeConverter",
                .product(name: "PySwiftAST", package: "PySwiftAST"),
                .product(name: "PySwiftCodeGen", package: "PySwiftAST"),
                .product(name: "PyAstVisitors", package: "PySwiftAST"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
            ],
            path: "Sources/PyDataModels"
        ),
        .executableTarget(
            name: "PySwiftKitDemo",
            dependencies: [
                "PythonToSwiftLib",
                "SwiftToPythonLib",
                "PyDataModels",
                .product(name: "JavaScriptKit", package: "JavaScriptKit"),
            ],
            path: "Sources/PySwiftKitDemo"
        ),
        .executableTarget(
            name: "SwiftToPythonDemo",
            dependencies: [
                "SwiftToPythonLib",
                .product(name: "JavaScriptKit", package: "JavaScriptKit"),
            ],
            path: "Sources/SwiftToPythonDemo"
        ),
        .executableTarget(
            name: "PythonToSwiftDemo",
            dependencies: [
                "PythonToSwiftLib",
                .product(name: "JavaScriptKit", package: "JavaScriptKit"),
            ],
            path: "Sources/PythonToSwiftDemo"
        ),
        .executableTarget(
            name: "PyDataModelDemo",
            dependencies: [
                "PyDataModels",
                .product(name: "JavaScriptKit", package: "JavaScriptKit"),
            ],
            path: "Sources/PyDataModelDemo"
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
        .testTarget(
            name: "PyDataModelTests",
            dependencies: [
                "PyDataModels",
            ],
            path: "Tests/PyDataModelTests"
        ),
    ]
)
