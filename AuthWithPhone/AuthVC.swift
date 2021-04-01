//
//  ViewController.swift
//  AuthWithPhone
//
//  Created by Macbook Pro on 01/05/2020.
//  Copyright © 2020 Alexey Lazukin. All rights reserved.
//

import UIKit
import FirebaseAuth

class AuthVC: UIViewController {

    @IBAction func closeSegue(_ sender: UIStoryboardSegue) {
        
    }
    
    @IBAction func authTapped() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let dvc = storyboard.instantiateViewController(withIdentifier: "PhoneNumberVC") as! PhoneNumberVC
        self.present(dvc, animated: true)
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

