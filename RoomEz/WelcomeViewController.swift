import UIKit

class WelcomeViewController: UIViewController {
    
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var registerButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginButton.clipsToBounds = true
        
        registerButton.clipsToBounds = true
    }
}
