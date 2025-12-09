import UIKit
import FirebaseFirestore
import FirebaseAuth

class AnnouncementViewController: UIViewController,
                                 UITableViewDataSource,
                                 UITableViewDelegate,
                                 NewAnnouncementDelegate,
                                 AnnouncementCellDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    var announcements: [Announcement] = []
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var hasLoadedOnce = false
    private var notificationsEnabled = true
    private var lastAnnouncementCount = 0
    
    var roomCode: String? {
        didSet {
            if isViewLoaded {
                startListening(for: roomCode)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Announcements"
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 167
        
        if let code = roomCode {
            startListening(for: code)
        }
    }
    
    deinit {
        listener?.remove()
    }
    
    func setRoomCode(_ code: String?) {
        self.roomCode = code
    }
    
    // MARK: - Live Firestore Listener
    private func startListening(for roomCode: String?) {
        listener?.remove()
        guard let code = roomCode, !code.isEmpty else { return }
        
        let collection = db.collection("roommateGroups")
            .document(code)
            .collection("announcements")
        
        listener = collection
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                guard let documents = snapshot?.documents else { return }
                
                let now = Date()
                var freshAnnouncements: [Announcement] = []
                var expiredIDs: [String] = []
                
                for doc in documents {
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
                
                // Archive expired announcements
                for id in expiredIDs {
                    collection.document(id).updateData(["isArchived": true])
                }
            }
    }
    
    // MARK: - Add Announcement
    @IBAction func addAnnouncementTapped(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "showNewAnnouncement", sender: self)
    }
    
    // MARK: - Prepare for Segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "commentsSegue",
           let dest = segue.destination as? CommentsViewController,
           let announcement = sender as? Announcement {

            guard let roomCode = self.roomCode else {
                print("ERROR: roomCode is nil in AnnouncementViewController")
                return
            }

            dest.roomCode = roomCode
            dest.announcementID = announcement.id
            dest.announcement = announcement
        }
        
        if segue.identifier == "showNewAnnouncement",
           let dest = segue.destination as? NewAnnouncementViewController {
            dest.delegate = self
            dest.roomCode = roomCode
        }
    }

    func didPostAnnouncement(_ announcement: Announcement) {
        tableView.reloadData()
    }
    
    // MARK: - TableView
    
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return announcements.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "AnnouncementCell",
            for: indexPath
        ) as! AnnouncementCell
        
        let announcement = announcements[indexPath.row]
        cell.configure(with: announcement, delegate: self)
        return cell
    }
    
    // MARK: - AnnouncementCellDelegate
    
    func didTapComments(for announcementID: String) {
        guard let announcement = announcements.first(where: { $0.id == announcementID }) else { return }
        
        // Get a reference to your Storyboard
        let storyboard = UIStoryboard(name: "Main", bundle: nil) // Change "Main" if your storyboard has a different name
        
        // Instantiate the View Controller using the Storyboard ID
        guard let commentsVC = storyboard.instantiateViewController(withIdentifier: "CommentsViewControllerID") as? CommentsViewController else {
            fatalError("Failed to instantiate CommentsViewController from Storyboard.")
        }
        
        // Pass the required data to the instance
        commentsVC.announcement = announcement
        commentsVC.announcementID = announcement.id
        commentsVC.roomCode = self.roomCode
        
        // Push the instantiated object
        navigationController?.pushViewController(commentsVC, animated: true)
    }
    // MARK: - Swipe to Delete
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, completion in
            self.deleteAnnouncement(at: indexPath)
            completion(true)
        }
        
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
                if let e = error { print("Delete failed: \(e)") }
            }
    }
    
    // MARK: - Banner
    
    func showNewAnnouncementBanner() {
        guard notificationsEnabled else { return }
        
        let bannerHeight: CGFloat = 60
        let banner = UIView()
        banner.backgroundColor = .systemBlue
        banner.layer.cornerRadius = 12
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
                       animations: { self.view.layoutIfNeeded() })
        
        let tap = UITapGestureRecognizer(target: self,
                                         action: #selector(dismissBannerView(_:)))
        banner.addGestureRecognizer(tap)
    }
    
    @objc func dismissBannerView(_ sender: UITapGestureRecognizer) {
        guard let banner = sender.view else { return }
        
        UIView.animate(withDuration: 0.3, animations: {
            banner.transform = CGAffineTransform(translationX: 0, y: -80)
            banner.alpha = 0
        }, completion: { _ in banner.removeFromSuperview() })
    }
}
