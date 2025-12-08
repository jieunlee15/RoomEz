

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class RegisterViewController: UIViewController {
    
    @IBOutlet weak var firstName: UITextField!
    @IBOutlet weak var lastName: UITextField!
    @IBOutlet weak var errorMessage: UILabel!
    @IBOutlet weak var emailText: UITextField!
    @IBOutlet weak var passwordText: UITextField!
    @IBOutlet weak var confirmPasswordText: UITextField!
    @IBOutlet weak var registerButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerButton.clipsToBounds = true
        errorMessage.text = ""
        errorMessage.textColor = .systemRed
        errorMessage.font = .systemFont(ofSize: 14, weight: .medium)
    }
    
    
    // MARK: - Navigate to Main Tab Bar
    func goToMainTabs(userHasRoom: Bool) {
        guard let tabBar = storyboard?.instantiateViewController(withIdentifier: "MainTabBar") as? MainTabBarController else { return }

        tabBar.setUserHasRoom(userHasRoom)
        tabBar.selectedIndex = 2
        
        // FIX: Present modally exactly like your OG login flow did
        tabBar.modalPresentationStyle = .fullScreen
        self.present(tabBar, animated: true, completion: nil)
    }
    
    
    // MARK: - Register User
    @IBAction func registerButtonPressed(_ sender: Any) {
        guard let fName = firstName.text, !fName.isEmpty,
              let lName = lastName.text, !lName.isEmpty,
              let email = emailText.text, !email.isEmpty,
              let password = passwordText.text, !password.isEmpty,
              let confirmPassword = confirmPasswordText.text, !confirmPassword.isEmpty else {
            errorMessage.text = "Please fill in all fields."
            return
        }
        
        guard password == confirmPassword else {
            errorMessage.text = "Passwords do not match."
            return
        }
        
        // Create account
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                self.errorMessage.text = error.localizedDescription
                return
            }
            
            self.errorMessage.text = ""
            
            // Auto-login to ensure full session init
            Auth.auth().signIn(withEmail: email, password: password) { result, error in
                if let error = error {
                    self.errorMessage.text = "Login failed: \(error.localizedDescription)"
                    return
                }
                
                guard let user = result?.user else { return }
                let displayName = "\(fName) \(lName)"
                
                // Update Auth Profile
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.displayName = displayName
                changeRequest.commitChanges(completion: nil)
                
                // Save Firestore doc
                let userData: [String: Any] = [
                    "firstName": fName,
                    "lastName": lName,
                    "displayName": displayName,
                    "email": email,
                    "photoURL": "",
                    "notificationOn": true,
                    "anonymousOn": false,
                    "currentRoomCode": "",
                    "createdAt": Timestamp()
                ]
                
                Firestore.firestore().collection("users").document(user.uid).setData(userData)
                
                // Navigate to app
                self.goToMainTabs(userHasRoom: false)
            }
        }
    }
}
