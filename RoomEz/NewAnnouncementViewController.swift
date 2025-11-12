//  NewAnnouncementViewController.swift
//  RoomEz
//  Created by Jieun Lee on 10/20/25.

import UIKit

protocol NewAnnouncementDelegate: AnyObject {
    func didPostAnnouncement(_ announcement: Announcement)
}

class NewAnnouncementViewController: UIViewController {

    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var contentField: UITextView!
    @IBOutlet weak var anonymousSwitch: UISwitch!
    
    weak var delegate: NewAnnouncementDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleField.layer.borderWidth = 1.0
        titleField.layer.borderColor = UIColor(red: 193/255, green: 193/255, blue: 193/255, alpha: 1).cgColor
        titleField.layer.cornerRadius = 10.0
        contentField.layer.borderWidth = 1.0 // Set border width
        contentField.layer.borderColor = UIColor(red: 193/255, green: 193/255, blue: 193/255, alpha: 1).cgColor
        contentField.layer.cornerRadius = 10.0 // Optional: for rounded corners
    }
    
    @IBAction func submitTapped(_ sender: UIButton) {
        guard let title = titleField.text, !title.isEmpty,let content = contentField.text, !content.isEmpty else { return }

        let isAnonymous = anonymousSwitch.isOn
                
        let announcement = Announcement(
            title: title,
            content: content,
            author: isAnonymous ? "Anonymous" : "Lucy",
            isAnonymous: isAnonymous,
            date: Date()
        )
                
        delegate?.didPostAnnouncement(announcement)
        navigationController?.popViewController(animated: true)
    }
}
