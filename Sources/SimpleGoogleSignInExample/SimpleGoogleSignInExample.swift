import UIKit
import SwiftUI

// MARK: - SwiftUI Implementation Example

struct ContentView: View {
    @StateObject private var authViewModel = AuthenticationViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            if let user = authViewModel.currentUser {
                // Signed In View
                VStack(spacing: 15) {
                    if let imageURL = user.profile.imageURL {
                        AsyncImage(url: imageURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.gray)
                        }
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                    }
                    
                    Text("Welcome, \(user.profile.name ?? "User")!")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    if let email = user.profile.email {
                        Text(email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("User ID: \(user.userID)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 10) {
                        Button("Sign Out") {
                            authViewModel.signOut()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Disconnect", role: .destructive) {
                            authViewModel.disconnect()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }
                    .padding(.top)
                }
                .padding()
                
            } else {
                // Sign In View
                VStack(spacing: 20) {
                    Image(systemName: "person.circle")
                        .font(.system(size: 100))
                        .foregroundColor(.blue)
                    
                    Text("Sign in with Google")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Access your Google account")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    GoogleSignInButton {
                        authViewModel.signIn()
                    }
                    .frame(width: 280, height: 50)
                    
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                    
                    if let error = authViewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .padding()
            }
        }
        .onAppear {
            authViewModel.checkPreviousSignIn()
        }
    }
}

// MARK: - Custom Google Sign-In Button

struct GoogleSignInButton: UIViewRepresentable {
    let action: () -> Void
    
    func makeUIView(context: Context) -> UIButton {
        let button = UIButton(type: .system)
        
        // Configure button appearance
        button.backgroundColor = .white
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemGray4.cgColor
        
        // Add shadow
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.layer.shadowOpacity = 0.1
        button.layer.shadowRadius = 2
        
        // Configure title and image
        let googleImage = UIImage(systemName: "globe")?.withRenderingMode(.alwaysOriginal).withTintColor(.systemBlue)
        button.setImage(googleImage, for: .normal)
        button.setTitle("  Sign in with Google", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        
        // Add action
        button.addTarget(context.coordinator, action: #selector(Coordinator.buttonTapped), for: .touchUpInside)
        
        return button
    }
    
    func updateUIView(_ uiView: UIButton, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }
    
    class Coordinator: NSObject {
        let action: () -> Void
        
        init(action: @escaping () -> Void) {
            self.action = action
        }
        
        @objc func buttonTapped() {
            action()
        }
    }
}

// MARK: - View Model

class AuthenticationViewModel: ObservableObject {
    @Published var currentUser: GoogleUser?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        // Configure Google Sign-In on initialization
        // Replace with your actual Google OAuth client ID
        let configuration = GoogleSignInConfiguration(
            clientID: "YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com"
        )
        SimpleGoogleSignIn.shared.configure(configuration: configuration)
        
        // Check current user
        currentUser = SimpleGoogleSignIn.shared.currentUser
    }
    
    func checkPreviousSignIn() {
        guard SimpleGoogleSignIn.shared.hasPreviousSignIn() else { return }
        
        isLoading = true
        errorMessage = nil
        
        SimpleGoogleSignIn.shared.restorePreviousSignIn { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let user):
                    self?.currentUser = user
                    
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func signIn() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            errorMessage = "Unable to get root view controller"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        SimpleGoogleSignIn.shared.signIn(presentingViewController: rootViewController) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let signInResult):
                    self?.currentUser = signInResult.user
                    self?.errorMessage = nil
                    
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func signOut() {
        SimpleGoogleSignIn.shared.signOut()
        currentUser = nil
        errorMessage = nil
    }
    
    func disconnect() {
        isLoading = true
        
        SimpleGoogleSignIn.shared.disconnect { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                } else {
                    self?.currentUser = nil
                }
            }
        }
    }
}

// MARK: - UIKit Implementation Example

class SignInViewController: UIViewController {
    
    // UI Elements
    private let logoImageView = UIImageView()
    private let titleLabel = UILabel()
    private let signInButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let statusLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureGoogleSignIn()
        checkPreviousSignIn()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Logo
        logoImageView.image = UIImage(systemName: "person.circle.fill")
        logoImageView.tintColor = .systemBlue
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Title
        titleLabel.text = "Welcome"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Sign In Button
        signInButton.setTitle("Sign in with Google", for: .normal)
        signInButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        signInButton.backgroundColor = .systemBlue
        signInButton.setTitleColor(.white, for: .normal)
        signInButton.layer.cornerRadius = 8
        signInButton.addTarget(self, action: #selector(signInTapped), for: .touchUpInside)
        signInButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Activity Indicator
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        // Status Label
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.font = .systemFont(ofSize: 14)
        statusLabel.textColor = .secondaryLabel
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Add subviews
        view.addSubview(logoImageView)
        view.addSubview(titleLabel)
        view.addSubview(signInButton)
        view.addSubview(activityIndicator)
        view.addSubview(statusLabel)
        
        // Constraints
        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
            logoImageView.widthAnchor.constraint(equalToConstant: 100),
            logoImageView.heightAnchor.constraint(equalToConstant: 100),
            
            titleLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            signInButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            signInButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            signInButton.widthAnchor.constraint(equalToConstant: 250),
            signInButton.heightAnchor.constraint(equalToConstant: 50),
            
            activityIndicator.topAnchor.constraint(equalTo: signInButton.bottomAnchor, constant: 20),
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            statusLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 20),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
    }
    
    private func configureGoogleSignIn() {
        // Configure with your Google OAuth client ID
        let configuration = GoogleSignInConfiguration(
            clientID: "YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com",
            scopes: ["openid", "profile", "email"]
        )
        SimpleGoogleSignIn.shared.configure(configuration: configuration)
    }
    
    private func checkPreviousSignIn() {
        guard SimpleGoogleSignIn.shared.hasPreviousSignIn() else { return }
        
        activityIndicator.startAnimating()
        signInButton.isEnabled = false
        
        SimpleGoogleSignIn.shared.restorePreviousSignIn { [weak self] result in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                self?.signInButton.isEnabled = true
                
                switch result {
                case .success(let user):
                    self?.handleSignInSuccess(user)
                    
                case .failure(let error):
                    self?.statusLabel.text = "Restore failed: \(error.localizedDescription)"
                    self?.statusLabel.textColor = .systemRed
                }
            }
        }
    }
    
    @objc private func signInTapped() {
        activityIndicator.startAnimating()
        signInButton.isEnabled = false
        statusLabel.text = ""
        
        SimpleGoogleSignIn.shared.signIn(presentingViewController: self) { [weak self] result in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                self?.signInButton.isEnabled = true
                
                switch result {
                case .success(let signInResult):
                    self?.handleSignInSuccess(signInResult.user)
                    
                case .failure(let error):
                    self?.statusLabel.text = "Sign in failed: \(error.localizedDescription)"
                    self?.statusLabel.textColor = .systemRed
                }
            }
        }
    }
    
    private func handleSignInSuccess(_ user: GoogleUser) {
        titleLabel.text = "Welcome, \(user.profile.name ?? "User")!"
        statusLabel.text = """
            Email: \(user.profile.email ?? "N/A")
            User ID: \(user.userID)
            """
        statusLabel.textColor = .label
        
        signInButton.setTitle("Sign Out", for: .normal)
        signInButton.removeTarget(self, action: #selector(signInTapped), for: .touchUpInside)
        signInButton.addTarget(self, action: #selector(signOutTapped), for: .touchUpInside)
        
        // Load profile image if available
        if let imageURL = user.profile.imageURL {
            loadProfileImage(from: imageURL)
        }
    }
    
    @objc private func signOutTapped() {
        SimpleGoogleSignIn.shared.signOut()
        
        // Reset UI
        titleLabel.text = "Welcome"
        statusLabel.text = "Signed out successfully"
        statusLabel.textColor = .systemGreen
        logoImageView.image = UIImage(systemName: "person.circle.fill")
        
        signInButton.setTitle("Sign in with Google", for: .normal)
        signInButton.removeTarget(self, action: #selector(signOutTapped), for: .touchUpInside)
        signInButton.addTarget(self, action: #selector(signInTapped), for: .touchUpInside)
    }
    
    private func loadProfileImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data, let image = UIImage(data: data) else { return }
            
            DispatchQueue.main.async {
                self?.logoImageView.image = image
                self?.logoImageView.layer.cornerRadius = 50
                self?.logoImageView.clipsToBounds = true
            }
        }.resume()
    }
}

// MARK: - App Delegate Setup

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Configure Google Sign-In
        let configuration = GoogleSignInConfiguration(
            clientID: "YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com"
        )
        SimpleGoogleSignIn.shared.configure(configuration: configuration)
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return SimpleGoogleSignIn.shared.handleURL(url)
    }
}

// MARK: - Usage Instructions

/*
 SETUP INSTRUCTIONS:
 
 1. Get your Google OAuth 2.0 Client ID:
    - Go to https://console.cloud.google.com/
    - Create a new project or select existing
    - Enable Google Sign-In API
    - Create OAuth 2.0 credentials (iOS application)
    - Add your bundle ID
    - Copy the Client ID
 
 2. Configure URL Scheme:
    - In Xcode, select your project
    - Go to Info tab
    - Add URL Types
    - Set URL Schemes to your reversed client ID
      Example: If your client ID is "123456789-abcdef.apps.googleusercontent.com"
      Then your URL scheme is: "com.googleusercontent.apps.123456789-abcdef"
 
 3. Update Info.plist:
    - Add CFBundleURLTypes if not exists
    - Add your reversed client ID as URL scheme
 
 4. Replace "YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com" with your actual Client ID
 
 5. Import the SimpleGoogleSignIn.swift file into your project
 
 6. Use either the SwiftUI ContentView or UIKit SignInViewController
 
 FEATURES:
 - Simple OAuth 2.0 sign-in flow
 - PKCE (Proof Key for Code Exchange) for security
 - Token refresh functionality
 - Keychain storage for persistence
 - User profile information
 - Sign out and disconnect functionality
 - Error handling
 - SwiftUI and UIKit examples
 
 LIMITATIONS:
 - iOS only (no macOS support in this simplified version)
 - Basic scopes only (can be extended)
 - No server auth code support (can be added if needed)
 - No additional scope requests after initial sign-in
 */