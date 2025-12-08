//  EnterCodeViewController.swift
//  RoomEz
//  Created by Ananya Singh on 11/11/25.

import UIKit
import FirebaseFirestore

class EnterCodeViewController: UIViewController {

    @IBOutlet weak var codeField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!

    let db = Firestore.firestore()
    var userEmail: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        enableKeyboardDismissOnTap()
        errorLabel.text = ""
    }

    @IBAction func verifyPressed(_ sender: UIButton) {
        guard let email = userEmail,
              let enteredCode = codeField.text,
              !enteredCode.isEmpty else { return }

        // Fetch stored code from Firestore
        db.collection("passwordResetCodes").document(email).getDocument { doc, error in
            if let doc = doc, let data = doc.data(), let realCode = data["code"] as? String {

                if enteredCode == realCode {
                    // Correct code → go to password reset screen
                    self.performSegue(withIdentifier: "toCreateNewPass", sender: nil)
                } else {
                    // Wrong code → show error
                    self.errorLabel.text = "Incorrect code, try again."
                    self.errorLabel.textColor = .systemRed
                }

            } else {
                self.errorLabel.text = "No reset request found."
                self.errorLabel.textColor = .systemRed
            }
        }
    }
}
