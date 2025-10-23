//
//  WelcomeViewController.swift
//  RoomEz
//
//  Created by Ananya Singh on 10/20/25.
//

import UIKit

class WelcomeViewController: UIViewController {

    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var registerButton: UIButton!
    override func viewDidLoad() {
            super.viewDidLoad()

            // Style the login button: black background, white bold text
            loginButton.backgroundColor = .black
            loginButton.setTitleColor(.white, for: .normal)
            loginButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
            loginButton.layer.cornerRadius = 10
            loginButton.clipsToBounds = true
            
            // Style the register button: white background, black border, black bold text
            registerButton.backgroundColor = .white
            registerButton.setTitleColor(.black, for: .normal)
            registerButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
            registerButton.layer.borderWidth = 1
            registerButton.layer.borderColor = UIColor.black.cgColor
            registerButton.layer.cornerRadius = 10
            registerButton.clipsToBounds = true
        }
    
    @IBAction func loginButtonPressed(_ sender: Any) {
        performSegue(withIdentifier: "toLogin", sender: self)
    }
    
    @IBAction func registerButtonPressed(_ sender: Any) {
        performSegue(withIdentifier: "toRegister", sender: self)
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
