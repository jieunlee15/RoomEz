//
//  InviteRoomieViewController.swift
//  RoomEz
//
//  Created by Venkataraman, Shriya on 10/20/25.
//

import UIKit

class InviteRoomieViewController: UIViewController {
    @IBOutlet weak var generatedCodeLabel: UITextField!
    override func viewDidLoad() {
            super.viewDidLoad()
            let newCode = generateRandomCode()
            generatedCodeLabel.text = newCode
        }

        func generateRandomCode(length: Int = 4) -> String {
            let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
            return String((0..<length).compactMap { _ in characters.randomElement() })
        }

        @IBAction func copyCodeTapped(_ sender: UIButton) {
            if let code = generatedCodeLabel.text {
                UIPasteboard.general.string = code
                let alert = UIAlertController(title: "Copied", message: "Roommate code copied to clipboard.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
            }
        }
    }
