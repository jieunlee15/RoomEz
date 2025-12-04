//
//  MainTableBarController.swift
//  RoomEz
//
//  Created by Ananya Singh on 12/4/25.
//
//  Handles custom tab bar behavior:
//  - If the user is not in a room yet, Home/Task/Message all just show
//    the same "No room yet" screen on the Messages tab.
//  - Account still works normally so they can manage their profile/log out.

import UIKit

class MainTabBarController: UITabBarController, UITabBarControllerDelegate {
    
    // Flip this to true once the user has joined or created a room.
    var userHasRoom: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Want to intercept tab bar selections.
        self.delegate = self
        
        // If the user doesn’t have a room yet, land them on the Messages tab (index 2), which shows the "No room yet" view.
        if !userHasRoom {
            self.selectedIndex = 2
        }
    }
    
    // This runs whenever the user taps a tab.
    func tabBarController(_ tabBarController: UITabBarController,
                          shouldSelect viewController: UIViewController) -> Bool {
        
        // Figure out which tab index they tapped.
        guard let vcs = tabBarController.viewControllers,
              let index = vcs.firstIndex(of: viewController) else {
            return true
        }
        
        // While the user isn’t in a room:
        // - Block Home (0), Task (1), and Message (2) from switching to other screens
        // - Always keep them on the Messages tab instead
        // - Allow Account (3) to work normally
        if !userHasRoom && index != 3 {
            tabBarController.selectedIndex = 2   // Messages tab
            return false
        }
        
        // Once userHasRoom is true, all tabs work like normal.
        return true
    }
    
    // Call from other view controllers when the user gets a room.
    func setUserHasRoom(_ hasRoom: Bool) {
        self.userHasRoom = hasRoom
    }
}
