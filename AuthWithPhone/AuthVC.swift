//
//  ViewController.swift
//  AuthWithPhone
//
//  Created by Macbook Pro on 01/05/2020.
//  Copyright © 2020 Alexey Lazukin. All rights reserved.
//

import UIKit
import FirebaseAuth
import GoogleSignIn
import FBSDKLoginKit
import AuthenticationServices

class AuthVC: UIViewController {

    @IBAction func closeSegue(_ sender: UIStoryboardSegue) {
        
    }
    @IBAction func googleTapped(_ sender: Any) {
        print(#function)
        GIDSignIn.sharedInstance()?.presentingViewController = self
        GIDSignIn.sharedInstance().signIn()
    }
    
    @IBAction func facebookTapped(_ sender: Any) {
        print(#function)
        AuthService.shared.facebookLogin(from: self) { (result) in
            switch result {
            
            case .success(let user):
                print("user: ", user)
                print("user.email ", user.email)
            case .failure(let error):
                self.showAlert(with: "Ошибка", and: error.localizedDescription)
            }
        }
    }
    
    @IBAction func appleIDTapped(_ sender: Any) {
        print(#function)
        AuthService.shared.presentingAppleIDViewCOntroller(from: self)
    }
    
    @IBAction func authTapped() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let dvc = storyboard.instantiateViewController(withIdentifier: "PhoneNumberVC") as! PhoneNumberVC
        self.present(dvc, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        GIDSignIn.sharedInstance()?.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        DispatchQueue.main.async {
            if Auth.auth().currentUser?.uid != nil {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let dvc = storyboard.instantiateViewController(withIdentifier: "ContentVC") as! ContentVC
                self.present(dvc, animated: true, completion: nil)
            }
        }
    }
}

// MARK: - GIDSignInDelegate
extension AuthVC: GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        AuthService.shared.googleLogin(user: user, error: error) { (result) in
            switch result {
            case .success(let user):
                print("user: ", user)
                print("user.email ", user.email)
            case .failure(let error):
                self.showAlert(with: "Ошибка", and: error.localizedDescription)
            }
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension AuthVC: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        AuthService.shared.appleIDLogin(authorization: authorization) { (result) in
            switch result {
            case .success(let user):
                print("user: ", user)
                print("user.email ", user.email)
            case .failure(let error):
                self.showAlert(with: "Ошибка", and: error.localizedDescription)
            }
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AuthVC: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}
