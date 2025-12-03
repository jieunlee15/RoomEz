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
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 44
        tableView.tableFooterView = UIView()
        tableView.separatorInset = .zero
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadUserData()          // refresh name/photo/email every time
        loadSettingsFromFirestore()
    }
    
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
        
        profileImageView.contentMode = .scaleAspectFill
                
        nameLabel.font = UIFont.boldSystemFont(ofSize: 24)
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
        
        // Temporarily keep the current picture while loading — prevents flicker
        let currentImage = profileImageView.image

        db.collection("users").document(uid).getDocument { snapshot, _ in
            let data = snapshot?.data()
            var didLoadImage = false

            if let urlStr = data?["photoURL"] as? String,
               !urlStr.isEmpty,
               let url = URL(string: urlStr) {
                didLoadImage = true
                self.downloadAndSetImage(url)
            }

            if !didLoadImage, let authPhotoURL = user.photoURL {
                didLoadImage = true
                self.downloadAndSetImage(authPhotoURL)
            }

            if !didLoadImage {
                DispatchQueue.main.async {
                    // Only apply default if we truly have no saved pic
                    if currentImage == nil {
                        self.profileImageView.image = UIImage(systemName: "person.circle.fill")
                        self.profileImageView.tintColor = .gray
                    }
                }
            }
        }
    }

    
    private func downloadAndSetImage(_ url: URL) {
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil,
                  let image = UIImage(data: data) else { return }

            DispatchQueue.main.async {
                self.profileImageView.image = image
            }
        }.resume()
    }
    
    private func loadSettingsFromFirestore() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).getDocument { snapshot, _ in
            if let data = snapshot?.data() {
                self.notificationOn = data["notificationOn"] as? Bool ?? true
                self.anonymousOn = data["anonymousOn"] as? Bool ?? false
                self.tableView.reloadData()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let rowTitle = rows[indexPath.row]
        let cellIdentifier: String
        
        switch rowTitle {
        case "Edit Profile": cellIdentifier = "profileCell"
        case "Password": cellIdentifier = "passwordCell"
        case "Notification": cellIdentifier = "notificationCell"
        case "Anonymous": cellIdentifier = "anonymousCell"
        default: cellIdentifier = "OptionCell"
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        cell.textLabel?.text = rowTitle
        cell.textLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        
        if rowTitle == "Notification" || rowTitle == "Anonymous" {
            let toggleSwitch = UISwitch()
            toggleSwitch.isOn = (rowTitle == "Notification") ? notificationOn : anonymousOn
            toggleSwitch.tag = indexPath.row
            toggleSwitch.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
            toggleSwitch.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            
            let container = UIView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
            container.addSubview(toggleSwitch)
            toggleSwitch.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                toggleSwitch.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                toggleSwitch.centerYAnchor.constraint(equalTo: container.centerYAnchor)
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selected = rows[indexPath.row]
            
        switch selected {
        case "Edit Profile":
            presentTextInputAlert(title: "Edit Name", placeholder: "Enter new name") { newName in
                self.nameLabel.text = newName
                self.updateFirebaseDisplayName(newName)
                self.saveProfileDataToFirestore(name: newName)
            }
        case "Password":
            presentTextInputAlert(title: "Change Password", placeholder: "Enter new password", isSecure: true) { newPassword in
                self.updateFirebasePassword(newPassword)
            }
        default: break
        }
    }
    
    @objc func switchChanged(_ sender: UISwitch) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let rowTitle = rows[sender.tag]
            
        if rowTitle == "Notification" {
            notificationOn = sender.isOn
            db.collection("users").document(uid).setData(["notificationOn": notificationOn], merge: true)
        } else if rowTitle == "Anonymous" {
            anonymousOn = sender.isOn
            db.collection("users").document(uid).setData(["anonymousOn": anonymousOn], merge: true)
        }
    }
    
    func presentTextInputAlert(title: String, placeholder: String, isSecure: Bool = false, completion: @escaping (String) -> Void) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = placeholder
            tf.isSecureTextEntry = isSecure
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            if let text = alert.textFields?.first?.text, !text.isEmpty {
                completion(text)
            }
        })
        present(alert, animated: true)
    }
            
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
            
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            picker.dismiss(animated: true)
            guard let selectedImage = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage else { return }
            self.profileImageView.image = selectedImage
            uploadProfilePhotoToFirebase(selectedImage)
        }
            
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
            
    func uploadProfilePhotoToFirebase(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8),
              let user = Auth.auth().currentUser else {
            print("❌ No user")
            return
        }

        let uid = user.uid
        let storageRef = Storage.storage().reference()
            .child("profilePhotos/\(uid).jpg")

        print("⬆️ Uploading image for user: \(uid)")

        storageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                print("❌ Upload failed: \(error.localizedDescription)")
                return
            }
            print("☁️ Upload success")

            storageRef.downloadURL { url, _ in
                guard let downloadURL = url else {
                    print("❌ Failed to get downloadURL")
                    return
                }
                print("🔗 Got downloadURL: \(downloadURL.absoluteString)")

                // Update FirebaseAuth FIRST
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.photoURL = downloadURL

                changeRequest.commitChanges { error in
                    if let error = error {
                        print("❌ Auth update failed: \(error.localizedDescription)")
                    } else {
                        print("👤 FirebaseAuth updated with new photoURL")
                    }

                    // Now Firestore
                    self.db.collection("users").document(uid)
                        .setData(["photoURL": downloadURL.absoluteString], merge: true) { error in
                        
                            if let error = error {
                                print("❌ Firestore save failed: \(error.localizedDescription)")
                            } else {
                                print("🔥 Firestore photoURL saved successfully!")
                            }

                            DispatchQueue.main.async {
                                self.loadUserData()
                            }
                        }
                }
            }
        }
    }



        
    // MARK: - Log Out
    // NOTE: This @IBAction must be present for the Storyboard connection to work.
    @IBAction func logoutPressed(_ sender: UIButton) {
        do {
            try Auth.auth().signOut()
            UserDefaults.standard.removeObject(forKey: "currentRoomCode")
            if let loginVC = storyboard?.instantiateViewController(withIdentifier: "LoginViewController") {
                navigationController?.setViewControllers([loginVC], animated: true)
            }
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}
