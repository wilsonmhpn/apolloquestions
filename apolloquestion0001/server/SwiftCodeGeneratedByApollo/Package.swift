// swift-tools-version:5.7

import PackageDescription

let package = Package(
  name: "SwiftCodeGeneratedByApollo",
  platforms: [
    .iOS(.v12),
    .macOS(.v10_14),
    .tvOS(.v12),
    .watchOS(.v5),
  ],
  products: [
    .library(name: "SwiftCodeGeneratedByApollo", targets: ["SwiftCodeGeneratedByApollo"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apollographql/apollo-ios.git", from: "1.0.0"),
  ],
  targets: [
    .target(
      name: "SwiftCodeGeneratedByApollo",
      dependencies: [
        .product(name: "ApolloAPI", package: "apollo-ios"),
      ],
      path: "./Sources"
    ),
  ]
)
