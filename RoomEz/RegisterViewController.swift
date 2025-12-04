//  RegisterViewController.swift
//  RoomEz
//  Created by Ananya Singh on 10/20/25.

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

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
        
        // Create the account
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }
            
            if let error = error {
                self.errorMessage.text = error.localizedDescription
                return
            }
            
            self.errorMessage.text = ""
            
            // Make sure session is fully initialized → sign in again explicitly
            Auth.auth().signIn(withEmail: email, password: password) { result, error in
                if let error = error {
                    self.errorMessage.text = "Login failed: \(error.localizedDescription)"
                    return
                }
                
                guard let user = result?.user else { return }
                let displayName = "\(fName) \(lName)"
                
                // Update displayName in Firebase Auth
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.displayName = displayName
                changeRequest.commitChanges(completion: nil)
                
                // Save Firestore user document
                let userData: [String: Any] = [
                    "firstName": fName,
                    "lastName": lName,
                    "displayName": displayName,
                    "email": email,
                    "photoURL": "",
                    "notificationOn": true,
                    "anonymousOn": false,
                    "currentRoomCode": "",
                    "createdAt": Timestamp()
                ]
                
                Firestore.firestore().collection("users").document(user.uid)
                    .setData(userData) { error in
                        if let error = error {
                            print("Error saving user: \(error.localizedDescription)")
                        } else {
                            print("User successfully saved to Firestore!")
                        }
                    }
                
                // Send them straight to the Main Tab Bar → Messages tab
                DispatchQueue.main.async {
                    if let tabBar = self.storyboard?.instantiateViewController(withIdentifier: "MainTabBar") as? MainTabBarController {
                        
                        // New users do NOT have a room yet
                        tabBar.setUserHasRoom(false)
                        
                        // Land on the Messages tab
                        tabBar.selectedIndex = 2
                        
                        // Replace the current stack
                        self.navigationController?.setViewControllers([tabBar], animated: true)
                    }
                }
            }
        }
    }
}
