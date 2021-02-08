// swift-tools-version:5.3
// s.name         = "MoyaPromise"
// s.version      = "1.0.0"
// s.summary      = "PromiseKit-oriented 'DataService' layer on top of Moya"
// s.description  = <<-DESC
//    A 'DataService' layer implemented with PromiseKit on the top of Moya with extra functionalities using the power of Promis
// DESC
//  s.homepage     = "https://github.com/Can-Sahin/MoyaPromise"
//  s.license = { :type => "MIT", :file => "LICENSE" }
//  s.author             = { "Can-Sahin" => "cann2005@gmail.com" }
//  s.swift_version = "4.0"
//  s.source       = { :git => "https://github.com/Can-Sahin/MoyaPromise.git", :tag => "#{s.version}" }
//  s.source_files  = 'src/MoyaPromise/*.swift'


import PackageDescription

let package = Package(
    name: "MoyaPromise",
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