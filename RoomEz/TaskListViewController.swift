//  TaskListViewController.swift
//  RoomEz
//  Created by Kirti Ganesh on 10/22/25.

import UIKit

class DateCell: UICollectionViewCell {
    @IBOutlet weak var dayLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var monthLabel: UILabel!
}

class TaskListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    var dates: [Date] = []
    let calendar = Calendar.current
    var selectedDate: Date?

    @IBOutlet weak var calendarCollectionView: UICollectionView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentControl: UISegmentedControl! // FIXED: should be UISegmentedControl

    private var taskManager = TaskManager.shared
    var filteredTasks: [RoomTask] = [] // FIXED: added filtered array

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Task"
        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsSelection = true
        tableView.rowHeight = 110
        tableView.estimatedRowHeight = 110
        
        calendarCollectionView.dataSource = self
        calendarCollectionView.delegate = self
        
        generateDates()
        selectedDate = dates.first

        filteredTasks = taskManager.tasks // start with all tasks
    }
    
    func generateDates() {
        let today = Date()
        for i in 0..<7 {
            if let nextDate = calendar.date(byAdding: .day, value: i, to: today) {
                dates.append(nextDate)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        segmentChanged(segmentControl)
    }

    // MARK: - Segmented Control
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        filterTasks()
        tableView.reloadData()
    }

    func filterTasks() {
        switch segmentControl.selectedSegmentIndex {
        case 0:
            // All tasks
            filteredTasks = taskManager.tasks
        case 1:
            // To Do
            filteredTasks = taskManager.tasks.filter { $0.status == .todo }
        case 2:
            // In Progress (and maybe due date tasks)
            filteredTasks = taskManager.tasks.filter { $0.status == .inProgress && $0.dueDate != nil }
        case 3:
            // Done
            filteredTasks = taskManager.tasks.filter { $0.status == .done }
        default:
            filteredTasks = taskManager.tasks
        }
                // Optional: filter by selected date
        if let selected = selectedDate {
            filteredTasks = filteredTasks.filter {
            guard let due = $0.dueDate else { return true }
            return calendar.isDate(due, inSameDayAs: selected)
            }
        }
    }
    
    // MARK: - Collection View (Calendar)
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dates.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
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

        // Highlight selected date
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


    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedDate = dates[indexPath.item]
        filterTasks()
        tableView.reloadData()
        collectionView.reloadData()
    }

    // Layout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 70, height: 80)
    }


    // MARK: - Add Task
    @IBAction func addTaskTapped(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "showNewTask", sender: self)
    }

    // MARK: - Table View
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredTasks.count
    }
    
    private func presentEditor(task: RoomTask?, index: Int? = nil) {
            performSegue(withIdentifier: "showNewTask", sender: (task, index))
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showNewTask",
            let dest = segue.destination as? NewTaskViewController {
                
            dest.delegate = self
                
            if let (task, index) = sender as? (RoomTask, Int) {
                    // Editing existing task
                dest.editingTask = task
                dest.editingIndex = index
            } else {
                    // Creating new task
                dest.editingTask = nil
                dest.editingIndex = nil
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedTask = filteredTasks[indexPath.row]
        
        // Instantiate from storyboard
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let detailVC = storyboard.instantiateViewController(withIdentifier: "TaskDetailViewController") as? TaskDetailViewController {
            detailVC.task = selectedTask
            detailVC.taskIndex = indexPath.row
            navigationController?.pushViewController(detailVC, animated: true)
        }
    }


    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath) as! TaskCell
        let task = filteredTasks[indexPath.row]
        cell.configure(with: task)

        cell.onStatusTapped = { [weak self, weak tableView, weak cell] in
            guard
                let self = self,
                let tableView = tableView,
                let cell = cell,
                let tappedIndexPath = tableView.indexPath(for: cell)
            else { return }

            var t = self.filteredTasks[tappedIndexPath.row]
            // Cycle through statuses
            switch t.status {
            case .todo:
                t.status = .inProgress
            case .inProgress:
                t.status = .done
            case .done:
                t.status = .todo
            }

            // Update both arrays
            if let originalIndex = self.taskManager.tasks.firstIndex(where: {$0.id == t.id }) {
                self.taskManager.updateTask(t, at: originalIndex)
            }
            self.filteredTasks[tappedIndexPath.row] = t

            tableView.reloadRows(at: [tappedIndexPath], with: .automatic)
            self.showBanner(message: "Status: \(t.status.rawValue)")
        }

        return cell
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {

        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, done in
            guard let self = self else { return }

            let taskToDelete = self.filteredTasks[indexPath.row]
            self.taskManager.tasks.removeAll { $0.id == taskToDelete.id }
            self.filteredTasks.remove(at: indexPath.row)

            tableView.deleteRows(at: [indexPath], with: .automatic)
            self.showBanner(message: "Task deleted")
            done(true)
        }

        let edit = UIContextualAction(style: .normal, title: "Edit") { [weak self] _, _, done in
            guard let self = self else { return }

            let taskToEdit = self.filteredTasks[indexPath.row]
            if let indexInAll = self.taskManager.tasks.firstIndex(where: { $0.id == taskToEdit.id }) {
                self.presentEditor(task: taskToEdit, index: indexInAll)
            } else {
                self.presentEditor(task: taskToEdit, index: nil)
            }
            done(true)
        }
        edit.backgroundColor = .systemBlue

        return UISwipeActionsConfiguration(actions: [delete, edit])
    }

    // MARK: - Banner
    func showBanner(message: String) {
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

        let top = banner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -bannerHeight)
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
        UIView.animate(withDuration: 0.45, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.4, options: [], animations: {
            self.view.layoutIfNeeded()
        })

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            UIView.animate(withDuration: 0.25, animations: {
                banner.transform = CGAffineTransform(translationX: 0, y: -bannerHeight - 20)
                banner.alpha = 0
            }, completion: { _ in banner.removeFromSuperview() })
        }
    }
}

// MARK: - Delegate
extension TaskListViewController: NewTaskDelegate {
    func didCreateTask(_ task: RoomTask) {
        taskManager.addTask(task)
        segmentChanged(segmentControl)
        tableView.reloadData()
        showBanner(message: "New task added")
    }

    func didUpdateTask(_ task: RoomTask, at index: Int) {
        guard taskManager.tasks.indices.contains(index) else { return }
        taskManager.updateTask(task, at: index)
        if let filteredIndex = filteredTasks.firstIndex(where: { $0.id == task.id }) {
            filteredTasks[filteredIndex] = task
        }
        tableView.reloadData()
        showBanner(message: "Task updated")
    }
}

