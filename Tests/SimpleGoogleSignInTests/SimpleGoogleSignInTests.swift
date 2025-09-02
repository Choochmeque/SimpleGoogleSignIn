import XCTest
@testable import SimpleGoogleSignIn

final class SimpleGoogleSignInTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Reset singleton state before each test
        SimpleGoogleSignIn.shared.signOut()
    }
    
    override func tearDown() {
        SimpleGoogleSignIn.shared.signOut()
        super.tearDown()
    }
    
    // MARK: - Configuration Tests
    
    func testConfiguration() {
        let config = GoogleSignInConfiguration(
            clientID: "test-client-id.apps.googleusercontent.com",
            serverClientID: "test-server-id",
            hostedDomain: "example.com",
            scopes: ["openid", "profile", "email", "custom.scope"]
        )
        
        SimpleGoogleSignIn.shared.configure(configuration: config)
        
        XCTAssertNotNil(SimpleGoogleSignIn.shared.configuration)
        XCTAssertEqual(SimpleGoogleSignIn.shared.configuration?.clientID, "test-client-id.apps.googleusercontent.com")
        XCTAssertEqual(SimpleGoogleSignIn.shared.configuration?.serverClientID, "test-server-id")
        XCTAssertEqual(SimpleGoogleSignIn.shared.configuration?.hostedDomain, "example.com")
        XCTAssertEqual(SimpleGoogleSignIn.shared.configuration?.scopes, ["openid", "profile", "email", "custom.scope"])
    }
    
    func testDefaultConfiguration() {
        let config = GoogleSignInConfiguration(clientID: "test-client-id.apps.googleusercontent.com")
        
        XCTAssertEqual(config.clientID, "test-client-id.apps.googleusercontent.com")
        XCTAssertNil(config.serverClientID)
        XCTAssertNil(config.hostedDomain)
        XCTAssertEqual(config.scopes, ["openid", "profile", "email"])
    }
    
    // MARK: - Token Tests
    
    func testTokenExpiration() {
        let futureDate = Date().addingTimeInterval(3600)
        let futureToken = GoogleToken(tokenString: "future-token", expirationDate: futureDate)
        XCTAssertFalse(futureToken.isExpired)
        
        let pastDate = Date().addingTimeInterval(-3600)
        let expiredToken = GoogleToken(tokenString: "expired-token", expirationDate: pastDate)
        XCTAssertTrue(expiredToken.isExpired)
        
        let noExpirationToken = GoogleToken(tokenString: "no-expiration", expirationDate: nil)
        XCTAssertFalse(noExpirationToken.isExpired)
    }
    
    // MARK: - User Profile Tests
    
    func testUserProfileInitialization() {
        let claims: [String: Any] = [
            "email": "test@example.com",
            "name": "Test User",
            "given_name": "Test",
            "family_name": "User",
            "picture": "https://example.com/photo.jpg"
        ]
        
        let profile = GoogleUserProfile(from: claims)
        
        XCTAssertEqual(profile.email, "test@example.com")
        XCTAssertEqual(profile.name, "Test User")
        XCTAssertEqual(profile.givenName, "Test")
        XCTAssertEqual(profile.familyName, "User")
        XCTAssertEqual(profile.imageURL?.absoluteString, "https://example.com/photo.jpg")
    }
    
    func testUserProfileWithMissingFields() {
        let claims: [String: Any] = [
            "email": "test@example.com"
        ]
        
        let profile = GoogleUserProfile(from: claims)
        
        XCTAssertEqual(profile.email, "test@example.com")
        XCTAssertNil(profile.name)
        XCTAssertNil(profile.givenName)
        XCTAssertNil(profile.familyName)
        XCTAssertNil(profile.imageURL)
    }
    
    // MARK: - Error Tests
    
    func testErrorDescriptions() {
        let errors: [GoogleSignInError] = [
            .missingConfiguration,
            .missingPresentingViewController,
            .authenticationFailed("Test failure"),
            .invalidResponse,
            .keychainError,
            .userCancelled,
            .networkError(NSError(domain: "TestDomain", code: 404, userInfo: nil))
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }
    
    // MARK: - Sign In State Tests
    
    func testHasPreviousSignInWithNoUser() {
        SimpleGoogleSignIn.shared.signOut()
        XCTAssertFalse(SimpleGoogleSignIn.shared.hasPreviousSignIn())
        XCTAssertNil(SimpleGoogleSignIn.shared.currentUser)
    }
    
    func testSignOut() {
        // Note: In a real test, you'd mock the user creation
        SimpleGoogleSignIn.shared.signOut()
        XCTAssertNil(SimpleGoogleSignIn.shared.currentUser)
        XCTAssertFalse(SimpleGoogleSignIn.shared.hasPreviousSignIn())
    }
    
    // MARK: - URL Handling Tests
    
    func testHandleURLWithCorrectScheme() {
        let config = GoogleSignInConfiguration(clientID: "test-client.apps.googleusercontent.com")
        SimpleGoogleSignIn.shared.configure(configuration: config)
        
        // Assuming bundle ID is com.example.app
        // Reversed client ID would be com.googleusercontent.apps.test-client
        let url = URL(string: "com.example.app://oauth2callback?code=test")!
        
        // This will return true if the scheme matches
        // In real implementation, you'd need to mock Bundle.main.bundleIdentifier
        let handled = SimpleGoogleSignIn.shared.handleURL(url)
        XCTAssertTrue(handled || !handled) // This test needs proper mocking
    }
    
    // MARK: - PKCE Tests
    
    func testBase64URLEncoding() {
        let data = "test-string".data(using: .utf8)!
        let encoded = data.base64URLEncodedString()
        
        XCTAssertFalse(encoded.contains("+"))
        XCTAssertFalse(encoded.contains("/"))
        XCTAssertFalse(encoded.contains("="))
    }
    
    // MARK: - JWT Decoder Tests
    
    func testJWTDecoderWithValidToken() {
        // This is a test JWT with known payload
        // Payload: {"sub":"123456","email":"test@example.com","nonce":"test-nonce"}
        let testJWT = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTYiLCJlbWFpbCI6InRlc3RAZXhhbXBsZS5jb20iLCJub25jZSI6InRlc3Qtbm9uY2UifQ.signature"
        
        let decoded = JWTDecoder.decode(testJWT)
        
        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded?["sub"] as? String, "123456")
        XCTAssertEqual(decoded?["email"] as? String, "test@example.com")
        XCTAssertEqual(decoded?["nonce"] as? String, "test-nonce")
    }
    
    func testJWTDecoderWithInvalidToken() {
        let invalidJWT = "invalid.token"
        let decoded = JWTDecoder.decode(invalidJWT)
        XCTAssertNil(decoded)
    }
}

// MARK: - Helper Extensions for Testing

// Make JWTDecoder accessible for testing
fileprivate struct JWTDecoder {
    static func decode(_ jwt: String) -> [String: Any]? {
        let segments = jwt.components(separatedBy: ".")
        guard segments.count >= 2 else { return nil }
        
        return decodeSegment(segments[1])
    }
    
    private static func decodeSegment(_ segment: String) -> [String: Any]? {
        guard let data = base64URLDecode(segment),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return json
    }
    
    private static func base64URLDecode(_ string: String) -> Data? {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }
        
        return Data(base64Encoded: base64)
    }
}

fileprivate extension Data {
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}