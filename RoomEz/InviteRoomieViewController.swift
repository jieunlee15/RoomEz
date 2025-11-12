import UIKit
import FirebaseFirestore
import FirebaseAuth

class InviteRoomieViewController: UIViewController {
    
    @IBOutlet weak var generatedCodeLabel: UITextField!
    let db = Firestore.firestore()

    override func viewDidLoad() {
        super.viewDidLoad()
        let newCode = generateRandomCode()
        generatedCodeLabel.text = newCode
        
        // Save this new room code to Firestore
        createRoomInFirestore(code: newCode)
    }

    func generateRandomCode(length: Int = 4) -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).compactMap { _ in characters.randomElement() })
    }

    @IBAction func copyCodeTapped(_ sender: UIButton) {
        if let code = generatedCodeLabel.text {
            UIPasteboard.general.string = code
            let alert = UIAlertController(title: "Copied",
                message: "Roommate code copied to clipboard.",
                preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }

    // Creates a new room group in Firestore and adds current user to it
    func createRoomInFirestore(code: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let roomRef = db.collection("roommateGroups").document(code)

        roomRef.setData([
            "code": code,
            "members": [uid],
            "createdAt": Timestamp()
        ]) { error in
            if let error = error {
                print("Error creating room: \(error)")
            } else {
                print("Room created with code: \(code)")
            }
        }
    }
}
