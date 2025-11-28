//  MessagesTabRootViewController.swift
//  RoomEz
//  Created by Jieun Lee on 11/28/25.

import UIKit

class MessagesTabRootViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        showCorrectMessagesVC()
    }
    
    private func showCorrectMessagesVC() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let nextVC: UIViewController
        
        if let _ = UserDefaults.standard.string(forKey: "currentRoomCode") {
            // User is in a room → go to announcements
            nextVC = storyboard.instantiateViewController(withIdentifier: "MessagesVC")
        } else {
            // User not in a room → show initial join/create screen
            nextVC = storyboard.instantiateViewController(withIdentifier: "CreateJoinRoomVC")
        }
        
        // If Messages tab is a navigation controller
        if let navController = self.navigationController {
            navController.setViewControllers([nextVC], animated: false)
        } else if let tabBarController = self.tabBarController,
                  var vcs = tabBarController.viewControllers,
                  let index = vcs.firstIndex(of: self) {
            // Replace the tab's root view controller
            vcs[index] = nextVC
            tabBarController.setViewControllers(vcs, animated: false)
        } else {
            // Fallback: present modally if all else fails
            present(nextVC, animated: false)
        }
    }
}


