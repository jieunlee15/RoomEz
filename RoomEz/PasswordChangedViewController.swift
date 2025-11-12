//  PasswordChangedViewController.swift
//  RoomEz
//  Created by Ananya Singh on 11/11/25.

import UIKit

class PasswordChangedViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func backToLoginPressed(_ sender: Any) {
        performSegue(withIdentifier: "backToLogin", sender: self)
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
