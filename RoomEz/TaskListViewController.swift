import UIKit
import FirebaseAuth
import FirebaseFirestore

class DateCell: UICollectionViewCell {
    @IBOutlet weak var dayLabel: UILabel?
    @IBOutlet weak var dateLabel: UILabel?
    @IBOutlet weak var monthLabel: UILabel?
}

class TaskListViewController: UIViewController,
                              UITableViewDataSource,
                              UITableViewDelegate,
                              UICollectionViewDataSource,
                              UICollectionViewDelegateFlowLayout {

    // MARK: - Outlets (Optional to Avoid Crashes)
    @IBOutlet weak var calendarCollectionView: UICollectionView?
    @IBOutlet weak var tableView: UITableView?
    @IBOutlet weak var segmentControl: UISegmentedControl?

    // MARK: - Properties
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

        // Table Setup
        tableView?.dataSource = self
        tableView?.delegate = self
        tableView?.rowHeight = 110

        // Calendar Setup
        calendarCollectionView?.dataSource = self
        calendarCollectionView?.delegate = self

        generateDates()
        selectedDate = dates.first

        loadNotificationPreference()
        loadUserAndRoomData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let seg = segmentControl {
            segmentChanged(seg)
        }
    }

    deinit {
        tasksListener?.remove()
    }

    // MARK: - Notification Preference
    private func loadNotificationPreference() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(uid).getDocument { [weak self] snap, _ in
            guard let self = self else { return }

            self.notificationsEnabled = snap?.data()?["notificationOn"] as? Bool ?? true
        }
    }

    // MARK: - Load Room & Tasks
    private func loadUserAndRoomData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        self.userID = uid

        db.collection("roommateGroups")
            .whereField("members", arrayContains: uid)
            .getDocuments { [weak self] snap, error in
                guard let self = self else { return }

                if let error = error {
                    print("Error finding room: \(error)")
                    return
                }

                guard let doc = snap?.documents.first else {
                    print("No room found")
                    return
                }

                self.roomCode = doc.documentID
                self.startListeningToTasks()
            }
    }

    private func startListeningToTasks() {
        guard let code = roomCode else { return }

        tasksListener?.remove()

        tasksListener = db.collection("rooms").document(code).collection("tasks")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { [weak self] snap, error in
                
                guard let self = self else { return }

                if let error = error {
                    print("Error listening for tasks: \(error)")
                    return
                }

                guard let docs = snap?.documents else { return }

                self.allTasks = docs.compactMap { RoomTask.fromDocument($0.data()) }
                self.filterTasks()
                self.tableView?.reloadData()
            }
    }

    // MARK: - Save / Delete
    func saveTask(_ task: RoomTask) {
        guard let code = roomCode else { return }

        db.collection("rooms").document(code)
            .collection("tasks").document(task.id.uuidString)
            .setData(task.toDictionary(), merge: true)
    }

    func deleteTask(_ task: RoomTask) {
        guard let code = roomCode else { return }

        db.collection("rooms").document(code)
            .collection("tasks").document(task.id.uuidString)
            .delete()
    }

    // MARK: - Calendar Setup
    func generateDates() {
        let today = Date()
        for i in 0..<7 {
            if let next = calendar.date(byAdding: .day, value: i, to: today) {
                dates.append(next)
            }
        }
    }

    // MARK: - Collection View
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return dates.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DateCell",
                                                      for: indexPath) as! DateCell
        let date = dates[indexPath.item]

        let monthFmt = DateFormatter(); monthFmt.dateFormat = "MMM"
        let dateFmt = DateFormatter(); dateFmt.dateFormat = "d"
        let dayFmt = DateFormatter(); dayFmt.dateFormat = "E"

        cell.monthLabel?.text = monthFmt.string(from: date)
        cell.dateLabel?.text = dateFmt.string(from: date)
        cell.dayLabel?.text = dayFmt.string(from: date)

        if let selected = selectedDate,
           calendar.isDate(selected, inSameDayAs: date) {

            cell.backgroundColor = .black
            [cell.monthLabel, cell.dateLabel, cell.dayLabel].forEach { $0?.textColor = .white }

        } else {
            cell.backgroundColor = .clear
            cell.monthLabel?.textColor = .black
            cell.dateLabel?.textColor = .black
            cell.dayLabel?.textColor = .darkGray
        }

        cell.layer.cornerRadius = 12
        cell.layer.borderWidth = 1
        cell.layer.borderColor = UIColor.black.withAlphaComponent(0.1).cgColor

        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {

        selectedDate = dates[indexPath.item]
        filterTasks()
        tableView?.reloadData()
        calendarCollectionView?.reloadData()
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 70, height: 80)
    }

    // MARK: - Segmented Control
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        filterTasks()
        tableView?.reloadData()
    }

    // MARK: - Filtering Logic
    func filterTasks() {

        switch segmentControl?.selectedSegmentIndex {
        case 1:
            filteredTasks = allTasks.filter { $0.status == .todo }
        case 2:
            filteredTasks = allTasks.filter { $0.status == .inProgress }
        case 3:
            filteredTasks = allTasks.filter { $0.status == .done }
        default:
            filteredTasks = allTasks
        }

        if let selected = selectedDate {
            filteredTasks = filteredTasks.filter {
                guard let due = $0.dueDate else { return true }
                return calendar.isDate(due, inSameDayAs: selected)
            }
        }

        // Sort (overdue first)
        filteredTasks.sort { lhs, rhs in
            let now = Date()
            let leftOverdue = (lhs.dueDate ?? now) < now && lhs.status != .done
            let rightOverdue = (rhs.dueDate ?? now) < now && rhs.status != .done

            if leftOverdue != rightOverdue { return leftOverdue }

            return (lhs.dueDate ?? now) < (rhs.dueDate ?? now)
        }
    }

    // MARK: - Table View
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return filteredTasks.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell") as? TaskCell else {
            return UITableViewCell(style: .default, reuseIdentifier: "Fallback")
        }

        let task = filteredTasks[indexPath.row]
        cell.configure(with: task)

        cell.onStatusTapped = { [weak self, weak tableView, weak cell] in
            guard let self = self,
                  let tableView = tableView,
                  let cell = cell,
                  let idx = tableView.indexPath(for: cell) else { return }

            var updated = self.filteredTasks[idx.row]
            let oldStatus = updated.status

            switch updated.status {
            case .todo:       updated.status = .inProgress
            case .inProgress: updated.status = .done
            case .done:       updated.status = .todo
            }

            self.saveTask(updated)
            self.filteredTasks[idx.row] = updated
            tableView.reloadRows(at: [idx], with: .automatic)

            self.showBanner(message: "Status: \(updated.status.rawValue)")

            if oldStatus != .done,
               updated.status == .done,
               let nextTask = self.nextOccurrence(for: updated) {
                self.saveTask(nextTask)
            }
        }

        return cell
    }

    // MARK: - Repeating Tasks
    private func nextOccurrence(for task: RoomTask) -> RoomTask? {
        guard let due = task.dueDate else { return nil }

        var component: Calendar.Component
        let step = 1

        switch task.frequency {
        case .none:
            return nil
        case .daily:
            component = .day
        case .weekly:
            component = .weekOfYear
        case .monthly:
            component = .month
        }

        guard let newDue = calendar.date(byAdding: component, value: step, to: due) else { return nil }

        return RoomTask(
            title: task.title,
            details: task.details,
            dueDate: newDue,
            assignee: task.assignee,
            status: .todo,
            priority: task.priority,
            createdAt: Date(),
            updatedAt: nil,
            completionPercent: 0.0,
            reminderSet: task.reminderSet,
            frequency: task.frequency
        )
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

        } else if segue.identifier == "showTaskDetail",
                  let dest = segue.destination as? TaskDetailViewController,
                  let task = sender as? RoomTask {

            dest.task = task
            dest.roomCode = self.roomCode   // ← UNCOMMENT / ADD THIS
        
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

        let top = banner.topAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.topAnchor,
            constant: -bannerHeight
        )

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
    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {

        tableView.deselectRow(at: indexPath, animated: true)

        // Safety: make sure the row still exists in filteredTasks
        guard indexPath.row < filteredTasks.count else { return }

        let task = filteredTasks[indexPath.row]
        performSegue(withIdentifier: "showTaskDetail", sender: task)
    }
}

// MARK: - Delegate
extension TaskListViewController: NewTaskDelegate {
    func didCreateTask(_ task: RoomTask) {
        saveTask(task)
    }

    func didUpdateTask(_ task: RoomTask, at index: Int) {
        saveTask(task)
    }
}
