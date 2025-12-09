import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class ProfileViewController: UIViewController,
                             UITableViewDelegate,
                             UITableViewDataSource,
                             UIImagePickerControllerDelegate,
                             UINavigationControllerDelegate {
    
    // MARK: - UI Outlets
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var editPhotoButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var roomCodeLabel: UILabel!
    
    // MARK: - Data
    let rows = ["Edit Profile", "Password", "Notification", "Leave Room"]
    var notificationOn = true
    let db = Firestore.firestore()
    var topBlackView: UIView?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 44
        tableView.tableFooterView = UIView()
        tableView.separatorInset = .zero
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "OptionCell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadUserData()
        loadRoomCode()
        loadSettingsFromFirestore()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupTopBlackView()
        profileImageView.layer.cornerRadius = profileImageView.frame.width / 2
        profileImageView.clipsToBounds = true
        setupEditPhotoButton()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        profileImageView.contentMode = .scaleAspectFill
        nameLabel.font = UIFont.boldSystemFont(ofSize: 24)
        nameLabel.textAlignment = .center
        emailLabel.font = UIFont.systemFont(ofSize: 16)
        emailLabel.textColor = .secondaryLabel
        emailLabel.textAlignment = .center
        logoutButton.clipsToBounds = true
    }
    
    private func setupTopBlackView() {
        guard topBlackView == nil else { return }
        let viewToAdd = UIView()
        viewToAdd.backgroundColor = UIColor(red: 24/255, green: 24/255, blue: 24/255, alpha: 1)
        viewToAdd.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(viewToAdd)
        view.sendSubviewToBack(viewToAdd)
        NSLayoutConstraint.activate([
            viewToAdd.topAnchor.constraint(equalTo: view.topAnchor),
            viewToAdd.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            viewToAdd.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            viewToAdd.bottomAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: -23)
        ])
        topBlackView = viewToAdd
    }
    
    private func setupEditPhotoButton() {
        editPhotoButton.tintColor = .white
        editPhotoButton.layer.shadowOpacity = 0.2
        editPhotoButton.layer.shadowRadius = 4
        editPhotoButton.layer.shadowOffset = CGSize(width: 0, height: 2)
    }
    
    // MARK: - Load Data
    func loadRoomCode() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            if let data = snapshot?.data(),
               let roomCode = data["currentRoomCode"] as? String,
               !roomCode.isEmpty {
                DispatchQueue.main.async { self.roomCodeLabel.text = "Room Code: \(roomCode)" }
            } else {
                DispatchQueue.main.async { self.roomCodeLabel.text = "No room code" }
            }
        }
    }
    
    private func loadUserData() {
        guard let user = Auth.auth().currentUser else {
            nameLabel.text = "Guest"
            emailLabel.text = ""
            profileImageView.image = UIImage(systemName: "person.circle.fill")
            profileImageView.tintColor = .gray
            return
        }
        nameLabel.text = user.displayName ?? "User"
        emailLabel.text = user.email
        let uid = user.uid
        
        db.collection("users").document(uid).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            guard let data = snapshot?.data() else { return }
            
            if let firstName = data["firstName"] as? String {
                var fullName = firstName
                if let lastName = data["lastName"] as? String, !lastName.isEmpty {
                    fullName += " \(lastName)"
                }
                DispatchQueue.main.async { self.nameLabel.text = fullName }
            }
            
            if let base64String = data["profileImageBase64"] as? String,
               let imageData = Data(base64Encoded: base64String),
               let profileImage = UIImage(data: imageData) {
                DispatchQueue.main.async {
                    self.profileImageView.image = profileImage
                    self.profileImageView.tintColor = .clear
                }
            } else {
                DispatchQueue.main.async {
                    self.profileImageView.image = UIImage(systemName: "person.circle.fill")
                    self.profileImageView.tintColor = .gray
                }
            }
        }
    }
    
    private func loadSettingsFromFirestore() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).getDocument { [weak self] snapshot, _ in
            guard let self = self else { return }
            if let data = snapshot?.data() {
                self.notificationOn = data["notificationOn"] as? Bool ?? true
                self.tableView.reloadData()
            }
        }
    }
    
    // MARK: - TableView
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { rows.count }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let rowTitle = rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "OptionCell", for: indexPath)
        cell.textLabel?.text = rowTitle
        cell.textLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        
        if rowTitle == "Notification" {
            let toggle = UISwitch()
            toggle.isOn = notificationOn
            toggle.tag = indexPath.row
            toggle.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
            toggle.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            let container = UIView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
            container.addSubview(toggle)
            toggle.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                toggle.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                toggle.centerYAnchor.constraint(equalTo: container.centerYAnchor)
            ])
            cell.accessoryView = container
            cell.selectionStyle = .none
        } else {
            cell.accessoryView = nil
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selected = rows[indexPath.row]
        
        switch selected {
        case "Edit Profile":
            pushEditProfile()
        case "Password":
            presentTextInputAlert(title: "Change Password",
                                  placeholder: "New Password",
                                  isSecure: true) { [weak self] pw in
                self?.updateFirebasePassword(pw)
            }
        case "Leave Room":
            presentLeaveRoomAlert()
        default:
            break
        }
    }
    
    // MARK: - Edit Profile
    private func pushEditProfile() {
        guard let storyboard = self.storyboard,
              let editVC = storyboard.instantiateViewController(
                withIdentifier: "EditProfileViewController"
              ) as? EditProfileViewController else { return }
        
        let fullName = nameLabel.text ?? ""
        let parts = fullName.split(separator: " ")
        if let first = parts.first { editVC.currentFirstName = String(first) }
        if parts.count > 1 { editVC.currentLastName = parts.dropFirst().joined(separator: " ") }
        editVC.currentEmail = emailLabel.text
        
        navigationController?.pushViewController(editVC, animated: true)
    }
    
    // MARK: - Leave Room
    func presentLeaveRoomAlert() {
        let alert = UIAlertController(title: "Leave Room",
                                      message: "Are you sure you want to leave this room? You will be logged out immediately.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Leave", style: .destructive) { [weak self] _ in
            self?.leaveRoom()
        })
        present(alert, animated: true)
    }
    
    private func leaveRoom() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("roommateGroups").whereField("members", arrayContains: uid)
            .getDocuments { [weak self] snapshot, _ in
                guard let self = self else { return }
                snapshot?.documents.forEach { $0.reference.updateData(["members": FieldValue.arrayRemove([uid])]) }
                self.db.collection("users").document(uid).setData(["currentRoomCode": ""], merge: true)
                UserDefaults.standard.removeObject(forKey: "currentRoomCode")
                self.updateTabBarItems(disableFirstTwo: true)
                self.logoutUser()
            }
    }
    
    // MARK: - Logout
    @IBAction func logoutPressed(_ sender: UIButton) {
        logoutUser()
    }
    
    private func logoutUser() {
        UserDefaults.standard.removeObject(forKey: "currentRoomCode")
        do {
            try Auth.auth().signOut()
            if let loginVC = storyboard?.instantiateViewController(withIdentifier: "LoginViewController") {
                let navController = UINavigationController(rootViewController: loginVC)
                navController.modalPresentationStyle = .fullScreen
                view.window?.rootViewController = navController
                view.window?.makeKeyAndVisible()
            }
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
    
    private func updateTabBarItems(disableFirstTwo: Bool) {
        if let tabBar = tabBarController {
            for (index, item) in (tabBar.tabBar.items ?? []).enumerated() {
                item.isEnabled = !disableFirstTwo || index >= 2
            }
            if disableFirstTwo { tabBar.selectedIndex = 2 }
        }
    }
    
    // MARK: - Switch
    @objc func switchChanged(_ sender: UISwitch) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).setData(["notificationOn": sender.isOn], merge: true)
    }
    
    // MARK: - Alerts
    func presentTextInputAlert(title: String, placeholder: String, isSecure: Bool, completion: @escaping (String) -> Void) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = placeholder
            tf.isSecureTextEntry = isSecure
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            if let text = alert.textFields?.first?.text, !text.isEmpty { completion(text) }
        })
        present(alert, animated: true)
    }
    
    private func updateFirebasePassword(_ newPassword: String) {
        Auth.auth().currentUser?.updatePassword(to: newPassword) { error in
            if let error = error { print("Error updating password: \(error.localizedDescription)") }
        }
    }
    
    // MARK: - Photo Editing
    @IBAction func editPhotoButtonPressed(_ sender: UIButton) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        let alert = UIAlertController(title: "Select Photo", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Take Photo", style: .default) { _ in
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                picker.sourceType = .camera
                self.present(picker, animated: true)
            }
        })
        alert.addAction(UIAlertAction(title: "Choose from Library", style: .default) { _ in
            picker.sourceType = .photoLibrary
            self.present(picker, animated: true)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        guard let selectedImage = info[.editedImage] as? UIImage ??
                info[.originalImage] as? UIImage else { return }
        profileImageView.image = selectedImage
        uploadProfilePhotoToFirebase(selectedImage)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    private func uploadProfilePhotoToFirebase(_ image: UIImage) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let targetSize = CGSize(width: 256, height: 256)
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: targetSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        guard let finalImage = resizedImage,
              let imageData = finalImage.jpegData(compressionQuality: 0.7) else { return }
        let base64String = imageData.base64EncodedString()
        db.collection("users").document(uid).setData(["profileImageBase64": base64String], merge: true)
    }
}
