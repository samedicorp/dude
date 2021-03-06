// swift-tools-version:5.2

// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 05/05/2021.
//  All code (c) 2021 - present day, Elegant Chaos.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import PackageDescription

let package = Package(
    name: "Indexer",
    platforms: [
        .macOS(.v10_13)
    ],
    products: [
        .executable(
            name: "indexer",
            targets: ["Indexer"]),
    ],
    dependencies: [
        .package(url: "https://github.com/samedicorp/duswift.git", from: "1.0.0"),
        .package(url: "https://github.com/elegantchaos/ElegantStrings.git", from: "1.0.0"),
        .package(url: "https://github.com/elegantchaos/XCTestExtensions.git", from: "1.3.1")
    ],
    targets: [
        .target(
            name: "Indexer",
            dependencies: ["duswift", "ElegantStrings"]),
        .testTarget(
            name: "IndexerTests",
            dependencies: ["Indexer", "XCTestExtensions"]),
    ]
)
