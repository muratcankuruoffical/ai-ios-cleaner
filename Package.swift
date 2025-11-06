// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// This Package.swift file is provided as a reference for SPM dependencies.
// When opening this project in Xcode, you should add these packages via:
// File > Add Package Dependencies...
//

import PackageDescription

let package = Package(
    name: "AI Cleaner",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "AI Cleaner",
            targets: ["AI Cleaner"]
        )
    ],
    dependencies: [
        // RevenueCat SDK for subscription management
        .package(
            url: "https://github.com/RevenueCat/purchases-ios.git",
            from: "4.31.0"
        ),

        // Firebase SDK for Analytics and Crashlytics
        .package(
            url: "https://github.com/firebase/firebase-ios-sdk.git",
            from: "10.19.0"
        )
    ],
    targets: [
        .target(
            name: "AI Cleaner",
            dependencies: [
                .product(name: "RevenueCat", package: "purchases-ios"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseCrashlytics", package: "firebase-ios-sdk")
            ]
        )
    ]
)
