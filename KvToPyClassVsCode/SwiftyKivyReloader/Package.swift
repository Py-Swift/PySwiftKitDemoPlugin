// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription



let package_dependencies: [Package.Dependency] = [
    .package(url: "https://github.com/py-swift/PySwiftKit", from: .init(313, 0, 0)),
    .package(url: "https://github.com/py-swift/PyFileGenerator", from: .init(0, 0, 1)),
    // add other packages
    .package(url: "https://github.com/kivy-school/KivyLauncher", branch: "master")
]



let package_targets: [Target] = [
    .target(
        name: "SwiftyKivyReloader",
        dependencies: [
            .product(name: "PySwiftKitBase", package: "PySwiftKit"),
            // add other package products or internal targets
            .product(name: "KivyLauncher", package: "KivyLauncher")
        ],
        resources: [

        ]
    ),
    .executableTarget(
        name: "SwiftyKivyAppLoader",
        dependencies: [
            
        ]
    )
]



let package = Package(
    name: "SwiftyKivyReloader",
    platforms: [
        .iOS(.v13),
        .macOS(.v11)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftyKivyReloader",
            targets: ["SwiftyKivyReloader"]
        ),
        .executable(
            name: "SwiftyKivyAppLoader",
            targets: ["SwiftyKivyAppLoader"]
        )
    ],
    dependencies: package_dependencies,
    targets: package_targets
)
