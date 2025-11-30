//  ProfileViewController.swift
//  RoomEz
//  Created by Shriya Venkataraman on 11/11/25.

import UIKit
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

class ProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var editPhotoButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var logoutButton: UIButton!
    
    let rows = ["Edit Profile", "Password", "Notification", "Anonymous"]
    var notificationOn = true
    var anonymousOn = false
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadUserData()
        loadSettingsFromFirestore()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 44
        tableView.tableFooterView = UIView()
        tableView.separatorInset = .zero
    }
    
    // MARK: - Layout Fix: Circular Image Timing
    
    // Calculate corner radius AFTER Auto Layout has set the final frame (needed for circular image)
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let topBlackView = UIView()
        topBlackView.backgroundColor = UIColor(
            red: 24/255,
            green: 24/255,
            blue: 24/255,
            alpha: 1
        )
        topBlackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topBlackView)
        view.sendSubviewToBack(topBlackView) // ensures profile image is on top

        NSLayoutConstraint.activate([
            topBlackView.topAnchor.constraint(equalTo: view.topAnchor),
            topBlackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBlackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topBlackView.bottomAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: -23)
        ])
        profileImageView.layer.cornerRadius = profileImageView.frame.width / 2
        profileImageView.clipsToBounds = true
        
        editPhotoButton.tintColor = .white
        editPhotoButton.layer.shadowOpacity = 0.2
        editPhotoButton.layer.shadowRadius = 4
        editPhotoButton.layer.shadowOffset = CGSize(width: 0, height: 2)

    }
    private func setupUI() {
        profileImageView.image = UIImage(systemName: "person.circle.fill")
        profileImageView.tintColor = .gray
        profileImageView.contentMode = .scaleAspectFill
        
        nameLabel.font = UIFont.boldSystemFont(ofSize: 24) // ⭐ Updated to match mockup
        nameLabel.textAlignment = .center
        
        emailLabel.font = UIFont.systemFont(ofSize: 16)
        emailLabel.textColor = .secondaryLabel
        emailLabel.textAlignment = .center

        logoutButton.setTitle("Log out", for: .normal)
        logoutButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        logoutButton.layer.borderWidth = 1
        logoutButton.layer.borderColor = UIColor.black.cgColor
        logoutButton.layer.cornerRadius = 10
        logoutButton.clipsToBounds = true
    }
    
    // MARK: - Load Auth & Firestore Data
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
        
        // Load profile photo from Firestore first
        let uid = user.uid
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let data = snapshot?.data(), let photoURLString = data["photoURL"] as? String, let url = URL(string: photoURLString) {
                DispatchQueue.global().async {
                    if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self.profileImageView.image = image
                        }
                    }
                }
            } else if let photoURL = user.photoURL { // fallback to Auth photoURL
                DispatchQueue.global().async {
                    if let data = try? Data(contentsOf: photoURL), let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self.profileImageView.image = image
                        }
                    }
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
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let data = snapshot?.data() {
                self.notificationOn = data["notificationOn"] as? Bool ?? true
                self.anonymousOn = data["anonymousOn"] as? Bool ?? false
                self.tableView.reloadData()
            }
        }
    }
    
    // MARK: - UITableView Data Source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let rowTitle = rows[indexPath.row]
        let cellIdentifier: String
        
        switch rowTitle {
        case "Edit Profile":       cellIdentifier = "profileCell"
        case "Password":           cellIdentifier = "passwordCell"
        case "Notification":       cellIdentifier = "notificationCell"
        case "Anonymous":          cellIdentifier = "anonymousCell"
        default:                   cellIdentifier = "OptionCell"
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)

        cell.textLabel?.text = rowTitle
        cell.textLabel?.font = UIFont(name: "SFProText-Medium", size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .medium)

        if rowTitle == "Notification" || rowTitle == "Anonymous" {
            let toggleSwitch = UISwitch()
            toggleSwitch.isOn = (rowTitle == "Notification") ? notificationOn : anonymousOn
            toggleSwitch.tag = indexPath.row
            toggleSwitch.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
            
            // ⭐ Switch size tweak (24x24)
            toggleSwitch.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)

            // ⭐ Use accessory view container to force alignment to edge
            let container = UIView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))

            container.addSubview(toggleSwitch)
            toggleSwitch.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                toggleSwitch.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                toggleSwitch.centerXAnchor.constraint(equalTo: container.centerXAnchor)
            ])
            cell.accessoryView = container
            cell.selectionStyle = .none
            cell.accessoryType = .none
        } else {
            cell.accessoryView = nil
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
        }
        return cell
    }
    
    // MARK: - UITableView Delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selected = rows[indexPath.row]
        
        switch selected {
        case "Edit Profile":
            presentTextInputAlert(title: "Edit your name", placeholder: "Enter new name") { newName in
                self.nameLabel.text = newName
                self.updateFirebaseDisplayName(newName)
                self.saveProfileDataToFirestore(name: newName)
            }
        case "Password":
            presentTextInputAlert(title: "Change Password", placeholder: "Enter new password", isSecure: true) { newPassword in
                self.updateFirebasePassword(newPassword)
            }
        default:
            break
        }
    }
    
    // MARK: - Switch Handler
    
    @objc func switchChanged(_ sender: UISwitch) {
        let toggleName = rows[sender.tag]
        guard let uid = Auth.auth().currentUser?.uid else { return }
        if toggleName == "Notification" {
            notificationOn = sender.isOn
            db.collection("users").document(uid).setData(["notificationOn": notificationOn], merge: true)
        } else if toggleName == "Anonymous" {
            anonymousOn = sender.isOn
            db.collection("users").document(uid).setData(["anonymousOn": anonymousOn], merge: true)
        }
    }
    
    // MARK: - Popup Alert for Editing Text
    
    func presentTextInputAlert(title: String, placeholder: String, isSecure: Bool = false, completion: @escaping (String) -> Void) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = placeholder
            textField.isSecureTextEntry = isSecure
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            if let text = alert.textFields?.first?.text, !text.isEmpty {
                completion(text)
            }
        })
        present(alert, animated: true)
    }
    
    // MARK: - Update Firebase Data
    
    func updateFirebaseDisplayName(_ newName: String) {
        guard let user = Auth.auth().currentUser else { return }
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = newName
        changeRequest.commitChanges { _ in }
    }
    
    func updateFirebasePassword(_ newPassword: String) {
        Auth.auth().currentUser?.updatePassword(to: newPassword) { error in
            if let error = error {
                print("Error updating password: \(error.localizedDescription)")
            } else {
                print("Password updated successfully")
            }
        }
    }
    
    func saveProfileDataToFirestore(name: String? = nil, photoURL: String? = nil) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        var data: [String: Any] = [:]
        if let name = name { data["displayName"] = name }
        if let photoURL = photoURL { data["photoURL"] = photoURL }
        db.collection("users").document(uid).setData(data, merge: true)
    }
    
    // MARK: - Edit Photo (Upload to Firebase Storage)
    
    // FIX: Added @objc for the #selector in viewDidLoad()
    
    @IBAction func editPhotoButtonPressed(_ sender: UIButton) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true

        // Use .alert to make it centered
        let alert = UIAlertController(title: "Select Photo", message: nil, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Take Photo", style: .default, handler: { _ in
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                picker.sourceType = .camera
                self.present(picker, animated: true)
            }
        }))

        alert.addAction(UIAlertAction(title: "Choose from Album", style: .default, handler: { _ in
            picker.sourceType = .photoLibrary
            self.present(picker, animated: true)
        }))

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(alert, animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            picker.dismiss(animated: true)
            guard let selectedImage = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage else { return }

            // Update UI immediately
            DispatchQueue.main.async {
                self.profileImageView.image = selectedImage
            }

            // Upload to Firebase
            uploadProfilePhotoToFirebase(selectedImage)
        }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    func uploadProfilePhotoToFirebase(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8),
              let user = Auth.auth().currentUser else { return }

        let storageRef = Storage.storage().reference().child("profilePhotos/\(user.uid).jpg")
        storageRef.putData(imageData, metadata: nil) { _, error in
            guard error == nil else { return }
            
            storageRef.downloadURL { url, _ in
                guard let downloadURL = url else { return }
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.photoURL = downloadURL
                changeRequest.commitChanges { _ in
                    self.saveProfileDataToFirestore(photoURL: downloadURL.absoluteString)
                }
            }
        }
    }

        // MARK: - Log Out
        // NOTE: This @IBAction must be present for the Storyboard connection to work.
        @IBAction func logoutPressed(_ sender: UIButton) {
            do {
                // 1. Sign out the current user from Firebase Auth
                try Auth.auth().signOut()
                if let loginVC = storyboard?.instantiateViewController(withIdentifier: "LoginViewController") {
                    navigationController?.setViewControllers([loginVC], animated: true)
                }
            } catch {
                print("Error signing out: \(error.localizedDescription)")
            }
        }
    } // End of class
