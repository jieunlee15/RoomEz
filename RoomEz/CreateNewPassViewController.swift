
import UIKit
import FirebaseAuth

class CreateNewPassViewController: UIViewController {

    @IBOutlet weak var confirmPassword: UITextField!
    @IBOutlet weak var newPassword: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    
    var userEmail: String?   // Passed from EnterCodeVC

    override func viewDidLoad() {
        super.viewDidLoad()
        //errorLabel.text = ""
        //errorLabel.textColor = .systemRed
        enableKeyboardDismissOnTap()
    }

    @IBAction func resetPassPressed(_ sender: Any) {
        // clear old message
        errorLabel.text = ""

        guard let email = userEmail else {
            showInlineError("Missing email information.")
            return
        }
        guard let newPass = newPassword.text, !newPass.isEmpty,
              let confirmPass = confirmPassword.text, !confirmPass.isEmpty else {
            showInlineError("Please fill out both password fields.")
            return
        }
        guard newPass == confirmPass else {
            showInlineError("Passwords don’t match. Please try again.")
            return
        }
        guard newPass.count >= 6 else {
            showInlineError("Password must be at least 6 characters long.")
            return
        }

        // Only continue if user is signed in 
        if let user = Auth.auth().currentUser {
            user.updatePassword(to: newPass) { error in
                if let error = error {
                    self.showInlineError(error.localizedDescription)
                } else {
                    self.showSuccessAndSegue()
                }
            }
        } else {
            // User not signed in — show error and DO NOT segue
            self.showInlineError("You must be signed in to update your password.")
        }
    }

    // MARK: - Helpers
    private func showInlineError(_ message: String) {
        DispatchQueue.main.async {
            self.errorLabel.textColor = .systemRed
            self.errorLabel.text = message
        }
    }

    private func showSuccessAndSegue() {
        DispatchQueue.main.async {
            self.errorLabel.textColor = .systemGreen
            self.errorLabel.text = "Password updated successfully!"
            // Only segue after showing success
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.performSegue(withIdentifier: "toPassChange", sender: self)
            }
        }
    }
}
