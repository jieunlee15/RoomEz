//
//  ForgotPasswordViewController.swift
//  RoomEz
//
//  Created by Ananya Singh on 11/11/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class ForgotPasswordViewController: UIViewController {

    @IBOutlet weak var emailField: UITextField!
    let db = Firestore.firestore()

    @IBAction func sendCodeTapped(_ sender: UIButton) {
        // later: call Firebase password reset here
        guard let email = emailField.text, !email.isEmpty else { return }

        // Generate 6-digit code
        let code = String(Int.random(in: 100000...999999))

        // Save to Firestore
        db.collection("passwordResetCodes").document(email).setData(["code": code, "createdAt": Date()])

        // Print for testing (pretend this was emailed)
        print("Reset code for \(email): \(code)")
        performSegue(withIdentifier: "goToVerification", sender: self)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
