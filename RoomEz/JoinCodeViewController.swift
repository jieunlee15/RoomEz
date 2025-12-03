//  JoinCodeViewController.swift
//  RoomEz
//  Created by Venkataraman, Shriya on 10/20/25.

import UIKit
import FirebaseFirestore
import FirebaseAuth

class JoinCodeViewController: UIViewController {
    
    @IBOutlet weak var codeTextField: UITextField!
    let db = Firestore.firestore()
    
    @IBAction func joinButtonTapped(_ sender: UIButton) {
        guard let enteredCode = codeTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !enteredCode.isEmpty else {
            showAlert(title: "Missing Code", message: "Please enter a room code.")
            return
        }
        
        joinRoom(with: enteredCode)
    }
    
    func joinRoom(with code: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let roomRef = db.collection("roommateGroups").document(code)
        
        roomRef.getDocument { document, error in
            if let error = error {
                self.showAlert(title: "Error", message: "Could not connect. Try again.")
                print(error)
                return
            }
            
            guard let document = document, document.exists else {
                self.showAlert(title: "Invalid Code", message: "Room code does not exist.")
                return
            }
            
            roomRef.updateData(["members": FieldValue.arrayUnion([uid])]) { error in
                if let error = error {
                    self.showAlert(title: "Error", message: "Could not join room.")
                    print(error)
                } else {
                    // Persist room code
                    Firestore.firestore().collection("users").document(uid)
                        .updateData(["currentRoomCode": code])
                    
                    DispatchQueue.main.async {
                        guard let nav = self.navigationController else { return }
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        let annVC = storyboard.instantiateViewController(withIdentifier: "MessagesVC") as! AnnouncementViewController
                        annVC.setRoomCode(code)
                        nav.setViewControllers([annVC], animated: true)
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

