import UIKit

class PasswordChangedViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        enableKeyboardDismissOnTap()

    }
    
    @IBAction func backToLoginPressed(_ sender: Any) {
        if let loginVC = storyboard?.instantiateViewController(withIdentifier: "LoginViewController") {
            navigationController?.setViewControllers([loginVC], animated: true)
        }
    }
}
