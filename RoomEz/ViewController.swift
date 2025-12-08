//  ViewController.swift
//  RoomEz
//  Created by Jieun Lee on 10/18/25.

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }


}

// MARK: - Keyboard Dismiss Helper

extension UIViewController {

    func enableKeyboardDismissOnTap() {
        let tap = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissKeyboardOnTap)
        )
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboardOnTap() {
        view.endEditing(true)
    }
}


// Adding comment to test github -- Ananya
