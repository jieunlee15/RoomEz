//  AnnouncementViewController.swift
//  RoomEz
//  Created by Jieun Lee on 10/20/25.

import UIKit
import FirebaseFirestore
import FirebaseAuth

struct Announcement {
    let id: String
    let title: String
    let content: String
    let author: String
    let isAnonymous: Bool
    let date: Date
}

class AnnouncementViewController: UIViewController,  UITableViewDataSource, UITableViewDelegate, NewAnnouncementDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    var announcements: [Announcement] = []
    var roomCode: String?
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var hasLoadedOnce = false
    private var notificationsEnabled = true
    private var lastAnnouncementCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 167
        
        loadNotificationPreference()
        if let code = roomCode {
            startListening(for: code)
        }
    }
    
    deinit {
        listener?.remove()
    }
    
    func setRoomCode(_ code: String) {
        // Remove old listener
        listener?.remove()
        listener = nil
        
        roomCode = code
        hasLoadedOnce = false
        lastAnnouncementCount = 0
        announcements = []
        tableView.reloadData()
        
        startListening(for: code)
    }
    
    // MARK: - Firestore listener
    private func startListening(for code: String) {
        let collection = db.collection("roommateGroups")
            .document(code)
            .collection("announcements")
        
        listener = collection
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                guard let docs = snapshot?.documents else { return }
                
                let now = Date()
                var freshAnnouncements: [Announcement] = []
                var expiredIDs: [String] = []
                
                for doc in docs {
                    let data = doc.data()
                    if data["isArchived"] as? Bool ?? false { continue }
                    
                    if let expiresTS = data["expiresAt"] as? Timestamp,
                       expiresTS.dateValue() < now {
                        expiredIDs.append(doc.documentID)
                        continue
                    }
                    
                    let announcement = Announcement(
                        id: doc.documentID,
                        title: data["title"] as? String ?? "",
                        content: data["content"] as? String ?? "",
                        author: data["author"] as? String ?? "Roommate",
                        isAnonymous: data["isAnonymous"] as? Bool ?? false,
                        date: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    )
                    freshAnnouncements.append(announcement)
                }
                
                if self.hasLoadedOnce,
                   freshAnnouncements.count > self.lastAnnouncementCount {
                    self.showNewAnnouncementBanner()
                }
                
                self.hasLoadedOnce = true
                self.lastAnnouncementCount = freshAnnouncements.count
                self.announcements = freshAnnouncements
                self.tableView.reloadData()
                
                // Archive expired
                for id in expiredIDs {
                    collection.document(id).updateData(["isArchived": true])
                }
            }
    }
    
    // MARK: - User notification setting
    
    private func loadNotificationPreference() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).getDocument { [weak self] snap, _ in
            guard let self = self else { return }
            if let data = snap?.data() {
                self.notificationsEnabled = data["notificationOn"] as? Bool ?? true
            }
        }
    }
    
    // MARK: - Add new announcement
    
    @IBAction func addAnnouncementTapped(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "showNewAnnouncement", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showNewAnnouncement",
           let dest = segue.destination as? NewAnnouncementViewController {
                       dest.delegate = self
            if let code = roomCode {
                dest.roomCode = code
            }
        }
    }
    
    // Delegate called when user taps Submit in the NewAnnouncement screen
    // Delegate called when user taps Submit in the NewAnnouncement screen
    func didPostAnnouncement(_ announcement: Announcement) {
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return announcements.count
    }
    
    func tableView(_ tableView: UITableView,cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "AnnouncementCell",
            for: indexPath
        ) as! AnnouncementCell
        let announcement = announcements[indexPath.row]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd"
        let dateString = dateFormatter.string(from: announcement.date)
        cell.authorLabel.text = "\(announcement.author) | \(dateString)"
        cell.titleLabel.text = announcement.title
        cell.contentLabel.text = announcement.content
        return cell
    }
    // Swipe to delete
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, completion in
            self.deleteAnnouncement(at: indexPath)
            completion(true)
        }
        
        deleteAction.backgroundColor = .systemRed
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    private func deleteAnnouncement(at indexPath: IndexPath) {
        guard let roomCode = roomCode else { return }
        let announcementID = announcements[indexPath.row].id
        db.collection("roommateGroups")
            .document(roomCode)
            .collection("announcements")
            .document(announcementID)
            .delete { error in
                if let error = error {
                    print("❌ Delete failed: \(error.localizedDescription)")
                }
            }
    }

    func showNewAnnouncementBanner() {
        guard notificationsEnabled else { return }
        
        let bannerHeight: CGFloat = 60
        let banner = UIView()
        banner.backgroundColor = .systemBlue
        banner.layer.cornerRadius = 12
        banner.layer.masksToBounds = false
        banner.layer.shadowColor = UIColor.black.cgColor
        banner.layer.shadowOpacity = 0.3
        banner.layer.shadowOffset = CGSize(width: 0, height: 2)
        banner.layer.shadowRadius = 4
        banner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(banner)
        
        let label = UILabel()
        label.text = "New note posted"
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        banner.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: banner.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: banner.trailingAnchor, constant: -12),
            label.topAnchor.constraint(equalTo: banner.topAnchor),
            label.bottomAnchor.constraint(equalTo: banner.bottomAnchor)
        ])
        
        let topConstraint = banner.topAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.topAnchor,
            constant: -bannerHeight
        )
        NSLayoutConstraint.activate([
            banner.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            banner.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            banner.heightAnchor.constraint(equalToConstant: bannerHeight),
            topConstraint
        ])
        view.layoutIfNeeded()
        
        topConstraint.constant = 16
        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 0.5,
                       options: [],
                       animations: {
            self.view.layoutIfNeeded()
        })
        
        let tap = UITapGestureRecognizer(target: self,
                                         action: #selector(dismissBannerView(_:)))
        banner.addGestureRecognizer(tap)
    }
    
    @objc func dismissBannerView(_ sender: UITapGestureRecognizer) {
        guard let banner = sender.view else { return }
        UIView.animate(withDuration: 0.3,
                       animations: {
            banner.transform = CGAffineTransform(
                translationX: 0,
                y: -banner.frame.height - 16
            )
            banner.alpha = 0
        }, completion: { _ in
            banner.removeFromSuperview()
        })
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        listener?.remove()
    }
}
