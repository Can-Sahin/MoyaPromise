// swift-tools-version:5.3


import PackageDescription

let package = Package(
    name: "MoyaPromise",
    version: "1.0.0",
    summary: "PromiseKit-oriented 'DataService' layer on top of Moya",
    description: "A 'DataService' layer implemented with PromiseKit on the top of Moya with extra functionalities using the power of Promise",
    homepage: "https://github.com/Alamofire/Alamofire.git",
    license: "MIT",
    author: "Can-Sahin <cann2005@gmail.com>",
    source_files: "src/MoyaPromise/*.swift",
    platforms: [
        .iOS(.v8)
    ],
    products: [
        .library(
            name: "MoyaPromise", 
            targets: ["MoyaPromise"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "4.7.0"),
        .package(url: "https://github.com/PromiseKit/PMKAlamofire.git", from: "6.0.0"),
        .package(url: "https://github.com/mxcl/PromiseKit", from: "6.2.1"),
        .package(url: "https://github.com/Moya/Moya.git", from: "11.0.1")
    ],
    targets: [
        .target(name: "MoyaPromise"),
        .testTarget(name: "MoyaPromiseTests", dependencies: ["MoyaPromise"])
    ]
)