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
        guard let code = codeTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !code.isEmpty else {
            showAlert(title: "Missing Code", message: "Please enter a room code.")
            return
        }
        joinRoom(with: code)
    }
    
    private func joinRoom(with code: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let roomRef = db.collection("roommateGroups").document(code)
        
        roomRef.getDocument { doc, error in
            if let doc = doc, doc.exists {
                roomRef.updateData(["members": FieldValue.arrayUnion([uid])]) { _ in
                    Firestore.firestore().collection("users").document(uid)
                        .updateData(["currentRoomCode": code]) { _ in
                            DispatchQueue.main.async {
                                self.redirectToHome(with: code)
                            }
                        }
                }
            } else {
                self.showAlert(title: "Invalid Code", message: "Room code does not exist.")
            }
        }
    }
    
    private func redirectToHome(with roomCode: String) {
        guard let tabBar = self.tabBarController as? MainTabBarController else { return }
        tabBar.setUserHasRoom(true)
        tabBar.selectedIndex = 0 // Dashboard
        // Set messages tab to announcements
        if let nav = tabBar.viewControllers?[2] as? UINavigationController,
           let annVC = storyboard?.instantiateViewController(withIdentifier: "MessagesVC") as? AnnouncementViewController {
            annVC.setRoomCode(roomCode)
            nav.setViewControllers([annVC], animated: false)
        }
    }
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
        
    }
}
