import UIKit
import FirebaseAuth
import FirebaseFirestore

class MessagesTabRootViewController: UIViewController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureMessagesTab()
    }

    private func configureMessagesTab() {
        guard let tabBar = tabBarController,
              let nav = tabBar.viewControllers?[2] as? UINavigationController,
              let uid = Auth.auth().currentUser?.uid else { return }

        let userRef = Firestore.firestore().collection("users").document(uid)
        userRef.getDocument { doc, _ in
            let roomCode = doc?.data()?["currentRoomCode"] as? String

            if let code = roomCode, !code.isEmpty,
               !(nav.viewControllers.first is AnnouncementViewController) {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                if let annVC = storyboard.instantiateViewController(withIdentifier: "MessagesVC") as? AnnouncementViewController {
                    annVC.setRoomCode(code)
                    nav.setViewControllers([annVC], animated: false)
                }
            } else if roomCode == nil || roomCode!.isEmpty,
                      !(nav.viewControllers.first is InitialMessageViewController) {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let initVC = storyboard.instantiateViewController(withIdentifier: "CreateJoinRoomVC")
                nav.setViewControllers([initVC], animated: false)
            }
        }
    }
}
