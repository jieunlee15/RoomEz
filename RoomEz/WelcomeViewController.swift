//  WelcomeViewController.swift
//  RoomEz
//  Created by Ananya Singh on 10/20/25.

import UIKit

class WelcomeViewController: UIViewController {
    
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var registerButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Style the login button
        loginButton.layer.cornerRadius = 10
        loginButton.clipsToBounds = true
        
        // Style the register button
        registerButton.layer.borderWidth = 1
        registerButton.layer.borderColor = UIColor.black.cgColor
        registerButton.layer.cornerRadius = 10
        registerButton.clipsToBounds = true
    }
}
