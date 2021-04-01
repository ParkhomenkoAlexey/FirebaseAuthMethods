//
//  UIViewController + Extension.swift
//  AuthWithPhone
//
//  Created by Пархоменко Алексей on 01.04.2021.
//  Copyright © 2021 Alexey Lazukin. All rights reserved.
//

import UIKit

extension UIViewController {
    
    func showAlert(with title: String, and message: String, completion: @escaping () -> Void = { }) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { (_) in
            completion()
        }
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
}
