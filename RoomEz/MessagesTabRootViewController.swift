//  MessagesTabRootViewController.swift
//  RoomEz
//  Created by Jieun Lee on 11/28/25.


import UIKit
import FirebaseAuth

class MessagesTabRootViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        showCorrectMessagesVC()
    }
    
    private func showCorrectMessagesVC() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let nextVC: UIViewController
        
        if let roomCode = UserDefaults.standard.string(forKey: "currentRoomCode"), !roomCode.isEmpty {
            // User is in a room → go to announcements
            guard let announcementVC = storyboard.instantiateViewController(withIdentifier: "MessagesVC") as? AnnouncementViewController else {
                print("❌ Could not instantiate AnnouncementViewController")
                return
            }
            announcementVC.roomCode = roomCode
            nextVC = announcementVC
        } else {
            // User not in a room → show join/create room screen
            guard let createJoinVC = storyboard.instantiateViewController(withIdentifier: "CreateJoinRoomVC") as? UIViewController else {
                print("❌ Could not instantiate CreateJoinRoomVC")
                return
            }
            nextVC = createJoinVC
        }
        
        // If this VC is inside a navigation controller
        if let navController = self.navigationController {
            navController.setViewControllers([nextVC], animated: false)
        } else if let tabBarController = self.tabBarController,
                  var vcs = tabBarController.viewControllers,
                  let index = vcs.firstIndex(of: self) {
            vcs[index] = nextVC
            tabBarController.setViewControllers(vcs, animated: false)
        } else {
            present(nextVC, animated: false)
        }
    }
}


