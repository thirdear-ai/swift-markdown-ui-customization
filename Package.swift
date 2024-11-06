// swift-tools-version:5.6

import PackageDescription

let package = Package(
    name: "swift-markdown-ui",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .tvOS(.v15),
        .macCatalyst(.v15),
        .watchOS(.v8),
    ],
    products: [
        .library(
            name: "MarkdownUI",
            targets: ["MarkdownUI"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/gonzalezreal/NetworkImage", from: "6.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.10.0"),
        .package(url: "https://github.com/swiftlang/swift-cmark", from: "0.4.0"),
        .package(url: "https://github.com/colinc86/MathJaxSwift", from: "3.4.0")
        
    ],
    targets: [
        .target(
            name: "SVGCore",
            path: "Sources/SVGCore",
            cSettings: [.headerSearchPath("Sources/SVGCore/include")]
        ),
        .target(
            name: "MarkdownUI",
            dependencies: [
                "SVGCore",
                .product(name: "cmark-gfm", package: "swift-cmark"),
                .product(name: "cmark-gfm-extensions", package: "swift-cmark"),
                .product(name: "NetworkImage", package: "NetworkImage"),
                .product(name: "MathJaxSwift", package: "MathJaxSwift")
            ],
            path: "Sources/MarkdownUI" // Swift 文件所在目录
        ),
        .testTarget(
            name: "MarkdownUITests",
            dependencies: [
                "MarkdownUI",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ],
            exclude: ["__Snapshots__"]
        ),
    ]
)
