import UIKit
import FirebaseFirestore

class TaskDetailViewController: UIViewController {
    
    // MARK: - Outlets (all optional so they don't crash if not connected)
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var descriptionLabel: UILabel?
    
    @IBOutlet weak var dueTitleLabel: UILabel?
    @IBOutlet weak var dueValueLabel: UILabel?
    
    @IBOutlet weak var assigneeTitleLabel: UILabel?
    @IBOutlet weak var assigneeValueLabel: UILabel?
    
    @IBOutlet weak var priorityPill: UIButton?
    @IBOutlet weak var frequencyLabel: UILabel?
    
    @IBOutlet weak var markDoneButton: UIButton?
    
    // MARK: - Data
    var task: RoomTask?
    var roomCode: String?
    
    private let db = Firestore.firestore()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Task Details"
        [
            titleLabel,
            descriptionLabel,
            dueTitleLabel,
            dueValueLabel,
            assigneeTitleLabel,
            assigneeValueLabel,
            priorityPill,
            frequencyLabel,
            markDoneButton
        ].forEach { view in
            view?.translatesAutoresizingMaskIntoConstraints = true
        }
        
        styleUI()
        
        if let t = task {
            configure(with: t)
        }
    }
    
    // MARK: - Manual layout (NO constraints)
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    
        guard let titleLabel = titleLabel,
              let descriptionLabel = descriptionLabel,
              let dueTitleLabel = dueTitleLabel,
              let dueValueLabel = dueValueLabel,
              let assigneeTitleLabel = assigneeTitleLabel,
              let assigneeValueLabel = assigneeValueLabel,
              let priorityPill = priorityPill,
              let frequencyLabel = frequencyLabel,
              let markDoneButton = markDoneButton
        else {
            return
        }
        
        let safe = view.bounds.inset(by: view.safeAreaInsets)
        let padding: CGFloat = 24
        let spacing: CGFloat = 10
        
        let contentX = safe.minX + padding
        let contentWidth = safe.width - 2 * padding
        
        var y = safe.minY + padding
        
        // Title
        titleLabel.frame = CGRect(x: contentX,
                                  y: y,
                                  width: contentWidth,
                                  height: 26)
        y = titleLabel.frame.maxY + spacing
        
        // Description
        descriptionLabel.frame = CGRect(x: contentX,
                                        y: y,
                                        width: contentWidth,
                                        height: 60)
        descriptionLabel.sizeToFit()
        descriptionLabel.frame.size.width = contentWidth
        y = descriptionLabel.frame.maxY + spacing * 2
        
        // Due title + value
        dueTitleLabel.frame = CGRect(x: contentX,
                                     y: y,
                                     width: contentWidth,
                                     height: 20)
        y = dueTitleLabel.frame.maxY + 4
        
        dueValueLabel.frame = CGRect(x: contentX,
                                     y: y,
                                     width: contentWidth,
                                     height: 18)
        y = dueValueLabel.frame.maxY + spacing * 2
        
        // Assignee
        assigneeTitleLabel.frame = CGRect(x: contentX,
                                          y: y,
                                          width: contentWidth,
                                          height: 20)
        y = assigneeTitleLabel.frame.maxY + 4
        
        assigneeValueLabel.frame = CGRect(x: contentX,
                                          y: y,
                                          width: contentWidth,
                                          height: 18)
        y = assigneeValueLabel.frame.maxY + spacing * 2
        
        // Priority pill + frequency on same row
        priorityPill.sizeToFit()
        let pillHeight: CGFloat = 28
        let pillWidth = min(priorityPill.bounds.width + 16, contentWidth * 0.4)
        
        priorityPill.frame = CGRect(x: contentX,
                                    y: y,
                                    width: pillWidth,
                                    height: pillHeight)
        
        frequencyLabel.frame = CGRect(x: priorityPill.frame.maxX + 12,
                                      y: y,
                                      width: contentWidth - pillWidth - 12,
                                      height: pillHeight)
        y = priorityPill.frame.maxY + spacing * 3
        
        // Mark button pinned near bottom
        let buttonHeight: CGFloat = 48
        markDoneButton.frame = CGRect(x: contentX,
                                      y: safe.maxY - padding - buttonHeight,
                                      width: contentWidth,
                                      height: buttonHeight)
    }
    
    // MARK: - Styling
    private func styleUI() {
        view.backgroundColor = .systemBackground
        
        titleLabel?.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel?.numberOfLines = 2
        
        descriptionLabel?.font = .systemFont(ofSize: 14, weight: .regular)
        descriptionLabel?.textColor = .secondaryLabel
        descriptionLabel?.numberOfLines = 0
        
        // Section headers: "Needs to be finished before", "Assignee"
        let sectionFont = UIFont.systemFont(ofSize: 14, weight: .semibold)
        dueTitleLabel?.font = sectionFont
        assigneeTitleLabel?.font = sectionFont
        
        // Values: due date + assignee
        let valueFont = UIFont.systemFont(ofSize: 14, weight: .regular)
        dueValueLabel?.font = valueFont
        assigneeValueLabel?.font = valueFont
        
        // Frequency – small caption-style
        frequencyLabel?.font = .systemFont(ofSize: 13, weight: .regular)
        frequencyLabel?.textColor = .secondaryLabel
        
        // Priority pill
        if let pill = priorityPill {
            pill.layer.cornerRadius = 10
            pill.clipsToBounds = true
            pill.contentEdgeInsets = UIEdgeInsets(top: 4, left: 12, bottom: 4, right: 12)
            pill.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
            pill.isUserInteractionEnabled = false
        }
        
        // Mark As Done button – medium weight, slightly smaller
        if let btn = markDoneButton {
            btn.layer.cornerRadius = 12
            btn.layer.borderWidth = 1
            btn.layer.borderColor = UIColor.systemBlue.cgColor
            btn.setTitleColor(.systemBlue, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
            btn.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.06)
        }
    }

    // MARK: - Content
    func configure(with task: RoomTask) {
        self.task = task
        
        // Title
        titleLabel?.text = task.title
        
        // Description
        if let desc = task.details,
           !desc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            descriptionLabel?.text = desc
        } else {
            descriptionLabel?.text = "No description provided."
        }
        
        // Due date – match TaskCell style: "Due: 12/8/25"
        if let due = task.dueDate {
            let df = DateFormatter()
            df.dateStyle = .short
            dueValueLabel?.text = "Due: \(df.string(from: due))"
        } else {
            dueValueLabel?.text = "No due date"
        }
        
        // Assignee
        assigneeValueLabel?.text = task.assignee ?? "Unassigned"
        
        // ----- Overdue vs Priority pill -----
        let now = Date()
        var isOverdue = false
        if let due = task.dueDate {
            // same logic as list: overdue if past due and not done
            isOverdue = (due < now) && task.status != .done
        }
        
        if let pill = priorityPill {
            if isOverdue {
                // Overdue pill (matches the list)
                pill.setTitle("Overdue", for: .normal)
                pill.backgroundColor = UIColor.systemRed.withAlphaComponent(0.12)
                pill.setTitleColor(.systemRed, for: .normal)
            } else {
                // Normal priority pill
                switch task.priority {
                case .low:
                    pill.setTitle("Low", for: .normal)
                    pill.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.12)
                    pill.setTitleColor(.systemGreen, for: .normal)
                case .medium:
                    pill.setTitle("Medium", for: .normal)
                    pill.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.12)
                    pill.setTitleColor(.systemOrange, for: .normal)
                case .high:
                    pill.setTitle("High", for: .normal)
                    pill.backgroundColor = UIColor.systemRed.withAlphaComponent(0.12)
                    pill.setTitleColor(.systemRed, for: .normal)
                }
            }
        }
        
        // Frequency
        switch task.frequency {
        case .none:
            frequencyLabel?.text = "Does not repeat"
        case .daily:
            frequencyLabel?.text = "Repeats every day"
        case .weekly:
            frequencyLabel?.text = "Repeats every week"
        case .monthly:
            frequencyLabel?.text = "Repeats every month"
        }
    }

    
    // MARK: - Actions
    @IBAction func markDoneTapped(_ sender: UIButton) {
        guard var t = task else { return }
        
        switch t.status {
        case .todo:
            t.status = .inProgress
        case .inProgress:
            t.status = .done
        case .done:
            t.status = .todo
        }
        
        task = t
        configure(with: t)
        
        // Optional: update Firestore
        guard let code = roomCode else { return }
        db.collection("rooms")
            .document(code)
            .collection("tasks")
            .document(t.id.uuidString)
            .setData(t.toDictionary(), merge: true)
    }
}
