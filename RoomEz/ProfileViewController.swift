//
//  ProfileViewController.swift
//  RoomEz
//
//  Created by Shriya Venkataraman on 11/11/25.
//
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
    
    // Firestore reference
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadUserData()
        loadSettingsFromFirestore()
        tableView.delegate = self
        tableView.dataSource = self
        editPhotoButton.addTarget(self, action: #selector(onEditPhotoTapped), for: .touchUpInside)
    }
    
    // MARK: - Layout Fix: Circular Image Timing
    
    // Calculate corner radius AFTER Auto Layout has set the final frame (needed for circular image)
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        profileImageView.layer.cornerRadius = profileImageView.frame.width / 2
    }
    
    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        
        profileImageView.image = UIImage(systemName: "person.circle.fill")
        profileImageView.tintColor = .gray
        // NOTE: Corner radius is now set in viewDidLayoutSubviews()
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill
        
        nameLabel.font = UIFont.boldSystemFont(ofSize: 22)
        nameLabel.textAlignment = .center
        
        emailLabel.font = UIFont.systemFont(ofSize: 16)
        emailLabel.textColor = .secondaryLabel
        emailLabel.textAlignment = .center
        
        logoutButton.layer.cornerRadius = 12
        // NOTE: Removed redundant setTitle to fix duplicate "Log Out" text
        logoutButton.backgroundColor = .white
        logoutButton.setTitleColor(.black, for: .normal)
    }
    
    // MARK: - Load Auth & Firestore Data
    private func loadUserData() {
        guard let user = Auth.auth().currentUser else {
            nameLabel.text = "Guest"
            emailLabel.text = ""
            return
        }
        nameLabel.text = user.displayName ?? "User"
        emailLabel.text = user.email
        
        if let photoURL = user.photoURL {
            DispatchQueue.global().async {
                if let data = try? Data(contentsOf: photoURL), let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.profileImageView.image = image
                    }
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
        
        

        
        if rowTitle == "Notification" {
            let toggleSwitch = UISwitch()
            toggleSwitch.isOn = notificationOn
            toggleSwitch.tag = indexPath.row
            toggleSwitch.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
            cell.accessoryView = toggleSwitch
            cell.selectionStyle = .none
            cell.accessoryType = .none // Prevents dual accessories
        } else if rowTitle == "Anonymous" {
            let toggleSwitch = UISwitch()
            toggleSwitch.isOn = anonymousOn
            toggleSwitch.tag = indexPath.row
            toggleSwitch.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
            cell.accessoryView = toggleSwitch
            cell.selectionStyle = .none
            cell.accessoryType = .none // Prevents dual accessories
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
        if let user = Auth.auth().currentUser {
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = newName
            changeRequest.commitChanges { error in
                if let error = error {
                    print("Error updating name: \(error.localizedDescription)")
                } else {
                    print("Display name updated successfully")
                }
            }
        }
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
    @objc func onEditPhotoTapped() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        
        let alert = UIAlertController(title: "Select Photo", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                picker.sourceType = .camera
                self.present(picker, animated: true)
            }
        }))
        alert.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { _ in
            picker.sourceType = .photoLibrary
            self.present(picker, animated: true)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        let selectedImage = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage
        if let image = selectedImage {
            profileImageView.image = image
            uploadProfilePhotoToFirebase(image)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    func uploadProfilePhotoToFirebase(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8),
              let user = Auth.auth().currentUser else { return }
        let storageRef = Storage.storage().reference().child("profilePhotos/\(user.uid).jpg")
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            guard error == nil else {
                print("Upload failed: \(error!.localizedDescription)")
                return
            }
            storageRef.downloadURL { url, error in
                guard let downloadURL = url else {
                    print("No download URL: \(error!.localizedDescription)")
                    return
                }
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.photoURL = downloadURL
                changeRequest.commitChanges { error in
                    if let error = error {
                        print("Failed updating profile photo URL: \(error.localizedDescription)")
                    } else {
                        print("Profile photo URL updated.")
                        // Save photoURL in Firestore
                        self.saveProfileDataToFirestore(photoURL: downloadURL.absoluteString)
                    }
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
                
                // 2. Instantiate and present the Login View Controller (assuming its Storyboard ID is "LoginViewController")
                if let loginVC = storyboard?.instantiateViewController(withIdentifier: "LoginViewController") {
                    loginVC.modalPresentationStyle = .fullScreen
                    present(loginVC, animated: true)
                }
            } catch {
                print("Error signing out: \(error.localizedDescription)")
            }
        }
    } // End of class
