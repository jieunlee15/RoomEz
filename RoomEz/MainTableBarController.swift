//
//  MainTabBarController.swift
//  RoomEz
//
//  Created by Ananya Singh on 12/4/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class MainTabBarController: UITabBarController, UITabBarControllerDelegate {
    
    private let db = Firestore.firestore()
    private var roomListener: ListenerRegistration?
    
    // Flip to true once Firestore says the user is in a room
    private var userHasRoom: Bool = false {
        didSet {
            updateTabBarLockState()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.delegate = self
        observeRoomMembership()
        updateTabBarLockState()
    }
    
    deinit {
        roomListener?.remove()
    }
    
    // MARK: - Observe if user is in a room
    private func observeRoomMembership() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        roomListener = db.collection("roommateGroups")
            .whereField("members", arrayContains: uid)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error observing room membership: \(error)")
                    return
                }
                
                let hasRoom = !(snapshot?.documents.isEmpty ?? true)
                print("MainTabBarController: userHasRoom = \(hasRoom)")
                self.userHasRoom = hasRoom
            }
    }
    
    // MARK: - Lock / unlock tabs based on room status
    private func updateTabBarLockState() {
        guard let items = tabBar.items else { return }
        
        if userHasRoom {
            // In a room → all tabs enabled
            for item in items {
                item.isEnabled = true
            }
        } else {
            // NOT in a room → only Messages (2) + Profile/Account (3) enabled
            for (index, item) in items.enumerated() {
                item.isEnabled = (index == 2 || index == 3)
            }
            // Always land on Messages when not in a room
            if selectedIndex != 2 {
                selectedIndex = 2
            }
        }
    }
    
    // MARK: - Intercept tab selection
    func tabBarController(_ tabBarController: UITabBarController,
                          shouldSelect viewController: UIViewController) -> Bool {
        
        guard let vcs = tabBarController.viewControllers,
              let index = vcs.firstIndex(of: viewController) else {
            return true
        }
        
        // When NOT in a room → block Home (0) and Tasks (1)
        if !userHasRoom && !(index == 2 || index == 3) {
            tabBarController.selectedIndex = 2   // stay on Messages
            return false
        }
        
        // In a room or choosing Messages/Profile → allow
        return true
    }
    
    // Optional: manual override if you ever want to flip it from other VCs
    func setUserHasRoom(_ hasRoom: Bool) {
        userHasRoom = hasRoom
    }
}
