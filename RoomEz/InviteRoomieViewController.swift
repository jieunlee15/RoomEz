import UIKit
import FirebaseFirestore
import FirebaseAuth

class InviteRoomieViewController: UIViewController {
    @IBOutlet weak var generatedCodeLabel: UITextField!
    let db = Firestore.firestore()
    private var generatedCode: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        enableKeyboardDismissOnTap()
        let newCode = generateRandomCode()
        generatedCodeLabel.text = newCode
        generatedCode = newCode
        createRoomInFirestore(code: newCode)
    }

    func generateRandomCode(length: Int = 4) -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).compactMap { _ in characters.randomElement() })
    }

    @IBAction func copyCodeTapped(_ sender: UIButton) {
        guard let code = generatedCode else { return }
        UIPasteboard.general.string = code
        let alert = UIAlertController(title: "Copied",
                                      message: "Roommate code copied to clipboard.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func createRoomInFirestore(code: String) {
        let roomRef = db.collection("roommateGroups").document(code)
        roomRef.setData([
            "code": code,
            "members": [],
            "createdAt": Timestamp()
        ]) { error in
            if let error = error {
                print("Error creating room: \(error.localizedDescription)")
            } else {
                print("Room created: \(code)")
            }
        }
    }
}



