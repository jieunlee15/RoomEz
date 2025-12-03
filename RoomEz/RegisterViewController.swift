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
    }
    
    @IBAction func registerButtonPressed(_ sender: Any) {
        guard let fName = firstName.text, !fName.isEmpty,
              let lName = lastName.text, !lName.isEmpty,
              let email = emailText.text, !email.isEmpty,
              let password = passwordText.text, !password.isEmpty,
              let confirmPassword = confirmPasswordText.text, !confirmPassword.isEmpty else {
            errorMessage.text = "Please fill in all fields."
            return
        }
        
        guard password == confirmPassword else {
            errorMessage.text = "Passwords do not match."
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self]
            authResult, error in
            guard let self = self else { return }
            if let error = error {
                self.errorMessage.text = error.localizedDescription
                return
            }
            self.errorMessage.text = ""
            
            // Save user info in Firestore
            if let uid = authResult?.user.uid {
                Firestore.firestore().collection("users").document(uid).setData([
                    "firstName": fName,
                    "lastName": lName,
                    "email": email,
                    "createdAt": Timestamp(),
                    "currentRoomCode": "" // empty initially
                ]) { error in
                    if let error = error {
                        print("Error saving user: \(error.localizedDescription)")
                    } else {
                        print("User successfully saved to Firestore!")
                    }
                }
            }
            
            if let tabBar = self.storyboard?.instantiateViewController(withIdentifier: "MainTabBar") {
                tabBar.modalPresentationStyle = .fullScreen
                self.present(tabBar, animated: true)
            }
        }
    }
}
