//
//  ContentVC.swift
//  AuthWithPhone
//
//  Created by Macbook Pro on 01/05/2020.
//  Copyright © 2020 Alexey Lazukin. All rights reserved.
//

import UIKit
import FirebaseAuth

class ContentVC: UIViewController {
    
    @IBAction func logOut(_ sender: UIButton) {
        
        AuthService.shared.logOut()
        performSegue(withIdentifier: "closeSegue", sender: self)
    }
    
}
