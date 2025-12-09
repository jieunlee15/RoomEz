import UIKit
import FirebaseAuth
import FirebaseFirestore

class MainTabBarController: UITabBarController, UITabBarControllerDelegate {
    var roomCode: String? {
        didSet {
            propagateRoomCodeToChildren()
        }
    }

    private func propagateRoomCodeToChildren() {
        for vc in viewControllers ?? [] {
            if let nav = vc as? UINavigationController,
               let annVC = nav.viewControllers.first as? AnnouncementViewController {
                annVC.setRoomCode(roomCode)
            }
        }
    }

    
    private let db = Firestore.firestore()
    private var roomListener: ListenerRegistration?
    
    // Controls lock state + initial landing tab
    private var userHasRoom: Bool = false {
        didSet {
            updateTabBarLockState()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.delegate = self
        observeRoomMembership()
    }
    
    deinit {
        roomListener?.remove()
    }
    
    // MARK: - Listen for whether the user is in a room
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
    
    // MARK: - Lock / unlock tabs and choose which tab to show
    private func updateTabBarLockState() {
        guard let items = tabBar.items else { return }
        
        if userHasRoom {
            // User is in a room → unlock everything
            for item in items {
                item.isEnabled = true
            }
            
            // After login / app launch: send them to Home
            // (Only do this if they're not already on Home)
            if selectedIndex != 0 {
                selectedIndex = 0   // Home tab
            }
        } else {
            // User is NOT in a room → only allow Messages + Profile
            for (index, item) in items.enumerated() {
                item.isEnabled = (index == 2 || index == 3)
            }
            
            // Always keep them on Messages when no room
            if selectedIndex != 2 {
                selectedIndex = 2   // Messages tab
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
        
        // In a room or selecting Messages/Profile → allow
        return true
    }
    
    // Optional manual override if you ever need it
    func setUserHasRoom(_ hasRoom: Bool) {
        userHasRoom = hasRoom
    }
}
