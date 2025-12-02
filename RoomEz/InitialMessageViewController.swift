//  InitialMessageViewController.swift
//  RoomEz
//  Created by Jieun Lee on 10/20/25.

import UIKit

class InitialMessageViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        /*if UserDefaults.standard.string(forKey: "currentRoomCode") != nil {
            performSegue(withIdentifier: "showAnnouncements", sender: self)
        }*/
        
    }
}
