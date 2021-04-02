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

class AuthService {
    
    static let shared = AuthService()
    private let loginManager = LoginManager()
    
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
    
    func appleIDLogin(completion: @escaping (Result<User, Error>) -> Void) {
        
    }

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
