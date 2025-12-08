//
//  EditProfileViewController.swift
//  RoomEz
//
//  Created by Ananya Singh on 12/1/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class EditProfileViewController: UIViewController {
    
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    
    // Values passed in from ProfileViewController
    var currentFirstName: String?
    var currentLastName: String?
    var currentEmail: String?
    
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Edit Profile"
        
        firstNameTextField.text = currentFirstName
        lastNameTextField.text = currentLastName
        emailTextField.text = currentEmail
        emailTextField.isEnabled = false   // email read-only for now
        
        saveButton.layer.cornerRadius = 10
        saveButton.clipsToBounds = true
    }
    
    @IBAction func saveButtonPressed(_ sender: UIButton) {
        print("saveButtonPressed called")
        
        guard let newFirst = firstNameTextField.text, !newFirst.isEmpty,
              let newLast = lastNameTextField.text, !newLast.isEmpty else {
            print("First/last name cannot be empty")
            return
        }
        
        let fullDisplayName = "\(newFirst) \(newLast)"
        
        guard let user = Auth.auth().currentUser,
              let uid = user.uid as String? else {
            print("No authenticated user")
            return
        }
        
        // 1) Update Firebase Auth displayName
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = fullDisplayName
        
        changeRequest.commitChanges { error in
            if let error = error {
                print("Error updating display name: \(error.localizedDescription)")
            } else {
                print("Display name updated in Firebase Auth")
            }
        }
        
        // 2) Update Firestore user document, then pop back
        db.collection("users").document(uid).setData([
            "firstName": newFirst,
            "lastName": newLast,
            "displayName": fullDisplayName
        ], merge: true) { error in
            if let error = error {
                print("Error updating Firestore profile: \(error.localizedDescription)")
                return
            }
            print("Profile name updated in Firestore")
            
            // Pop back to Profile on main thread
            DispatchQueue.main.async {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
}
