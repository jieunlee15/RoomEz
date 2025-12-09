import UIKit
import FirebaseFirestore

class TaskDetailViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var dueTitleLabel: UILabel!
    @IBOutlet weak var dueValueLabel: UILabel!
    @IBOutlet weak var assigneeTitleLabel: UILabel!
    @IBOutlet weak var assigneeValueLabel: UILabel!
    @IBOutlet weak var priorityPill: UIButton!
    @IBOutlet weak var frequencyLabel: UILabel!
    @IBOutlet weak var markDoneButton: UIButton!

    // MARK: - Data
    var task: RoomTask?
    var roomCode: String?
    private let db = Firestore.firestore()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Task Details"
        styleUI()
        if let t = task {
            configure(with: t)
        }

        markDoneButton.addTarget(self, action: #selector(markDoneTapped), for: .touchUpInside)
    }

    // MARK: - Styling
    private func styleUI() {
        view.backgroundColor = .systemBackground

        // Description TextView
        descriptionTextView.isEditable = false
        descriptionTextView.isScrollEnabled = true
        descriptionTextView.textContainer.lineFragmentPadding = 8 // left/right padding inside the box
        descriptionTextView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        descriptionTextView.textAlignment = .left
        descriptionTextView.layer.borderColor = UIColor.lightGray.cgColor
        descriptionTextView.layer.borderWidth = 1.0
        descriptionTextView.layer.cornerRadius = 8
        descriptionTextView.clipsToBounds = true

        // Priority pill
        priorityPill.layer.cornerRadius = 10
        priorityPill.clipsToBounds = true
        priorityPill.isUserInteractionEnabled = false
        
        // Frequency label
        frequencyLabel.backgroundColor = UIColor(hex: "#DCE0E4")
        frequencyLabel.textColor = .darkText
        frequencyLabel.textAlignment = .center
        frequencyLabel.layer.cornerRadius = 10
        frequencyLabel.layer.masksToBounds = true
        frequencyLabel.layer.shadowColor = UIColor.black.cgColor
        frequencyLabel.layer.shadowOpacity = 0.1
        frequencyLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        frequencyLabel.layer.shadowRadius = 2
    }

    // MARK: - Configure
    func configure(with task: RoomTask) {
        self.task = task

        titleLabel.text = task.title
        descriptionTextView.text = (task.details?.isEmpty ?? true) ? "No description provided." : task.details
        assigneeValueLabel.text = task.assignee ?? "Unassigned"

        if let due = task.dueDate {
            let df = DateFormatter()
            df.dateStyle = .short
            dueValueLabel.text = "\(df.string(from: due))"
        } else {
            dueValueLabel.text = "No due date"
        }

        // Priority / overdue
        let now = Date()
        let isOverdue = (task.dueDate ?? Date()) < now && task.status != .done
        if isOverdue {
            priorityPill.setTitle("Overdue", for: .normal)
            priorityPill.backgroundColor = UIColor.systemRed.withAlphaComponent(0.12)
            priorityPill.setTitleColor(.systemRed, for: .normal)
        } else {
            switch task.priority {
            case .low:
                priorityPill.setTitle("Low", for: .normal)
                priorityPill.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.12)
                priorityPill.setTitleColor(.systemGreen, for: .normal)
            case .medium:
                priorityPill.setTitle("Medium", for: .normal)
                priorityPill.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.12)
                priorityPill.setTitleColor(.systemOrange, for: .normal)
            case .high:
                priorityPill.setTitle("High", for: .normal)
                priorityPill.backgroundColor = UIColor.systemRed.withAlphaComponent(0.12)
                priorityPill.setTitleColor(.systemRed, for: .normal)
            }
        }

        switch task.frequency {
        case .none: frequencyLabel.text = "Does not repeat"
        case .daily: frequencyLabel.text = "Repeats every day"
        case .weekly: frequencyLabel.text = "Repeats every week"
        case .monthly: frequencyLabel.text = "Repeats every month"
        }

        updateMarkDoneButtonUI()
    }

    // MARK: - Actions
    @objc func markDoneTapped(_ sender: UIButton) {
        guard let t = task else { return }

        // Determine the new status text
        let newStatusText = (t.status == .done) ? "not done" : "done"

        // Show confirmation alert
        let alert = UIAlertController(
            title: "Confirm",
            message: "Mark this task as \(newStatusText)?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Confirm", style: .default) { _ in
            // Toggle status
            var updatedTask = t
            updatedTask.status = (t.status == .done) ? .todo : .done
            updatedTask.updatedAt = Date()
            self.task = updatedTask

            // Update UI
            self.configure(with: updatedTask)

            // Persist to Firestore
            guard let code = self.roomCode else { return }
            self.db.collection("rooms")
                .document(code)
                .collection("tasks")
                .document(updatedTask.id.uuidString)
                .setData(updatedTask.toDictionary(), merge: true)
        })
        
        present(alert, animated: true)
    }
    
    private func updateMarkDoneButtonUI() {
        guard let t = task else { return }
        if t.status == .done {
            markDoneButton.setTitle("Done", for: .normal)
        } else {
            markDoneButton.setTitle("Mark As Done", for: .normal)
        }
    }
}

