// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "XcaTutor",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "XcaTutor", targets: ["XcaTutor"])
    ],
    dependencies: [
        // SQLite 封装
        .package(url: "https://github.com/ccgus/fmdb.git", from: "2.7.0"),
    ],
    targets: [
        .executableTarget(
            name: "XcaTutor",
            dependencies: [
                .product(name: "FMDB", package: "fmdb")
            ],
            path: "XcaTutor",
            exclude: ["Info.plist", "Assets.xcassets"]
        ),
        .testTarget(
            name: "XcaTutorTests",
            dependencies: ["XcaTutor"],
            path: "XcaTutorTests"
        )
    ]
)
