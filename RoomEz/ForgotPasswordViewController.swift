//
//  ForgotPasswordViewController.swift
//  RoomEz
//
//  Created by Ananya Singh on 11/11/25.
//

import UIKit
import FirebaseAuth

class ForgotPasswordViewController: UIViewController {

    @IBOutlet weak var emailField: UITextField!

    @IBAction func sendCodeTapped(_ sender: UIButton) {
        // later: call Firebase password reset here
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
