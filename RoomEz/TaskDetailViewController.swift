import UIKit
import FirebaseFirestore
class TaskDetailViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UITextView!
    @IBOutlet weak var dueDateLabel: UILabel!
    @IBOutlet weak var assigneeLabel: UILabel!
    @IBOutlet weak var markAsFinishedButton: UIButton!
    
    var task: RoomTask!
    var taskIndex: Int?
    var currentRoomCode: String? // Pass this from TaskListVC
    private let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Task"
        configureView()
    }
    
    func configureView() {
        titleLabel.text = task.title
        descriptionLabel.text = task.details ?? "No description provided."
        
        if let due = task.dueDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            dueDateLabel.text = "\(formatter.string(from: due))"
        } else {
            dueDateLabel.text = "No due date"
        }
        
        assigneeLabel.text = task.assignee ?? "Unassigned"
        
        // Style button
        markAsFinishedButton.layer.cornerRadius = 10
        markAsFinishedButton.layer.borderWidth = 1
        markAsFinishedButton.layer.borderColor = UIColor.black.cgColor
        
        // Button text and availability depend on task.status
        switch task.status {
        case .done:
            markAsFinishedButton.setTitle("Finished", for: .normal)
            markAsFinishedButton.isEnabled = false
            markAsFinishedButton.backgroundColor = .systemGray5
            markAsFinishedButton.setTitleColor(.black, for: .normal)
        case .inProgress, .todo:
            markAsFinishedButton.setTitle("Mark as Finished", for: .normal)
            markAsFinishedButton.isEnabled = true
            markAsFinishedButton.backgroundColor = .white
            markAsFinishedButton.setTitleColor(.black, for: .normal)
        }
    }
    
    @IBAction func markAsFinishedTapped(_ sender: UIButton) {
        guard task.status != .done, let roomCode = currentRoomCode else { return }
        
        let alert = UIAlertController(title: nil, message: "Confirm to mark as finished?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Confirm", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.task.status = .done
            self.task.updatedAt = Date()
            
            // Update Firestore
            self.db.collection("rooms").document(roomCode)
                .collection("tasks").document(self.task.id.uuidString)
                .setData(self.task.toDictionary()) { error in
                    if let error = error {
                        print("Error updating task: \(error)")
                    } else {
                        // Optionally update TaskManager locally
                        if let index = self.taskIndex {
                            TaskManager.shared.updateTask(self.task, at: index)
                        }
                        self.configureView()
                    }
                }
        })
        present(alert, animated: true)
    }
}
