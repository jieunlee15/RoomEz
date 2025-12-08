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
        loginButton.clipsToBounds = true
        
        // Style the register button
        registerButton.clipsToBounds = true
    }
}
