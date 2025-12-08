//
//  LoginViewController.swift
//  RoomEz
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class LoginViewController: UIViewController {
    
    @IBOutlet weak var errorMessage: UILabel!
    @IBOutlet weak var emailText: UITextField!
    @IBOutlet weak var passwordText: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginButton.clipsToBounds = true
        errorMessage.text = ""
        errorMessage.textColor = .systemRed
        errorMessage.font = .systemFont(ofSize: 14, weight: .medium)
    }
    
    
    func goToMainTabs(userHasRoom: Bool) {
        guard let tabBar = storyboard?.instantiateViewController(withIdentifier: "MainTabBar") as? MainTabBarController else { return }

        tabBar.setUserHasRoom(userHasRoom)
        tabBar.selectedIndex = 2
        
        // FIX: Present modally exactly like your OG login flow did
        tabBar.modalPresentationStyle = .fullScreen
        self.present(tabBar, animated: true, completion: nil)
    }

    @IBAction func loginButtonPressed(_ sender: Any) {
        guard let email = emailText.text, !email.isEmpty,
              let password = passwordText.text, !password.isEmpty else {
            errorMessage.text = "Please enter both email and password."
            return
        }

        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }
            
            if let error = error {
                self.errorMessage.text = error.localizedDescription
                return
            }

            self.errorMessage.text = ""
            self.goToMainTabs(userHasRoom: false)
        }
    }
}

