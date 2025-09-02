// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SimpleGoogleSignIn",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        // Main library product
        .library(
            name: "SimpleGoogleSignIn",
            targets: ["SimpleGoogleSignIn"]
        ),
        // Optional example app product
        .library(
            name: "SimpleGoogleSignInExample",
            targets: ["SimpleGoogleSignInExample"]
        )
    ],
    dependencies: [ ],
    targets: [
        // Main library target
        .target(
            name: "SimpleGoogleSignIn",
            dependencies: [],
            path: "Sources/SimpleGoogleSignIn",
            sources: ["SimpleGoogleSignIn.swift"],
            resources: [
                .process("Resources/PrivacyInfo.xcprivacy")
            ]
        ),
        
        // Example implementation target
        .target(
            name: "SimpleGoogleSignInExample",
            dependencies: ["SimpleGoogleSignIn"],
            path: "Sources/SimpleGoogleSignInExample",
            sources: ["SimpleGoogleSignInExample.swift"]
        ),
        
        // Test target
        .testTarget(
            name: "SimpleGoogleSignInTests",
            dependencies: ["SimpleGoogleSignIn"],
            path: "Tests/SimpleGoogleSignInTests"
        )
    ],
    swiftLanguageVersions: [.v5]
)

// MARK: - Package Structure
/*
 Recommended directory structure for this package:
 
 SimpleGoogleSignIn/
 ├── Package.swift
 ├── README.md
 ├── LICENSE
 ├── Sources/
 │   ├── SimpleGoogleSignIn/
 │   │   ├── SimpleGoogleSignIn.swift
 │   │   └── Resources/
 │   │       └── PrivacyInfo.xcprivacy
 │   └── SimpleGoogleSignInExample/
 │       └── SimpleGoogleSignInExample.swift
 └── Tests/
     └── SimpleGoogleSignInTests/
         └── SimpleGoogleSignInTests.swift
*/

// MARK: - Integration Instructions
/*
 HOW TO USE THIS PACKAGE:
 
 1. Swift Package Manager (Xcode):
    - File > Add Package Dependencies
    - Enter your repository URL
    - Select "SimpleGoogleSignIn" library
 
 2. Swift Package Manager (Package.swift):
    ```swift
    dependencies: [
        .package(url: "https://github.com/yourusername/SimpleGoogleSignIn.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "YourApp",
            dependencies: ["SimpleGoogleSignIn"]
        )
    ]
    ```
 
 3. CocoaPods (if you create a podspec):
    ```ruby
    pod 'SimpleGoogleSignIn', '~> 1.0'
    ```
 
 4. Manual Integration:
    - Simply copy SimpleGoogleSignIn.swift to your project
    - No additional dependencies needed!
*/

// MARK: - Comparison with Original GoogleSignIn
/*
 SIMPLIFIED VS ORIGINAL:
 
 Original GoogleSignIn Package Dependencies:
 - AppAuth-iOS (OpenID/OAuth library)
 - AppCheck (App attestation)
 - GTMAppAuth (Google Toolbox auth)
 - GTMSessionFetcher (Network fetching)
 - GoogleUtilities (Various utilities)
 - OCMock (Testing framework)
 
 SimpleGoogleSignIn Dependencies:
 - NONE! Uses only iOS system frameworks
 
 Benefits:
 ✅ Zero external dependencies
 ✅ Smaller app size (no dependency bloat)
 ✅ Faster build times
 ✅ Easier to understand and maintain
 ✅ No version conflicts with other packages
 ✅ Full control over the implementation
 
 Trade-offs:
 ⚠️ iOS only (no macOS support)
 ⚠️ Basic features only (can be extended as needed)
 ⚠️ No enterprise features (EMM, App Attest)
 ⚠️ Manual token refresh (no automatic background refresh)
*/