//  InviteRoomieViewController.swift
//  RoomEz
//  Created by Venkataraman, Shriya on 10/20/25.

import UIKit
import FirebaseFirestore
import FirebaseAuth

class InviteRoomieViewController: UIViewController {
    
    @IBOutlet weak var generatedCodeLabel: UITextField!
    let db = Firestore.firestore()

    override func viewDidLoad() {
        super.viewDidLoad()
        let newCode = generateRandomCode()
        generatedCodeLabel.text = newCode
        createRoomInFirestore(code: newCode)
    }

    func generateRandomCode(length: Int = 4) -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).compactMap { _ in characters.randomElement() })
    }

    @IBAction func copyCodeTapped(_ sender: UIButton) {
        if let code = generatedCodeLabel.text {
            UIPasteboard.general.string = code
            let alert = UIAlertController(title: "Copied",
                message: "Roommate code copied to clipboard.",
                preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }

    func createRoomInFirestore(code: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let roomRef = db.collection("roommateGroups").document(code)

        roomRef.setData([
            "code": code,
            "members": [uid],
            "createdAt": Timestamp()
        ]) { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                print("Error creating room: \(error.localizedDescription)")
                // optionally show an alert
                return
            }
            print("Room created with code: \(code)")

            // Save the room code only after successful creation
            Firestore.firestore().collection("users").document(uid).updateData(["currentRoomCode": code])
        }
    }
}


