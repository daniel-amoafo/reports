// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BudgetSystemService",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "BudgetSystemService",
            targets: ["BudgetSystemService"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: "https://github.com/andrebocchini/swiftynab", from: "2.1.0"),
        .package(url: "https://github.com/daniel-amoafo/swiftynab/", branch: "fix-api-errors"),
        .package(url: "https://github.com/pointfreeco/swift-identified-collections", from: "1.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-concurrency-extras", from: "1.1.0"),
        .package(path: "../MoneyCommon"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "BudgetSystemService",
            dependencies: [
                .product(name: "SwiftYNAB", package: "swiftynab"),
                .product(name: "IdentifiedCollections", package: "swift-identified-collections"),
                .product(name: "MoneyCommon", package: "MoneyCommon"),
            ]),
        .testTarget(
            name: "BudgetSystemServiceTests",
            dependencies: [
                "BudgetSystemService",
                .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras"),
            ]),
    ]
)
