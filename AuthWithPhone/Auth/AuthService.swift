//
//  AuthService.swift
//  IChat
//
//  Created by Алексей Пархоменко on 30.01.2020.
//  Copyright © 2020 Алексей Пархоменко. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import GoogleSignIn
import FBSDKLoginKit
import AuthenticationServices
import CryptoKit

class AuthService {
    
    static let shared = AuthService()
    private let loginManager = LoginManager() // fb
    private var currentNonce: String? // appleID

// MARK: - Phone Auth
    func login(email: String?, password: String?, completion: @escaping (Result<User, Error>) -> Void) {
        
        guard let email = email, let password = password else {
            completion(.failure(AuthError.notFilled))
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
            guard let result = result else {
                completion(.failure(error!))
                return
            }
            completion(.success(result.user))
        }
    }
    
// MARK: - Google Auth
    func googleLogin(user: GIDGoogleUser!, error: Error!, completion: @escaping (Result<User, Error>) -> Void) {
        if let error = error {
            completion(.failure(error))
            return
        }
        guard let auth = user.authentication else { return }
        let credential = GoogleAuthProvider.credential(withIDToken: auth.idToken, accessToken: auth.accessToken)
        
        Auth.auth().signIn(with: credential) { (result, error) in
            guard let result = result else {
                completion(.failure(error!))
                return
            }
            completion(.success(result.user))
        }
    }
    
// MARK: - Facebook Auth
    func facebookLogin(from: UIViewController, completion: @escaping (Result<User, Error>) -> Void) {
        
        if let _ = AccessToken.current {
            print("log out")
            } else {
                loginManager.logIn(permissions: ["email","public_profile"], from: from) { (result, error) in

                    guard error == nil else {
                        completion(.failure(error!))
                        return
                    }

                    guard let result = result, !result.isCancelled else {
                        print("User cancelled login")
                        return
                    }
                    
                    let credential = FacebookAuthProvider.credential(withAccessToken: AccessToken.current?.tokenString ?? "")
                    
                    Auth.auth().signIn(with: credential) { (result, error) in
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            completion(.success(result!.user))
                        }
                    }
                    
                    self.getUserDataFromFacebook { (result) in
                        switch result {
                        case .success(let email):
                            print("Facebook user email: \(email)")
                        case .failure(let error):
                            print("Email Error: \(error)")
                        }
                    }
                }
            }
    }
    
    private func getUserDataFromFacebook(completion: @escaping (Result<String, Error>) -> Void) {
        
        let req = GraphRequest(graphPath: "me", parameters: ["fields":"email,name"], tokenString: AccessToken.current!.tokenString, version: nil, httpMethod: .get)
           
        var email: String = ""
        req.start { (connection, result, error) in
            guard error == nil else {
                completion(.failure(error!))
                return }
            guard let fields = result as? [String:Any] else { return }
            email = fields["email"] as? String ?? ""
            completion(.success(email))
        }
    }
    
// MARK: - Apple ID Auth
    enum AppleIDError: Error {
        case credentialError
        case nonceError
        case tokenError
        case tokenStringError(String)
        case error(Error)
        
        var description: String {
            switch self {
            case .credentialError:
                return "credentialError"
            case .nonceError:
                return "Invalid state: A login callback was received, but no login request was send"
            case .error(let error):
                return error.localizedDescription
            case .tokenError:
                return "Unable to fetch identity token"
            case .tokenStringError(let tokenDebugDescription):
                return "Unable to serialize token string from data: \(tokenDebugDescription)"
            }
        }
    }
    
    func appleIDLogin(authorization: ASAuthorization!, completion: @escaping (Result<User, AppleIDError>) -> Void) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            completion(.failure(.credentialError))
            return
        }
        guard let nonce = currentNonce else {
            completion(.failure(.nonceError))
            return }
        guard let appleIDToken = appleIDCredential.identityToken else {
            completion(.failure(.tokenError))
            return
        }
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            completion(.failure(.tokenStringError(appleIDToken.debugDescription)))
            return
        }
        
        let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idTokenString, rawNonce: nonce)
        
        Auth.auth().signIn(with: credential) { (result, error) in
            guard let result = result else {
                completion(.failure(.error(error!)))
                return
            }
            completion(.success(result.user))
        }
        
    }
    
    typealias AppleIdEntity = UIViewController & ASAuthorizationControllerDelegate & ASAuthorizationControllerPresentationContextProviding
    
    func presentingAppleIDViewCOntroller<T: AppleIdEntity>(from: T) {
        let request = createAppleIDRequest()
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        
        authorizationController.delegate = from
        authorizationController.presentationContextProvider = from
        
        authorizationController.performRequests()
    }
    
    private func createAppleIDRequest() -> ASAuthorizationAppleIDRequest {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let nonce = randomNonceString()
        request.nonce = sha256(nonce)
        currentNonce = nonce
        return request
    }
    
    // Adapted from https://auth0.com/docs/api-auth/tutorials/nonce#generate-a-cryptographically-random-nonce
    private func randomNonceString(length: Int = 32) -> String {
      precondition(length > 0)
      let charset: Array<Character> =
          Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
      var result = ""
      var remainingLength = length

      while remainingLength > 0 {
        let randoms: [UInt8] = (0 ..< 16).map { _ in
          var random: UInt8 = 0
          let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
          if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
          }
          return random
        }

        randoms.forEach { random in
          if remainingLength == 0 {
            return
          }

          if random < charset.count {
            result.append(charset[Int(random)])
            remainingLength -= 1
          }
        }
      }

      return result
    }

    @available(iOS 13, *)
    private func sha256(_ input: String) -> String {
      let inputData = Data(input.utf8)
      let hashedData = SHA256.hash(data: inputData)
      let hashString = hashedData.compactMap {
        return String(format: "%02x", $0)
      }.joined()

      return hashString
    }

// MARK: - Email Auth
    func register(email: String?, password: String?, confirmPassword: String?, completion: @escaping (Result<User, Error>) -> Void) {
        
        guard Validators.isFilled(email: email, password: password, confirmPassword: confirmPassword) else {
            completion(.failure(AuthError.notFilled))
            return
        }
        
        guard password!.lowercased() == confirmPassword!.lowercased() else {
            completion(.failure(AuthError.passwordsNotMatched))
            return
        }
        
        guard Validators.isSimpleEmail(email!) else {
            completion(.failure(AuthError.invalidEmail))
            return
        }
        
        Auth.auth().createUser(withEmail: email!, password: password!) { (result, error) in
            guard let result = result else {
                completion(.failure(error!))
                return
            }
            completion(.success(result.user))
        }
    }

// MARK: - LogOut
    func logOut() {
        
        if let _ = AccessToken.current {
            loginManager.logOut()
        }
        
        do {
            try Auth.auth().signOut()
        } catch {
        }
    }
}
