//
//  InitialMessageViewController.swift
//  RoomEz
//
//  Created by Jieun Lee on 10/20/25.
//

import UIKit

class InitialMessageViewController: UIViewController {

    @IBAction func joinRoomTapped(_sender: UIButton) {
        performSegue(withIdentifier: "joinGroup", sender: self)
    }

    @IBAction func createRoomTapped(_sender: UIButton) {
        performSegue(withIdentifier: "showAnnouncements", sender: self)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
