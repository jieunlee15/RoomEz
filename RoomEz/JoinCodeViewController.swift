//
//  JoinCodeViewController.swift
//  RoomEz
//
//  Created by Venkataraman, Shriya on 10/20/25.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class JoinCodeViewController: UIViewController {
    @IBOutlet weak var codeTextField: UITextField!
    
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func joinButtonTapped(_ sender: UIButton) {
        guard let enteredCode = codeTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !enteredCode.isEmpty else {
            showAlert(title: "Missing Code", message: "Please enter a room code.")
            return
        }
        
        joinRoom(with: enteredCode)
    }
    
    func joinRoom(with code: String) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            showAlert(title: "Error", message: "You must be logged in to join a room.")
            return
        }

        let roomRef = db.collection("roommateGroups").document(code)
        
        roomRef.getDocument { document, error in
            if let error = error {
                print("Error fetching room: \(error)")
                self.showAlert(title: "Error", message: "Could not connect to the server. Try again.")
                return
            }
            
            guard let document = document, document.exists else {
                self.showAlert(title: "Invalid Code", message: "The room code you entered does not exist.")
                return
            }
            
            // Add user to members array (merge keeps existing members)
            roomRef.updateData([
                "members": FieldValue.arrayUnion([currentUserID])
            ]) { error in
                if let error = error {
                    print("Error joining room: \(error)")
                    self.showAlert(title: "Error", message: "Could not join room. Please try again.")
                } else {
                    UIPasteboard.general.string = code
                    print("Joined room \(code) successfully!")
                    
                    let alert = UIAlertController(title: "You're In!", message: "Entering room shortly...", preferredStyle: .alert)
                    self.present(alert, animated: true) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            alert.dismiss(animated: true) {
                                self.performSegue(withIdentifier: "afterJoinPressed", sender: self)
                            }
                        }
                    }
                }
            }
        }
    }

    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
