import UIKit
import FirebaseAuth
import FirebaseFirestore

class DashboardViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var greetingLabel: UILabel?
    @IBOutlet weak var messageLabel: UILabel?
    @IBOutlet weak var progressLabel: UILabel?
    @IBOutlet weak var tableView: UITableView?
    @IBOutlet weak var progressContainer: UIView?
    @IBOutlet weak var detailButton: UIButton?
    @IBOutlet weak var profileImageView: UIImageView?
    
    private var progressLayer = CAShapeLayer()
    private var trackLayer = CAShapeLayer()
    
    private let db = Firestore.firestore()
    private var roomCode: String?
    private var userID: String?
    private var tasksListener: ListenerRegistration?
    
    private var allTasks: [RoomTask] = []
    private var filteredTasks: [RoomTask] {
        allTasks.filter { $0.status != .done }
    }
    
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
        if let imageView = profileImageView {
            imageView.layer.cornerRadius = imageView.bounds.width / 2
            imageView.clipsToBounds = true
            imageView.layer.borderWidth = 1
            imageView.layer.borderColor = UIColor(hex: "#4F9BDE").cgColor
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showTaskDetailFromDashboard",
           let dest = segue.destination as? TaskDetailViewController,
           let task = sender as? RoomTask {
            
            dest.task = task
            dest.roomCode = self.roomCode   // <— THIS is the important part
        }
    }


    
    deinit {
        tasksListener?.remove()
    }
    
    // MARK: - UI Setup
    
    private func setupTable() {
        tableView?.dataSource = self
        tableView?.delegate = self
        tableView?.rowHeight = 110
        tableView?.estimatedRowHeight = 110
        
        if let tv = tableView {
            let lineView = UIView(frame: CGRect(x: 0, y: 0, width: tv.bounds.width, height: 0.5))
            lineView.backgroundColor = UIColor.separator
            tv.tableHeaderView = lineView
        }
        
        if let imageView = profileImageView {
            imageView.image = UIImage(systemName: "person.crop.circle")
            imageView.tintColor = .gray
            imageView.contentMode = .scaleAspectFill
        }
    }
    
    // MARK: - User + Room
    
    private func fetchUserData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        userID = uid
        
        db.collection("users").document(uid).getDocument { [weak self] snap, _ in
            guard let self = self else { return }
            let data = snap?.data() ?? [:]
            
            let name = data["firstName"] as? String ?? "there"
            self.greetingLabel?.text = "Hello \(name)!"
            
            if let base64 = data["profileImageBase64"] as? String,
               let imageData = Data(base64Encoded: base64),
               let img = UIImage(data: imageData) {
                self.profileImageView?.image = img
                self.profileImageView?.tintColor = .clear
            } else {
                self.profileImageView?.image = UIImage(systemName: "person.crop.circle")
                self.profileImageView?.tintColor = .gray
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
    
    // MARK: - Task listener
    
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
                self.tableView?.reloadData()
                self.updateProgress()
            }
    }
    
    // MARK: - Circular progress
    
    func setupCircularProgress() {
        guard let container = progressContainer else { return }
        
        let center = CGPoint(x: container.bounds.midX,
                             y: container.bounds.midY)
        let radius = min(container.bounds.width,
                         container.bounds.height) / 2.5
        
        let path = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: 1.5 * .pi,
            clockwise: true
        )
        progressLabel?.textColor = UIColor(hex: "#305B9D")
        
        trackLayer.path = path.cgPath
        trackLayer.strokeColor = UIColor.systemGray5.cgColor
        trackLayer.lineWidth = 10
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.lineCap = .round
        container.layer.addSublayer(trackLayer)
        
        progressLayer.path = path.cgPath
        progressLayer.strokeColor = UIColor(hex: "#305B9D").cgColor
        progressLayer.lineWidth = 10
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0
        container.layer.addSublayer(progressLayer)
    }
    
    func updateProgress() {
        guard !allTasks.isEmpty else {
            progressLayer.strokeEnd = 0
            progressLabel?.text = "0%"
            messageLabel?.text = "Let's get started together!"
            return
        }
        
        let done = allTasks.filter { $0.status == .done }.count
        let ratio = CGFloat(done) / CGFloat(allTasks.count)
        
        UIView.animate(withDuration: 0.4) {
            self.progressLayer.strokeEnd = ratio
        }
        
        progressLabel?.text = "\(Int(ratio * 100))%"
        
        switch ratio {
        case 0:
            messageLabel?.text = "Let's get started together!"
        case 0..<0.85:
            messageLabel?.text = "Nice teamwork — we're getting there!"
        case 0.85..<1:
            messageLabel?.text = "Almost done — just a few more steps!"
        default:
            messageLabel?.text = "All done! Great job, everyone!"
        }
    }
    
    // MARK: - Segue to Tasks tab
    
    @IBAction func detailPressed(_ sender: Any) {
        tabBarController?.selectedIndex = 1
    }
    
    
    
    // MARK: - Table view
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredTasks.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell") as? TaskCell else {
            return UITableViewCell(style: .default, reuseIdentifier: "FallbackCell")
        }
        
        let task = filteredTasks[indexPath.row]
        cell.configure(with: task)
        
        cell.onStatusTapped = { [weak self, weak tableView, weak cell] in
            guard let self = self,
                  let tableView = tableView,
                  let cell = cell,
                  let tappedIndexPath = tableView.indexPath(for: cell) else { return }
            
            let tappedTask = self.filteredTasks[tappedIndexPath.row]
            self.toggleTaskStatus(tappedTask)
        }
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {

        tableView.deselectRow(at: indexPath, animated: true)

        guard indexPath.row < filteredTasks.count else { return }

        let task = filteredTasks[indexPath.row]
        performSegue(withIdentifier: "showTaskDetailFromDashboard", sender: task)
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
