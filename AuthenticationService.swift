//
//  AuthenticationService.swift
//  CalTrackPro
//
//  Handles user authentication with Sign in with Apple and Firebase
//

import Foundation
import AuthenticationServices
import CryptoKit

// MARK: - User Model
struct AppUser: Codable, Identifiable {
    let id: String
    var email: String?
    var displayName: String?
    var photoURL: String?
    var createdAt: Date
    var lastLoginAt: Date
    
    // User profile data
    var targetCalories: Int?
    var targetProtein: Double?
    var targetCarbs: Double?
    var targetFat: Double?
}

// MARK: - Auth State
enum AuthState {
    case unknown
    case authenticated(AppUser)
    case unauthenticated
}

// MARK: - Auth Error
enum AuthError: Error, LocalizedError {
    case signInFailed(String)
    case signOutFailed
    case tokenError
    case userNotFound
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .signInFailed(let message):
            return "Sign in failed: \(message)"
        case .signOutFailed:
            return "Failed to sign out"
        case .tokenError:
            return "Authentication token error"
        case .userNotFound:
            return "User not found"
        case .networkError:
            return "Network connection error"
        }
    }
}

// MARK: - Authentication Service
@MainActor
class AuthenticationService: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var authState: AuthState = .unknown
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private var currentNonce: String?
    
    // Keychain keys
    private let userIDKey = "com.caltrackpro.userID"
    private let userDataKey = "com.caltrackpro.userData"
    
    // MARK: - Initialization
    override init() {
        super.init()
        checkExistingAuth()
    }
    
    // MARK: - Check Existing Authentication
    private func checkExistingAuth() {
        // Check if user is already signed in
        if let userData = UserDefaults.standard.data(forKey: userDataKey),
           let user = try? JSONDecoder().decode(AppUser.self, from: userData) {
            authState = .authenticated(user)
        } else {
            authState = .unauthenticated
        }
    }
    
    // MARK: - Sign in with Apple
    func signInWithApple() -> ASAuthorizationAppleIDRequest {
        let nonce = randomNonceString()
        currentNonce = nonce
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        return request
    }
    
    func handleAppleSignIn(result: Result<ASAuthorization, Error>) async {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = "Invalid credential type"
                return
            }
            
            let userID = appleIDCredential.user
            let email = appleIDCredential.email
            let fullName = appleIDCredential.fullName
            
            // Build display name
            var displayName: String?
            if let givenName = fullName?.givenName {
                displayName = givenName
                if let familyName = fullName?.familyName {
                    displayName = "\(givenName) \(familyName)"
                }
            }
            
            // Create user
            let user = AppUser(
                id: userID,
                email: email,
                displayName: displayName,
                photoURL: nil,
                createdAt: Date(),
                lastLoginAt: Date()
            )
            
            // Save user data
            saveUser(user)
            authState = .authenticated(user)
            
            // Optional: Send to backend for server-side user creation
            await syncUserToBackend(user, identityToken: appleIDCredential.identityToken)
            
        case .failure(let error):
            if let authError = error as? ASAuthorizationError,
               authError.code == .canceled {
                // User canceled - not an error
                return
            }
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Sign Out
    func signOut() {
        UserDefaults.standard.removeObject(forKey: userDataKey)
        UserDefaults.standard.removeObject(forKey: userIDKey)
        authState = .unauthenticated
    }

    // MARK: - Delete Account
    /// Permanently deletes the user's account and all associated data
    /// Required for App Store compliance (Guideline 5.1.1(v))
    func deleteAccount() async throws {
        guard let user = currentUser else {
            throw AuthError.userNotFound
        }

        isLoading = true
        defer { isLoading = false }

        // 1. Revoke Apple Sign In credentials if possible
        // Note: Apple doesn't provide a direct API to revoke credentials
        // The user must do this in their Apple ID settings

        // 2. Delete user data from backend (if you have one)
        // await deleteUserFromBackend(user.id)

        // 3. Clear all local user data
        clearAllUserData()

        // 4. Sign out
        authState = .unauthenticated
    }

    /// Clears all local user data
    private func clearAllUserData() {
        // Remove authentication data
        UserDefaults.standard.removeObject(forKey: userDataKey)
        UserDefaults.standard.removeObject(forKey: userIDKey)

        // Clear all app-specific user defaults
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()

        // Note: SwiftData persistence will be cleared separately in the view layer
    }
    
    // MARK: - User Management
    private func saveUser(_ user: AppUser) {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: userDataKey)
            UserDefaults.standard.set(user.id, forKey: userIDKey)
        }
    }
    
    func updateUser(_ user: AppUser) {
        saveUser(user)
        authState = .authenticated(user)
    }
    
    var currentUser: AppUser? {
        if case .authenticated(let user) = authState {
            return user
        }
        return nil
    }
    
    // MARK: - Backend Sync (Optional - integrate with your backend)
    private func syncUserToBackend(_ user: AppUser, identityToken: Data?) async {
        // Implement your backend API call here
        // Example with Firebase or custom backend:
        /*
        guard let token = identityToken,
              let tokenString = String(data: token, encoding: .utf8) else {
            return
        }
        
        let url = URL(string: "https://your-api.com/auth/apple")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "identityToken": tokenString,
            "userId": user.id,
            "email": user.email ?? "",
            "displayName": user.displayName ?? ""
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            // Handle response
        } catch {
            print("Backend sync failed: \(error)")
        }
        */
    }
    
    // MARK: - Credential State Check
    func checkCredentialState() async {
        guard let userID = UserDefaults.standard.string(forKey: userIDKey) else {
            authState = .unauthenticated
            return
        }
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        
        do {
            let state = try await appleIDProvider.credentialState(forUserID: userID)
            
            await MainActor.run {
                switch state {
                case .authorized:
                    // Credentials still valid
                    break
                case .revoked, .notFound:
                    // Sign out user
                    signOut()
                case .transferred:
                    // Handle account transfer
                    break
                @unknown default:
                    break
                }
            }
        } catch {
            print("Credential state check failed: \(error)")
        }
    }
    
    // MARK: - Nonce Generation (for security)
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce")
        }
        
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        
        return String(randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        })
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Sign in with Apple Button View
import SwiftUI

struct SignInWithAppleButtonView: View {
    @EnvironmentObject var authService: AuthenticationService
    
    var body: some View {
        SignInWithAppleButton(.signIn) { request in
            let appleRequest = authService.signInWithApple()
            request.requestedScopes = appleRequest.requestedScopes
            request.nonce = appleRequest.nonce
        } onCompletion: { result in
            Task {
                await authService.handleAppleSignIn(result: result)
            }
        }
        .signInWithAppleButtonStyle(.black)
        .frame(height: 50)
        .cornerRadius(10)
    }
}

// MARK: - Auth State View Modifier
struct AuthenticatedViewModifier: ViewModifier {
    @EnvironmentObject var authService: AuthenticationService
    let unauthenticatedView: AnyView
    
    func body(content: Content) -> some View {
        Group {
            switch authService.authState {
            case .unknown:
                ProgressView()
            case .authenticated:
                content
            case .unauthenticated:
                unauthenticatedView
            }
        }
    }
}

extension View {
    func requiresAuthentication<Unauthenticated: View>(
        @ViewBuilder unauthenticated: () -> Unauthenticated
    ) -> some View {
        modifier(AuthenticatedViewModifier(unauthenticatedView: AnyView(unauthenticated())))
    }
}
