//
//  NewMessageViewController.swift
//  RoomEz
//
//  Created by Jieun Lee on 10/19/25.
//

import UIKit

protocol NewMessageDelegate: AnyObject {
    func didPostMessage(_ message: String)
}

class NewMessageViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    weak var delegate: NewMessageDelegate?
        
        override func viewDidLoad() {
            super.viewDidLoad()
            title = "New Message"
            textView.text = ""
        }

        @IBAction func postButtonTapped(_ sender: UIButton) {
            let text = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return }

            delegate?.didPostMessage(text)   // tell the delegate
            navigationController?.popViewController(animated: true)  // go back
        }
}

