![Swift](https://img.shields.io/badge/Swift-5.7+-orange.svg)
![iOS](https://img.shields.io/badge/iOS-13.0+-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Dependencies](https://img.shields.io/badge/dependencies-none-brightgreen.svg)

# SimpleGoogleSignIn

A lightweight, dependency-free Google Sign-In implementation for iOS in pure Swift.

## Features

✅ **Zero external dependencies** - Uses only iOS system frameworks  
✅ **Modern OAuth 2.0 with PKCE** - Secure authentication flow  
✅ **Token management** - Access, refresh, and ID token handling  
✅ **Simple API** - Easy to integrate and use  
✅ **SwiftUI & UIKit** - Compatible with both frameworks  
✅ **Token refresh** - Built-in refresh token support  

## Requirements

- iOS 13.0+
- Swift 5.7+
- Xcode 14.0+

## Installation

### Swift Package Manager

Add this package to your project:

```swift
dependencies: [
    .package(url: "https://github.com/Choochmeque/SimpleGoogleSignIn.git", from: "1.0.0")
]
```

Or in Xcode:
1. File → Add Package Dependencies
2. Enter the repository URL
3. Select "SimpleGoogleSignIn" library

### Manual Installation

Simply copy `SimpleGoogleSignIn.swift` to your project. No dependencies needed!

## Setup

### 1. Get Google OAuth 2.0 Credentials

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing
3. Enable Google Sign-In API
4. Create OAuth 2.0 credentials (iOS application)
5. Add your bundle ID
6. Copy the Client ID

### 2. Configure URL Scheme

Add to your `Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <!-- Reversed client ID format -->
            <!-- If your client ID is: 123456789-abcdef.apps.googleusercontent.com -->
            <!-- Then your URL scheme is: com.googleusercontent.apps.123456789-abcdef -->
            <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

### 3. Handle URL Callbacks

In your `AppDelegate` or `SceneDelegate`:

```swift
func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    return SimpleGoogleSignIn.shared.handleURL(url)
}
```

## Usage

### Configuration

```swift
import SimpleGoogleSignIn

// Configure on app launch
let configuration = GoogleSignInConfiguration(
    clientID: "YOUR_CLIENT_ID.apps.googleusercontent.com",
    serverClientID: nil, // Optional: for server-side validation
    hostedDomain: nil    // Optional: restrict to specific domain
)
SimpleGoogleSignIn.shared.configure(configuration: configuration)
```

### Sign In

```swift
SimpleGoogleSignIn.shared.signIn(
    presentingViewController: viewController,
    hint: nil, // Optional: pre-fill email address
    scopes: ["openid", "profile", "email"] // Required: OAuth scopes
) { result in
    switch result {
    case .success(let signInResult):
        print("Access Token: \(signInResult.accessToken.tokenString)")
        print("ID Token: \(signInResult.openIdToken ?? "")")
        print("Refresh Token: \(signInResult.refreshToken ?? "")")
        print("Granted Scopes: \(signInResult.grantedScopes ?? [])")
    case .failure(let error):
        print("Sign in failed: \(error)")
    }
}
```

### Sign Out

```swift
// Sign out and optionally revoke access token
SimpleGoogleSignIn.shared.signOut(accessToken: accessTokenString) { error in
    if let error = error {
        print("Sign out failed: \(error)")
    } else {
        print("Successfully signed out")
    }
}

// Or sign out without revoking token
SimpleGoogleSignIn.shared.signOut(accessToken: nil) { error in
    // Local sign out only
}
```

### Token Refresh

```swift
// Refresh tokens using refresh token
SimpleGoogleSignIn.shared.refreshTokens(refreshToken: refreshTokenString) { result in
    switch result {
    case .success(let signInResult):
        print("New Access Token: \(signInResult.accessToken.tokenString)")
        print("Token expires: \(signInResult.accessToken.expirationDate ?? Date())")
        // Note: refreshToken may be the same as the original
    case .failure(let error):
        print("Refresh failed: \(error)")
    }
}
```

### Check Token Expiration

```swift
// GoogleToken provides expiration checking
if accessToken.isExpired {
    // Token has expired, refresh it
}
```

## SwiftUI Example

```swift
import SwiftUI
import SimpleGoogleSignIn

struct ContentView: View {
    @State private var signInResult: GoogleSignInResult?
    @State private var isSigningIn = false
    
    var body: some View {
        VStack(spacing: 20) {
            if let result = signInResult {
                Text("Signed In Successfully")
                Text("Access Token: ...\(String(result.accessToken.tokenString.suffix(10)))")
                
                Button("Sign Out") {
                    SimpleGoogleSignIn.shared.signOut(accessToken: result.accessToken.tokenString) { _ in
                        signInResult = nil
                    }
                }
            } else {
                Button("Sign in with Google") {
                    signIn()
                }
                .disabled(isSigningIn)
            }
        }
        .padding()
    }
    
    private func signIn() {
        isSigningIn = true
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        SimpleGoogleSignIn.shared.signIn(
            presentingViewController: rootViewController,
            hint: nil,
            scopes: ["openid", "profile", "email"]
        ) { result in
            isSigningIn = false
            switch result {
            case .success(let result):
                signInResult = result
            case .failure(let error):
                print("Sign in failed: \(error)")
            }
        }
    }
}
```

## UIKit Example

```swift
import UIKit
import SimpleGoogleSignIn

class SignInViewController: UIViewController {
    private var signInResult: GoogleSignInResult?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureGoogleSignIn()
    }
    
    private func configureGoogleSignIn() {
        let configuration = GoogleSignInConfiguration(
            clientID: "YOUR_CLIENT_ID.apps.googleusercontent.com"
        )
        SimpleGoogleSignIn.shared.configure(configuration: configuration)
    }
    
    @IBAction func signInTapped() {
        SimpleGoogleSignIn.shared.signIn(
            presentingViewController: self,
            hint: nil,
            scopes: ["openid", "profile", "email"]
        ) { result in
            switch result {
            case .success(let result):
                self.signInResult = result
                self.handleSignInSuccess(result)
            case .failure(let error):
                self.showError(error)
            }
        }
    }
    
    private func handleSignInSuccess(_ result: GoogleSignInResult) {
        print("Access Token: \(result.accessToken.tokenString)")
        // Navigate to main app or update UI
    }
    
    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "Sign In Failed",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
```

## Comparison with Official GoogleSignIn

| Feature | SimpleGoogleSignIn | Official GoogleSignIn |
|---------|-------------------|---------------------|
| Dependencies | None | 6+ packages |
| Size | ~570 lines | Thousands of lines |
| Platform | iOS only | iOS, macOS |
| Setup Complexity | Simple | Complex |
| App Attest | ❌ | ✅ |
| EMM Support | ❌ | ✅ |
| Server Auth Code | ✅ | ✅ |
| Token Refresh | ✅ | ✅ |
| PKCE Support | ✅ | ✅ |

## Security Features

- **PKCE** (Proof Key for Code Exchange) for OAuth security
- **State parameter** verification to prevent CSRF attacks
- **Nonce** included in authentication for additional security
- **Token expiration** tracking and validation
- **SSL/TLS** for all network requests
- **ASWebAuthenticationSession** for secure system-level authentication

## Error Handling

```swift
enum GoogleSignInError: LocalizedError {
    case missingConfiguration
    case missingPresentingViewController
    case authenticationFailed(String)
    case invalidResponse
    case userCancelled
    case networkError(Error)
    case missingURLScheme(String)
    
    var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return "Google Sign-In configuration is missing"
        case .missingPresentingViewController:
            return "No presenting view controller available"
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        case .invalidResponse:
            return "Invalid response from Google"
        case .userCancelled:
            return "User cancelled sign-in"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .missingURLScheme(let scheme):
            return "Required URL scheme '\(scheme)' is not configured in Info.plist"
        }
    }
}
```

## License

This simplified implementation is provided as-is for educational and practical use.

## Contributing

Contributions are welcome! Please feel free to submit pull requests.

## Support

For issues or questions, please create an issue in the repository.
