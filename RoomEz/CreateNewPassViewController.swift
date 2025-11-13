//  CreateNewPassViewController.swift
//  RoomEz
//  Created by Ananya Singh on 11/11/25.

import UIKit
import FirebaseAuth

class CreateNewPassViewController: UIViewController {

    @IBOutlet weak var confirmPassword: UITextField!
    @IBOutlet weak var newPassword: UITextField!

    var userEmail: String?        // ← passed from EnterCodeVC
    var tempPassword: String?     // optional if you create a temp sign-in flow

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func resetPassPressed(_ sender: Any) {
        guard let email = userEmail else { return }
        guard let newPass = newPassword.text, !newPass.isEmpty,
              let confirmPass = confirmPassword.text, !confirmPass.isEmpty else {
            showAlert("Missing Info", "Please fill out both password fields.")
            return
        }

        guard newPass == confirmPass else {
            showAlert("Passwords Don’t Match", "Please re-enter matching passwords.")
            return
        }

        // Option A: if user is still signed in (rare in reset flow)
        if let user = Auth.auth().currentUser {
            user.updatePassword(to: newPass) { error in
                if let error = error {
                    self.showAlert("Error", error.localizedDescription)
                } else {
                    self.showAlert("Success", "Password updated!") {
                        self.performSegue(withIdentifier: "toPassChange", sender: self)
                    }
                }
            }
            return
        }

        // Option B: sign in temporarily, update password, sign out
        Auth.auth().signIn(withEmail: email, password: newPass) { result, error in
            if let error = error {
                self.showAlert("Error", error.localizedDescription)
                return
            }

            result?.user.updatePassword(to: newPass) { err in
                if let err = err {
                    self.showAlert("Error", err.localizedDescription)
                } else {
                    self.showAlert("Success", "Password updated!") {
                        try? Auth.auth().signOut()
                        self.performSegue(withIdentifier: "toPassChange", sender: self)
                    }
                }
            }
        }
    }

    // Simple alert helper
    private func showAlert(_ title: String, _ msg: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completion?() })
        present(alert, animated: true)
    }
}
