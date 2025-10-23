//
//  JoinCodeViewController.swift
//  RoomEz
//
//  Created by Venkataraman, Shriya on 10/20/25.
//

import UIKit

class JoinCodeViewController: UIViewController {
    @IBOutlet weak var codeTextField: UITextField!

        let correctCode = "P1NK"
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
        }

        @IBAction func joinButtonTapped(_ sender: UIButton) {
            guard let enteredCode = codeTextField.text else { return }
            
            if enteredCode == correctCode {
                performSegue(withIdentifier: "afterJoinPressed", sender: self)
                UIPasteboard.general.string = enteredCode
                
                // Success alert
                let alert = UIAlertController(title: "You're In!", message: "Entering Room shortly...", preferredStyle: .alert)
                self.present(alert, animated: true)
            } else {
                // Failure alert
                let alert = UIAlertController(title: "Incorrect Code", message: "The code you entered is incorrect or no longer valid.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
            }
        }
    }
