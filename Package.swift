// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PySwiftKitDemoPlugin",
    platforms: [.macOS(.v13)],
    
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
        .executable(
            name: "KvAstTree",
            targets: ["KvAstTree"]
        ),
        .executable(
            name: "KvSwiftUITest",
            targets: ["KvSwiftUITest"]
        ),
        .executable(
            name: "KvSwiftUIDemo",
            targets: ["KvSwiftUIDemo"]
        ),
        .executable(
            name: "KvToDataModelDemo",
            targets: ["KvToDataModelDemo"]
        ),
        .executable(
            name: "KvToPyClassDemo",
            targets: ["KvToPyClassDemo"]
        ),
        .library(
            name: "KvSyntaxHighlight",
            targets: ["KvSyntaxHighlight"]
        ),
        .library(
            name: "KvSwiftUI",
            targets: ["KvSwiftUI"]
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
        .package(url: "https://github.com/Py-Swift/SwiftyKvLang", branch: "master"),
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "601.0.0"),
        .package(url: "https://github.com/Py-Swift/JavaScriptKitExtensions", branch: "master")
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
        .target(
            name: "KivyWidgetRegistry",
            dependencies: [],
            path: "KvToPyClass/Sources/KivyWidgetRegistry"
        ),
        .target(
            name: "KvToPyClass",
            dependencies: [
                "KivyWidgetRegistry",
                .product(name: "KvParser", package: "SwiftyKvLang"),
                .product(name: "PySwiftAST", package: "PySwiftAST"),
                .product(name: "PySwiftCodeGen", package: "PySwiftAST"),
                .product(name: "PyFormatters", package: "PySwiftAST"),
            ],
            path: "KvToPyClass/Sources/KvToPyClass"
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
            name: "KvAstTree",
            dependencies: [
                "KvSyntaxHighlight",
                .product(name: "JavaScriptKit", package: "JavaScriptKit"),
                .product(name: "KvParser", package: "SwiftyKvLang"),
            ],
            path: "Sources/KvAstTree"
        ),
        .target(
            name: "KvSyntaxHighlight",
            dependencies: [
                .product(name: "JavaScriptKit", package: "JavaScriptKit"),
                .product(name: "KvParser", package: "SwiftyKvLang"),
                .byName(name: "JavaScriptKitExtensions")
            ],
            path: "Sources/KvSyntaxHighlight"
        ),
        .target(
            name: "KvSwiftUI",
            dependencies: [
                .product(name: "KvParser", package: "SwiftyKvLang"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
            ],
            path: "Sources/KvSwiftUI"
        ),
        .executableTarget(
            name: "KvSwiftUITest",
            dependencies: [
                "KvSwiftUI",
                .product(name: "KvParser", package: "SwiftyKvLang"),
            ],
            path: "Sources/KvSwiftUITest"
        ),
        .executableTarget(
            name: "KvSwiftUIDemo",
            dependencies: [
                "KvSwiftUI",
                "KvSyntaxHighlight",
                .product(name: "JavaScriptKit", package: "JavaScriptKit"),
                .product(name: "KvParser", package: "SwiftyKvLang"),
            ],
            path: "Sources/KvSwiftUIDemo"
        ),
        .executableTarget(
            name: "KvToDataModelDemo",
            dependencies: [
                "KvSyntaxHighlight",
                "PyDataModels",
                .product(name: "JavaScriptKit", package: "JavaScriptKit"),
                .product(name: "KvParser", package: "SwiftyKvLang"),
            ],
            path: "Sources/KvToDataModelDemo"
        ),
        .executableTarget(
            name: "KvToPyClassDemo",
            dependencies: [
                "KvSyntaxHighlight",
                "KvToPyClass",
                .product(name: "JavaScriptKit", package: "JavaScriptKit"),
                .product(name: "JavaScriptKitExtensions", package: "JavaScriptKitExtensions"),
                .product(name: "KvParser", package: "SwiftyKvLang"),
            ],
            path: "Sources/KvToPyClassDemo"
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
