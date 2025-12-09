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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
