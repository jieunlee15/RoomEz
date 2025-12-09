import UIKit
import FirebaseAuth
import FirebaseFirestore

class LoginViewController: UIViewController {
    
    @IBOutlet weak var errorMessage: UILabel!
    @IBOutlet weak var emailText: UITextField!
    @IBOutlet weak var passwordText: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        enableKeyboardDismissOnTap()
        
        loginButton.clipsToBounds = true
        errorMessage.text = ""
        errorMessage.textColor = .systemRed
        errorMessage.font = .systemFont(ofSize: 14, weight: .medium)
        passwordText.isSecureTextEntry = true
        
        addShowPasswordButton(to: passwordText)
    }
        
        // MARK: - Show/Hide Password
        private func addShowPasswordButton(to textField: UITextField) {
            let textFieldHeight = textField.frame.height
            let padding: CGFloat = 8
            
            let button = UIButton(type: .custom)
            button.setImage(UIImage(systemName: "eye"), for: .normal)
            button.tintColor = .gray
            button.frame = CGRect(x: 0, y: 0, width: textFieldHeight * 0.6, height: textFieldHeight * 0.6) // scale icon relative to text field height
            button.addTarget(self, action: #selector(togglePasswordVisibility(_:)), for: .touchUpInside)
            
            // Container to add padding
            let container = UIView(frame: CGRect(x: 0, y: 0, width: button.frame.width + padding * 2, height: textFieldHeight))
            button.center = CGPoint(x: container.bounds.width/2, y: container.bounds.height/2)
            container.addSubview(button)
            
            textField.rightView = container
            textField.rightViewMode = .always
        }

        @objc private func togglePasswordVisibility(_ sender: UIButton) {
            guard let textField = sender.superview as? UITextField ?? sender.superview?.superview as? UITextField else { return }
            textField.isSecureTextEntry.toggle()
            
            let imageName = textField.isSecureTextEntry ? "eye" : "eye.slash"
            sender.setImage(UIImage(systemName: imageName), for: .normal)
            
            // Fix cursor jumping issue
            let currentText = textField.text
            textField.text = ""
            textField.text = currentText
        }
    
    
    func goToMainTabs(userHasRoom: Bool) {
        guard let tabBar = storyboard?.instantiateViewController(withIdentifier: "MainTabBar") as? MainTabBarController else { return }

        tabBar.setUserHasRoom(userHasRoom)
        tabBar.selectedIndex = 2
        
        // FIX: Present modally exactly like your OG login flow did
        tabBar.modalPresentationStyle = .fullScreen
        self.present(tabBar, animated: true, completion: nil)
    }

    @IBAction func loginButtonPressed(_ sender: Any) {
        guard let email = emailText.text, !email.isEmpty,
              let password = passwordText.text, !password.isEmpty else {
            errorMessage.text = "Please enter both email and password."
            return
        }

        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }
            
            if let error = error {
                self.errorMessage.text = error.localizedDescription
                return
            }

            self.errorMessage.text = ""
            self.goToMainTabs(userHasRoom: false)
        }
    }
}

