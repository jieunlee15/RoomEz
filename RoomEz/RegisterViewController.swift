//  RegisterViewController.swift
//  RoomEz
//  Created by Ananya Singh on 10/20/25.

import UIKit
import FirebaseAuth
import FirebaseFirestore

class RegisterViewController: UIViewController {
    
    
    @IBOutlet weak var firstName: UITextField!
    @IBOutlet weak var lastName: UITextField!
    @IBOutlet weak var errorMessage: UILabel!
    @IBOutlet weak var emailText: UITextField!
    @IBOutlet weak var passwordText: UITextField!
    @IBOutlet weak var confirmPasswordText: UITextField!
    @IBOutlet weak var registerButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        registerButton.layer.cornerRadius = 10
        registerButton.clipsToBounds = true
        
        errorMessage.textColor = .systemRed
        errorMessage.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        errorMessage.text = ""
        
        //passwordText.isSecureTextEntry = true
        //confirmPasswordText.isSecureTextEntry = true
        // Do any additional setup after loading the view.
    }
    
    @IBAction func registerButtonPressed(_ sender: Any) {
        guard let email = emailText.text, !email.isEmpty,
              let password = passwordText.text, !password.isEmpty,
              let confirmPassword = confirmPasswordText.text, !confirmPassword.isEmpty else {
            errorMessage.text = "Please fill in all fields."
            return
        }
        guard password == confirmPassword else {
            errorMessage.text = "Passwords do not match."
            return
        }
        
        // Step 2: Create the user in Firebase
        Auth.auth().createUser(withEmail: email, password: password) { [weak self]
            authResult, error in
            guard let self = self else { return }
            if let error = error as NSError? {
                self.errorMessage.text = error.localizedDescription
            } else {
                self.errorMessage.text = ""
                // Save user to Firestore database
                let db = Firestore.firestore()
                if let uid = authResult?.user.uid {
                    db.collection("users").document(uid).setData([
                        "email": email,
                        "createdAt": Timestamp()
                    ]) { error in
                        if let error = error {
                            print("Error saving user: \(error.localizedDescription)")
                        } else {
                            print("User successfully saved to Firestore!")
                        }
                    }
                }

                // Navigate after saving
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
}
