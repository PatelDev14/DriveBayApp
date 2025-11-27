
import Foundation
import UIKit
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices
import GoogleSignIn
import GoogleSignInSwift
import Combine
import CryptoKit
import FirebaseCore

// MARK: - AuthService

class AuthService: ObservableObject {
    
    // @Published var isLoggedIn is correctly initialized and observed in init()
    @Published var isLoggedIn: Bool = Auth.auth().currentUser != nil
    
    // Nonce storage for Sign In with Apple security
    private var currentNonce: String?
    
    init() {
        // ⭐️ BEST PRACTICE: Auth State Listener is the single source of truth for isLoggedIn ⭐️
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                //self.isLoggedIn = true
                self?.isLoggedIn = user != nil
            }
        }
    }
    
    // MARK: - Email and Password
    
    func signUp(email: String, password: String) async throws {
        let _ = try await Auth.auth().createUser(withEmail: email, password: password)
    }
    
    func signIn(email: String, password: String) async throws {
        let _ = try await Auth.auth().signIn(withEmail: email, password: password)
    }
    
    func signOut() throws {
        // Sign out of Google session first
        GIDSignIn.sharedInstance.signOut()
        // Then sign out of Firebase (which triggers the listener and updates isLoggedIn)
        try Auth.auth().signOut()
    }

    func sendPasswordReset(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
    
    // ❌ REMOVED: handleSuccessfulSignIn(user: User). The init() listener handles this automatically and reliably. ❌
    
    // --- MARK: Social Sign In Implementations ---
    
    // MARK: - Sign in with Apple
        
    func signInWithApple() async throws {
        let nonce = randomNonceString()
        currentNonce = nonce
        let hashedNonce = sha256(nonce)
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = hashedNonce
        
        let delegateHandler = ASDelegateHandler()
        let appleCredential = try await delegateHandler.performSignInWithAppleRequest(request: request)
        
        guard let appleIDToken = appleCredential.identityToken else {
            throw AuthError.general("Apple ID Token missing from credential.")
        }
        guard let tokenString = String(data: appleIDToken, encoding: .utf8) else {
            throw AuthError.general("Token string conversion failed.")
        }
        
        let firebaseCredential = OAuthProvider.appleCredential(
            withIDToken: tokenString,
            rawNonce: nonce,
            fullName: appleCredential.fullName
        )
        
        let _ = try await Auth.auth().signIn(with: firebaseCredential)
        currentNonce = nil
    }
        
    // MARK: - Sign in with Google 🌐
        
    func signInWithGoogle() async throws {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AuthError.general("Google Client ID not found. Check GoogleService-Info.plist setup.")
        }
        
        // Find the root view controller safely
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            throw AuthError.general("Unable to find application root view controller.")
        }
        
        // ⭐️ Standard Sign-In API with presenting view controller ⭐️
        let signInResult = try await GIDSignIn.sharedInstance.signIn(
            withPresenting: rootVC
        )
        
        let user = signInResult.user
        
        guard let idToken = user.idToken?.tokenString else {
            throw AuthError.general("Google ID Token missing.")
        }
        
        let accessToken = user.accessToken.tokenString
        
        // Firebase credential
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: accessToken
        )
        
        let _ = try await Auth.auth().signIn(with: credential)
    }
    
    
    // --- MARK: Utility Functions for Apple Sign In ---
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXTZabcdefghiklmnopqrstuvwxyz")
        
        let nonce = randomBytes.map { byte in
            return charset[Int(byte) % charset.count]
        }
        
        return String(nonce)
    }
    
    @available(iOS 13, *)
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        let hashString = hashed.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}


// MARK: - ASAuthorizationControllerDelegate Helper (Remains correct)

class ASDelegateHandler: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    private var continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>?
    
    func performSignInWithAppleRequest(request: ASAuthorizationAppleIDRequest) async throws -> ASAuthorizationAppleIDCredential {
        
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Find the most appropriate window for presentation
        guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) ?? UIApplication.shared.windows.first else {
            fatalError("No window found for Sign In with Apple.")
        }
        return window
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            continuation?.resume(throwing: AuthError.general("Authorization failed: Credential mismatch."))
            return
        }
        continuation?.resume(returning: appleIDCredential)
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation?.resume(throwing: error)
    }
}

// MARK: - Custom Error (Remains correct)

enum AuthError: Error {
    case general(String)
    
    var localizedDescription: String {
        switch self {
        case .general(let message): return message
        }
    }
}
