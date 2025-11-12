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
        guard
                    let title = titleField.text,
                    !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                    let content = contentField.text,
                    !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                else { return }

                let isAnonymous = anonymousSwitch.isOn
                let currentUser = Auth.auth().currentUser
                
                // If not anonymous, use their displayName or email
                let authorName: String
                if isAnonymous {
                    authorName = "Anonymous"
                } else {
                    authorName = currentUser?.displayName ?? currentUser?.email ?? "User"
                }
                
                let announcement = Announcement(
                    title: title,
                    content: content,
                    author: authorName,
                    isAnonymous: isAnonymous,
                    date: Date()
                )
                
                // Still use the delegate so the parent VC can handle Firebase write
                delegate?.didPostAnnouncement(announcement)
                navigationController?.popViewController(animated: true)
            }
        }
