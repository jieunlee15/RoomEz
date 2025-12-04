//  LoginViewController.swift
//  RoomEz
//  Created by Ananya Singh on 10/20/25.

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
        loginButton.layer.cornerRadius = 10
        loginButton.clipsToBounds = true
        errorMessage.textColor = .systemRed
        errorMessage.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        errorMessage.text = ""
    }
    
    
    @IBAction func loginButtonPressed(_ sender: Any) {
        guard let email = emailText.text, !email.isEmpty,
              let password = passwordText.text, !password.isEmpty else {
            errorMessage.text = "Please enter both email and password."
            return
        }
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }
            
            if let error = error as NSError? {
                self.errorMessage.text = error.localizedDescription
            } else {
                self.errorMessage.text = ""
                
                // Move to the next screen (e.g. home screen)
                self.performSegue(withIdentifier: "toMessageLog", sender: self)
            }
        }
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toMessageLog" {
            if let tabBar = self.storyboard?.instantiateViewController(withIdentifier: "MainTabBar") as? MainTabBarController {
                // At this point the user just logged in / registered,
                // so they probably don't have a room yet.
                tabBar.setUserHasRoom(false)
                tabBar.selectedIndex = 2   // Messages tab with "No room yet"
                self.navigationController?.setViewControllers([tabBar], animated: true)
            }
            }
        }
    }
