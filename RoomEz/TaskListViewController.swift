import UIKit
import FirebaseAuth
import FirebaseFirestore

class DateCell: UICollectionViewCell {
    @IBOutlet weak var dayLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var monthLabel: UILabel!
}

class TaskListViewController: UIViewController,
                              UITableViewDataSource,
                              UITableViewDelegate,
                              UICollectionViewDataSource,
                              UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var calendarCollectionView: UICollectionView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentControl: UISegmentedControl!
    
    private let db = Firestore.firestore()
    private var userID: String?
    private var roomCode: String?
    private var tasksListener: ListenerRegistration?
    
    var dates: [Date] = []
    let calendar = Calendar.current
    var selectedDate: Date?
    var allTasks: [RoomTask] = []
    var filteredTasks: [RoomTask] = []
    
    private var notificationsEnabled = true
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Tasks"
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 110
        
        calendarCollectionView.dataSource = self
        calendarCollectionView.delegate = self
        
        generateDates()
        selectedDate = dates.first
        
        loadNotificationPreference()
        loadUserAndRoomData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        segmentChanged(segmentControl)
    }
    
    deinit {
        tasksListener?.remove()
    }
    
    // MARK: - Load Preferences
    private func loadNotificationPreference() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).getDocument { [weak self] snap, _ in
            guard let self = self else { return }
            if let data = snap?.data() {
                self.notificationsEnabled = data["notificationOn"] as? Bool ?? true
            }
        }
    }
    
    // MARK: - Load Room Data
    private func loadUserAndRoomData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        userID = uid
        
        db.collection("roommateGroups")
            .whereField("members", arrayContains: uid)
            .getDocuments { [weak self] snap, error in
                guard let self = self else { return }
                if let error = error {
                    print("Error fetching room: \(error)")
                    return
                }
                guard let doc = snap?.documents.first else {
                    print("No room found for user")
                    return
                }
                self.roomCode = doc.documentID
                self.startListeningToTasks()
            }
    }
    
    // MARK: - Task Listener
    private func startListeningToTasks() {
        guard let code = roomCode else { return }
        
        tasksListener?.remove()
        tasksListener = db.collection("rooms").document(code).collection("tasks")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { [weak self] snap, error in
                guard let self = self else { return }
                if let error = error {
                    print("Error fetching tasks: \(error)")
                    return
                }
                guard let docs = snap?.documents else { return }
                
                self.allTasks = docs.compactMap { RoomTask.fromDocument($0.data()) }
                self.filterTasks()
                self.tableView.reloadData()
            }
    }
    
    // MARK: - Save / Delete Task
    func saveTask(_ task: RoomTask) {
        guard let code = roomCode else { return }
        db.collection("rooms").document(code).collection("tasks")
            .document(task.id.uuidString)
            .setData(task.toDictionary(), merge: true)
    }
    
    func deleteTask(_ task: RoomTask) {
        guard let code = roomCode else { return }
        db.collection("rooms").document(code).collection("tasks")
            .document(task.id.uuidString)
            .delete()
    }
    
    // MARK: - Calendar
    func generateDates() {
        let today = Date()
        for i in 0..<7 {
            if let nextDate = calendar.date(byAdding: .day, value: i, to: today) {
                dates.append(nextDate)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dates.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DateCell", for: indexPath) as! DateCell
        let date = dates[indexPath.item]
        
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMM"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d"
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "E"
        
        cell.monthLabel.text = monthFormatter.string(from: date)
        cell.dateLabel.text = dateFormatter.string(from: date)
        cell.dayLabel.text = dayFormatter.string(from: date)
        
        if let selected = selectedDate, calendar.isDate(selected, inSameDayAs: date) {
            cell.backgroundColor = .black
            cell.monthLabel.textColor = .white
            cell.dateLabel.textColor = .white
            cell.dayLabel.textColor = .white
        } else {
            cell.backgroundColor = .clear
            cell.monthLabel.textColor = .black
            cell.dateLabel.textColor = .black
            cell.dayLabel.textColor = .darkGray
        }
        
        cell.layer.cornerRadius = 12
        cell.layer.borderWidth = 1
        cell.layer.borderColor = UIColor.black.withAlphaComponent(0.1).cgColor
        cell.clipsToBounds = true
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        selectedDate = dates[indexPath.item]
        filterTasks()
        tableView.reloadData()
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 70, height: 80)
    }
    
    // MARK: - Segmented Control
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        filterTasks()
        tableView.reloadData()
    }
    
    func filterTasks() {
        switch segmentControl.selectedSegmentIndex {
        case 0: // All
            filteredTasks = allTasks
        case 1: // To Do
            filteredTasks = allTasks.filter { $0.status == .todo }
        case 2: // In Progress
            filteredTasks = allTasks.filter { $0.status == .inProgress }
        case 3: // Done
            filteredTasks = allTasks.filter { $0.status == .done }
        default:
            filteredTasks = allTasks
        }
        
        if let selected = selectedDate {
            filteredTasks = filteredTasks.filter {
                guard let due = $0.dueDate else { return true } // no due date shows on all days
                return calendar.isDate(due, inSameDayAs: selected)
            }
        }
        
        // (Optional) Sort so overdue tasks float to top
        filteredTasks.sort { lhs, rhs in
            let now = Date()
            let lOver = (lhs.dueDate ?? now) < now && lhs.status != .done
            let rOver = (rhs.dueDate ?? now) < now && rhs.status != .done
            if lOver != rOver { return lOver && !rOver }
            return (lhs.dueDate ?? now) < (rhs.dueDate ?? now)
        }
    }
    
    // MARK: - Table View
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredTasks.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath) as! TaskCell
        let task = filteredTasks[indexPath.row]
        cell.configure(with: task)  // TaskCell should show "Overdue" label when appropriate
        
        cell.onStatusTapped = { [weak self, weak tableView, weak cell] in
            guard let self = self,
                  let tableView = tableView,
                  let cell = cell,
                  let idx = tableView.indexPath(for: cell) else { return }
            
            var updatedTask = self.filteredTasks[idx.row]
            
            switch updatedTask.status {
            case .todo:       updatedTask.status = .inProgress
            case .inProgress: updatedTask.status = .done
            case .done:       updatedTask.status = .todo
            }
            
            self.saveTask(updatedTask)
            self.filteredTasks[idx.row] = updatedTask
            tableView.reloadRows(at: [idx], with: .automatic)
            self.showBanner(message: "Status: \(updatedTask.status.rawValue)")
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {
        
        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, done in
            guard let self = self else { return }
            let taskToDelete = self.filteredTasks[indexPath.row]
            self.deleteTask(taskToDelete)
            self.filteredTasks.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            self.showBanner(message: "Task deleted")
            done(true)
        }
        
        let edit = UIContextualAction(style: .normal, title: "Edit") { [weak self] _, _, done in
            guard let self = self else { return }
            let taskToEdit = self.filteredTasks[indexPath.row]
            self.presentEditor(task: taskToEdit)
            done(true)
        }
        edit.backgroundColor = .systemBlue
        
        return UISwipeActionsConfiguration(actions: [delete, edit])
    }
    
    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        let selectedTask = filteredTasks[indexPath.row]
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let detailVC = storyboard.instantiateViewController(withIdentifier: "TaskDetailViewController") as? TaskDetailViewController {
            detailVC.task = selectedTask
            detailVC.taskIndex = indexPath.row
            detailVC.currentRoomCode = self.roomCode
            navigationController?.pushViewController(detailVC, animated: true)
        }
    }
    
    // MARK: - New Task
    @IBAction func addTaskTapped(_ sender: UIBarButtonItem) {
        presentEditor(task: nil)
    }
    
    private func presentEditor(task: RoomTask?) {
        performSegue(withIdentifier: "showNewTask", sender: task)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showNewTask",
           let dest = segue.destination as? NewTaskViewController {
            dest.delegate = self
            dest.editingTask = sender as? RoomTask
        }
    }
    
    // MARK: - Banner
    func showBanner(message: String) {
        guard notificationsEnabled else { return }
        
        let bannerHeight: CGFloat = 60
        let banner = UIView()
        banner.backgroundColor = .systemBlue
        banner.layer.cornerRadius = 12
        banner.layer.shadowOpacity = 0.3
        banner.layer.shadowOffset = CGSize(width: 0, height: 2)
        banner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(banner)
        
        let label = UILabel()
        label.text = message
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        banner.addSubview(label)
        
        let top = banner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,
                                              constant: -bannerHeight)
        NSLayoutConstraint.activate([
            banner.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            banner.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            banner.heightAnchor.constraint(equalToConstant: bannerHeight),
            top,
            label.leadingAnchor.constraint(equalTo: banner.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: banner.trailingAnchor, constant: -12),
            label.topAnchor.constraint(equalTo: banner.topAnchor),
            label.bottomAnchor.constraint(equalTo: banner.bottomAnchor)
        ])
        
        view.layoutIfNeeded()
        top.constant = 16
        
        UIView.animate(withDuration: 0.45,
                       delay: 0,
                       usingSpringWithDamping: 0.85,
                       initialSpringVelocity: 0.4,
                       options: [],
                       animations: {
            self.view.layoutIfNeeded()
        })
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            UIView.animate(withDuration: 0.25, animations: {
                banner.transform = CGAffineTransform(translationX: 0,
                                                     y: -bannerHeight - 20)
                banner.alpha = 0
            }, completion: { _ in
                banner.removeFromSuperview()
            })
        }
    }
}

// MARK: - NewTaskDelegate
extension TaskListViewController: NewTaskDelegate {
    func didCreateTask(_ task: RoomTask) {
        saveTask(task)
    }
    
    func didUpdateTask(_ task: RoomTask, at index: Int) {
        saveTask(task)
    }
}
