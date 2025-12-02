//  NewAnnouncementViewController.swift
//  RoomEz
//  Created by Jieun Lee on 10/20/25.

import UIKit
import FirebaseAuth
import FirebaseFirestore

protocol NewAnnouncementDelegate: AnyObject {
    func didPostAnnouncement(_ announcement: Announcement)
}

class NewAnnouncementViewController: UIViewController {
    
    var roomCode: String!
    
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var contentField: UITextView!
    @IBOutlet weak var anonymousSwitch: UISwitch!
    
    weak var delegate: NewAnnouncementDelegate?
    
    private let db = Firestore.firestore()
    private var anonymousDefaultOn = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleField.layer.borderWidth = 1.0
        titleField.layer.borderColor = UIColor(
            red: 193/255,
            green: 193/255,
            blue: 193/255,
            alpha: 1
        ).cgColor
        titleField.layer.cornerRadius = 10.0
        
        contentField.layer.borderWidth = 1.0
        contentField.layer.borderColor = UIColor(
            red: 193/255,
            green: 193/255,
            blue: 193/255,
            alpha: 1
        ).cgColor
        contentField.layer.cornerRadius = 10.0
        
        loadAnonymousPreference()
    }
    
    // Pull the "Anonymous" toggle from Profile settings
    private func loadAnonymousPreference() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).getDocument { [weak self] snap, _ in
            guard let self = self else { return }
            if let data = snap?.data() {
                self.anonymousDefaultOn = data["anonymousOn"] as? Bool ?? false
                // If user has not touched the switch yet, use their default
                if self.anonymousSwitch.isOn == false {
                    self.anonymousSwitch.isOn = self.anonymousDefaultOn
                }
            }
        }
    }
    
    @IBAction func submitTapped(_ sender: UIButton) {
        // 1. Validate text
        guard
            let rawTitle = titleField.text,
            let rawContent = contentField.text
        else { return }
        
        let title = rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let content = rawContent.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !title.isEmpty, !content.isEmpty else {
            showAlert(title: "Missing Info",
                      message: "Please fill in both title and announcement.")
            return
        }
        
        // 2. Need a room code (set in JoinCodeViewController)
        guard let roomCode = roomCode else {
            showAlert(title: "No Room",
                      message: "Cannot post without a room. Please join a room first.")
            return
        }
        
        // 3. Need a logged-in user
        guard let user = Auth.auth().currentUser else {
            showAlert(title: "Not Logged In",
                      message: "You must be logged in to post an announcement.")
            return
        }
        
        // 4. Author name based on anonymous toggle
        let isAnonymous = anonymousSwitch.isOn
        let authorName: String = {
            if isAnonymous { return "Anonymous" }
            return user.displayName ?? user.email ?? "User"
        }()
        
        let createdAt = Date()
        // Simple expiration: 7 days from now (you can tweak)
        let expiresAt = Calendar.current.date(byAdding: .day, value: 7, to: createdAt)
        
        // 5. Build Firestore data
        var data: [String: Any] = [
            "title": title,
            "content": content,
            "author": authorName,
            "isAnonymous": isAnonymous,
            "createdAt": Timestamp(date: createdAt),
            "isArchived": false
        ]
        
        if let expiresAt = expiresAt {
            data["expiresAt"] = Timestamp(date: expiresAt)
        }
        
        sender.isEnabled = false
        
        let collection = db.collection("roommateGroups")
            .document(roomCode)
            .collection("announcements")
        
        // 6. Save to Firestore
        var ref: DocumentReference? = nil
        ref = collection.addDocument(data: data) { [weak self] error in
            guard let self = self else { return }
            sender.isEnabled = true
            
            if let error = error {
                print("Error saving announcement: \(error)")
                self.showAlert(title: "Error",
                               message: "Could not post your note. Please try again.")
                return
            }
            
            guard let documentID = ref?.documentID else { return }
            
            let announcement = Announcement(
                id: documentID,
                title: title,
                content: content,
                author: authorName,
                isAnonymous: isAnonymous,
                date: createdAt
            )
            self.delegate?.didPostAnnouncement(announcement)
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
