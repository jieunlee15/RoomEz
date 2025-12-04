//  ForgotPasswordViewController.swift
//  RoomEz
//
//  Created by Ananya Singh on 11/11/25.
//

import UIKit
import FirebaseAuth

class ForgotPasswordViewController: UIViewController {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Clear any previous error/success messages when the view loads
        errorLabel.text = "Please enter the email address associated with your account"
        errorLabel.textColor = .systemRed
    }

    @IBAction func sendCodeTapped(_ sender: UIButton) {
        
        // Clear old messages every time the user taps the button
        errorLabel.text = ""

        // Make sure the user actually entered an email
        guard let email = emailField.text, !email.isEmpty else {
            showError("Please enter your email.")
            return
        }

        // Use Firebase’s built-in password reset function — sends the user a secure email link
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            
            if let error = error {
                // Something went wrong — show the error directly on the screen
                self.showError(error.localizedDescription)
            } else {
                // Email sent successfully — show confirmation in green
                self.showSuccess("If an account exists for this email, a reset link has been sent.")
                
                /*
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.navigationController?.popViewController(animated: true)
                }
                */
            }
        }
    }

    // MARK: - Helper methods to show feedback

    // Shows red error text in the label
    private func showError(_ message: String) {
        DispatchQueue.main.async {
            self.errorLabel.textColor = .systemRed
            self.errorLabel.text = message
        }
    }

    // Shows green success text in the label
    private func showSuccess(_ message: String) {
        DispatchQueue.main.async {
            self.errorLabel.textColor = .systemGreen
            self.errorLabel.text = message
        }
    }
}
