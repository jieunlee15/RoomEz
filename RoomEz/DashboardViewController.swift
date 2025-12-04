import UIKit
import FirebaseAuth
import FirebaseFirestore

class DashboardViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    // MARK: - Outlets
    @IBOutlet weak var greetingLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var progressContainer: UIView!
    @IBOutlet weak var detailButton: UIButton!
    @IBOutlet weak var profileImageView: UIImageView!
    
    // MARK: - Layers
    private var progressLayer = CAShapeLayer()
    private var trackLayer = CAShapeLayer()
    
    // MARK: - Firestore
    private let db = Firestore.firestore()
    private var roomCode: String?
    private var userID: String?
    
    private var tasksListener: ListenerRegistration?

    // MARK: - Data
    private var allTasks: [RoomTask] = []
    private var filteredTasks: [RoomTask] {
        allTasks.filter { $0.status != .done }
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTable()
        setupCircularProgress()
        fetchUserData()
        loadUserAndRoomData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateProgress()
        fetchUserData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        profileImageView.layer.cornerRadius = profileImageView.bounds.width / 2
        profileImageView.clipsToBounds = true
    }

    deinit {
        tasksListener?.remove()
    }

    // MARK: - UI Setup
    private func setupTable() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 110
        tableView.estimatedRowHeight = 110
        
        let lineView = UIView(frame: CGRect(x: 0,y: 0, width: tableView.bounds.width, height: 0.5))
        lineView.backgroundColor = UIColor.separator
        tableView.tableHeaderView = lineView
        
        profileImageView.image = UIImage(systemName: "person.crop.circle")
        profileImageView.tintColor = .gray
        profileImageView.contentMode = .scaleAspectFill
    }

    // MARK: - Fetch User + Room
    private func fetchUserData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        userID = uid
        
        db.collection("users").document(uid).getDocument { [weak self] snap, _ in
            guard let self = self else { return }
            let data = snap?.data() ?? [:]
            
            let name = data["firstName"] as? String ?? "there"
            self.greetingLabel.text = "Hello \(name)!"
            
            if let base64 = data["profileImageBase64"] as? String,
               let imageData = Data(base64Encoded: base64),
               let img = UIImage(data: imageData) {
                self.profileImageView.image = img
                self.profileImageView.tintColor = .clear
            } else {
                self.profileImageView.image = UIImage(systemName: "person.crop.circle")
                self.profileImageView.tintColor = .gray
            }
        }
    }
    
    private func loadUserAndRoomData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("roommateGroups")
            .whereField("members", arrayContains: uid)
            .getDocuments { [weak self] snap, error in
                guard let self = self else { return }
                if let error = error {
                    print("Error fetching room for dashboard: \(error)")
                    return
                }
                guard let doc = snap?.documents.first else {
                    print("No room for this user")
                    return
                }
                
                self.roomCode = doc.documentID
                self.startListeningToTasks()
            }
    }

    // MARK: - Listen to Firestore Tasks
    private func startListeningToTasks() {
        guard let code = roomCode else { return }
        
        tasksListener?.remove()
        
        tasksListener = db.collection("rooms").document(code).collection("tasks")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { [weak self] snap, error in
                guard let self = self else { return }
                if let error = error {
                    print("Error fetching dashboard tasks: \(error)")
                    return
                }
                guard let docs = snap?.documents else { return }
                
                self.allTasks = docs.compactMap { RoomTask.fromDocument($0.data()) }
                self.tableView.reloadData()
                self.updateProgress()
            }
    }

    // MARK: - Circular Progress
    func setupCircularProgress() {
        let center = CGPoint(x: progressContainer.bounds.midX,
                             y: progressContainer.bounds.midY)
        let radius = min(progressContainer.bounds.width,
                         progressContainer.bounds.height) / 2.5
        
        let path = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: 1.5 * .pi,
            clockwise: true
        )
        
        trackLayer.path = path.cgPath
        trackLayer.strokeColor = UIColor.systemGray5.cgColor
        trackLayer.lineWidth = 10
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.lineCap = .round
        progressContainer.layer.addSublayer(trackLayer)
        
        progressLayer.path = path.cgPath
        progressLayer.strokeColor = UIColor.black.cgColor
        progressLayer.lineWidth = 10
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0
        progressContainer.layer.addSublayer(progressLayer)
    }

    func updateProgress() {
        guard !allTasks.isEmpty else {
            progressLayer.strokeEnd = 0
            progressLabel.text = "0%"
            messageLabel.text = "Let's get started together!"
            return
        }
        
        let done = allTasks.filter { $0.status == .done }.count
        let ratio = CGFloat(done) / CGFloat(allTasks.count)
        
        UIView.animate(withDuration: 0.4) {
            self.progressLayer.strokeEnd = ratio
        }
        
        progressLabel.text = "\(Int(ratio * 100))%"
        
        switch ratio {
        case 0:
            messageLabel.text = "Let's get started together!"
        case 0..<0.85:
            messageLabel.text = "Nice teamwork — we're getting there!"
        case 0.85..<1:
            messageLabel.text = "Almost done — just a few more steps!"
        default:
            messageLabel.text = "All done! Great job, everyone!"
        }
    }

    // MARK: - Segue to Task Tab
    @IBAction func detailPressed(_ sender: Any) {
        performSegue(withIdentifier: "toTaskTabBar", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toTaskTabBar",
           let tab = segue.destination as? UITabBarController {
            tab.selectedIndex = 1   // Tasks tab
        }
    }

    // MARK: - TableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredTasks.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell") as? TaskCell else {
            return UITableViewCell(style: .default, reuseIdentifier: "FallbackCell")
        }
        
        let task = filteredTasks[indexPath.row]
        cell.configure(with: task)   // TaskCell should show overdue label here too
        
        cell.onStatusTapped = { [weak self, weak tableView, weak cell] in
            guard let self = self,
                  let tableView = tableView,
                  let cell = cell,
                  let tappedIndexPath = tableView.indexPath(for: cell) else { return }
            
            let task = self.filteredTasks[tappedIndexPath.row]
            self.toggleTaskStatus(task)
        }
        
        return cell
    }

    private func toggleTaskStatus(_ task: RoomTask) {
        guard let code = roomCode else { return }

        var updated = task
        
        switch task.status {
        case .todo:       updated.status = .inProgress
        case .inProgress: updated.status = .done
        case .done:       updated.status = .todo
        }
        
        db.collection("rooms").document(code).collection("tasks")
            .document(task.id.uuidString)
            .setData(updated.toDictionary(), merge: true)
    }
}
