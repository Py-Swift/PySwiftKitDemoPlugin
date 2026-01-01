// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KvToPyClassVsCodeExtension",
    platforms: [.macOS(.v13)],
    products: [
        .executable(
            name: "KvToPyClassVsCodeExtension",
            targets: ["KvToPyClassVsCodeExtension"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swiftwasm/JavaScriptKit", from: "0.19.0"),
        .package(url: "https://github.com/Py-Swift/SwiftyKvLang", branch: "master"),
        .package(url: "https://github.com/Py-Swift/PySwiftAST", branch: "master"),
        .package(url: "https://github.com/Py-Swift/JavaScriptKitExtensions", branch: "master"),
        .package(path: "../KvToPyClass"),
    ],
    targets: [
        .target(
            name: "MonacoApi",
            dependencies: []
        ),
        .target(
            name: "MonacoJSK",
            dependencies: [
                .product(name: "JavaScriptKit", package: "JavaScriptKit"),
                "MonacoApi",
            ]
        ),
        .executableTarget(
            name: "KvToPyClassVsCodeExtension",
            dependencies: [
                .product(name: "JavaScriptKit", package: "JavaScriptKit"),
                .product(name: "KvParser", package: "SwiftyKvLang"),
                .product(name: "KvToPyClass", package: "KvToPyClass"),
                .product(name: "KivyWidgetRegistry", package: "KvToPyClass"),
                "MonacoApi",
                "MonacoJSK",
                .byName(name: "JavaScriptKitExtensions")
            ],
            swiftSettings: [
                .unsafeFlags(["-Xfrontend", "-disable-availability-checking"])
            ]
        )
    ]
)
