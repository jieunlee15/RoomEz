//  LoginViewController.swift
//  RoomEz
//  Created by Ananya Singh on 10/20/25.

import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {
    
    @IBOutlet weak var errorMessage: UILabel!
    @IBOutlet weak var emailText: UITextField!
    @IBOutlet weak var passwordText: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        loginButton.backgroundColor = .black
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
        loginButton.layer.cornerRadius = 10
        loginButton.clipsToBounds = true
        
        errorMessage.textColor = .systemRed
        errorMessage.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        errorMessage.text = ""
        
        //passwordText.isSecureTextEntry = true
        
    }
    
    @IBAction func forgotPassPressed(_ sender: Any) {
        performSegue(withIdentifier: "toForgotPassword", sender: self)
    }
    
    @IBAction func loginButtonPressed(_ sender: Any) {
        guard let email = emailText.text, !email.isEmpty,
              let password = passwordText.text, !password.isEmpty else {
            errorMessage.text = "Please enter both email and password."
            return
        }
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }
            
            if let error = error as NSError? {
                self.errorMessage.text = error.localizedDescription
            } else {
                self.errorMessage.text = ""
                
                // Move to the next screen (e.g. home screen)
                // Assuming you have a segue in your storyboard with identifier "goToHome"
                self.performSegue(withIdentifier: "toMessageLog", sender: self)
            }
        }
    }
}
