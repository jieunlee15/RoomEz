//  MessagesTabRootViewController.swift
//  RoomEz
//  Created by Jieun Lee on 11/28/25.

import UIKit
import FirebaseAuth
import FirebaseFirestore

class MessagesTabRootViewController: UIViewController {
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureMessagesTab()
    }
    
    private func configureMessagesTab() {
        guard let tabBar = tabBarController else {
            print("❌ No tab bar controller found")
            return
        }
        let messagesTabIndex = 2
        tabBar.selectedIndex = messagesTabIndex
        
        guard let nav = tabBar.viewControllers?[messagesTabIndex] as? UINavigationController else { return }
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let userRef = Firestore.firestore().collection("users").document(uid)
        userRef.getDocument { doc, _ in
            let roomCode = doc?.data()?["currentRoomCode"] as? String
            
            if let code = roomCode, !code.isEmpty {
                // Announcement VC
                if let annVC = nav.viewControllers.first as? AnnouncementViewController {
                    annVC.setRoomCode(code)
                } else {
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let annVC = storyboard.instantiateViewController(withIdentifier: "MessagesVC") as! AnnouncementViewController
                    annVC.setRoomCode(code)
                    nav.setViewControllers([annVC], animated: false)
                }
            } else {
                // InitialMessage VC
                if !(nav.viewControllers.first is InitialMessageViewController) {
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let initVC = storyboard.instantiateViewController(withIdentifier: "CreateJoinRoomVC")
                    nav.setViewControllers([initVC], animated: false)
                }
            }
        }
    }
}
