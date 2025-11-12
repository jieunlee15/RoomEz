//  AnnouncementViewController.swift
//  RoomEz
//  Created by Jieun Lee on 10/20/25.

import UIKit
import FirebaseFirestore
import FirebaseAuth

struct Announcement {
    let title: String
    let content: String
    let author: String
    let isAnonymous: Bool
    let date: Date
}

class AnnouncementViewController: UIViewController,  UITableViewDataSource, UITableViewDelegate, NewAnnouncementDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    var announcements: [Announcement] = []
        
        // This should be set by the previous screen (room code user joined)
        var roomCode: String?
        
        private let db = Firestore.firestore()
        private var listener: ListenerRegistration?
        private var hasLoadedOnce = false
        private var notificationsEnabled = true
        
        // Lifetime for an announcement before it is archived (in days)
        private let noteLifetimeDays = 7
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            tableView.dataSource = self
            tableView.delegate = self
            tableView.rowHeight = UITableView.automaticDimension
            tableView.estimatedRowHeight = 167
            
            loadNotificationPreference()
            startListeningForAnnouncements()
        }
        
        deinit {
            listener?.remove()
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
        
        // MARK: - Firestore listener
        
        private func startListeningForAnnouncements() {
            guard let roomCode = roomCode else {
                print("roomCode not set on AnnouncementViewController")
                return
            }
            
            let announcementsRef = db.collection("roommateGroups")
                .document(roomCode)
                .collection("announcements")
            
            listener = announcementsRef
                .whereField("isArchived", isEqualTo: false)
                .order(by: "createdAt", descending: true)
                .addSnapshotListener { [weak self] snapshot, error in
                    guard let self = self else { return }
                    if let error = error {
                        print("Error listening for announcements: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let snapshot = snapshot else { return }
                    
                    let now = Date()
                    var updatedAnnouncements: [Announcement] = []
                    var docsToArchive: [DocumentReference] = []
                    
                    for doc in snapshot.documents {
                        let data = doc.data()
                        
                        let title = data["title"] as? String ?? ""
                        let content = data["content"] as? String ?? ""
                        let authorName = data["authorName"] as? String ?? "User"
                        let isAnonymous = data["isAnonymous"] as? Bool ?? false
                        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                        let expiresAt = (data["expiresAt"] as? Timestamp)?.dateValue()
                        
                        // If expired, schedule it to be archived and skip it for the list
                        if let expiresAt = expiresAt, expiresAt <= now {
                            docsToArchive.append(doc.reference)
                            continue
                        }
                        
                        let announcement = Announcement(
                            title: title,
                            content: content,
                            author: authorName,
                            isAnonymous: isAnonymous,
                            date: createdAt
                        )
                        updatedAnnouncements.append(announcement)
                    }
                    
                    self.announcements = updatedAnnouncements
                    self.tableView.reloadData()
                    
                    // Mark expired notes as archived
                    for ref in docsToArchive {
                        ref.updateData(["isArchived": true])
                    }
                    
                    // Show banner only for new additions after the first load
                    if self.hasLoadedOnce {
                        let newChanges = snapshot.documentChanges.filter { $0.type == .added }
                        if !newChanges.isEmpty && self.notificationsEnabled {
                            self.showNewAnnouncementBanner()
                        }
                    } else {
                        self.hasLoadedOnce = true
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
            }
        }
        
        // Delegate called when user taps Submit in the NewAnnouncement screen
        func didPostAnnouncement(_ announcement: Announcement) {
            // Save to Firestore; the listener will handle updating the array and UI
            guard let roomCode = roomCode else {
                print("roomCode missing when posting announcement")
                return
            }
            guard let currentUser = Auth.auth().currentUser else { return }
            
            let roomRef = db.collection("roommateGroups").document(roomCode)
            let announcementsRef = roomRef.collection("announcements")
            
            let now = Date()
            let expiresAt = Calendar.current.date(byAdding: .day,
                                                  value: noteLifetimeDays,
                                                  to: now) ?? now
            
            let data: [String: Any] = [
                "title": announcement.title,
                "content": announcement.content,
                "authorName": announcement.author,
                "authorId": currentUser.uid,
                "isAnonymous": announcement.isAnonymous,
                "createdAt": Timestamp(date: now),
                "expiresAt": Timestamp(date: expiresAt),
                "isArchived": false
            ]
            
            announcementsRef.addDocument(data: data) { error in
                if let error = error {
                    print("Error saving announcement: \(error.localizedDescription)")
                } else {
                    // For the user who posted, you already see the note in the list
                    // The banner for others will trigger from the snapshot listener
                }
            }
        }
        
        // MARK: - Table view
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return announcements.count
        }
        
        func tableView(_ tableView: UITableView,
                       cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
        
        // MARK: - Banner
        
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
    }
