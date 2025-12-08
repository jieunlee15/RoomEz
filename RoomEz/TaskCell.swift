import UIKit

class TaskCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var assigneeLabel: UILabel!
    @IBOutlet weak var dueDateLabel: UILabel!
    @IBOutlet weak var statusButton: UIButton!
    @IBOutlet weak var priorityLabel: UIButton!

    // VC sets this; we call it when the status button is tapped
    var onStatusTapped: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        // If anything isn’t wired, don’t touch it (avoids crash)
        statusButton?.layer.cornerRadius = 11
        statusButton?.clipsToBounds = true
        statusButton?.titleLabel?.font = UIFont.systemFont(ofSize: 11, weight: .regular)
        statusButton?.contentEdgeInsets = UIEdgeInsets(top: 3, left: 10, bottom: 3, right: 10)

        priorityLabel?.layer.cornerRadius = 9
        priorityLabel?.clipsToBounds = true
        priorityLabel?.titleLabel?.font = UIFont.systemFont(ofSize: 10, weight: .semibold)
        priorityLabel?.contentEdgeInsets = UIEdgeInsets(top: 2, left: 8, bottom: 2, right: 8)
        priorityLabel?.isUserInteractionEnabled = false
    }

    func configure(with task: RoomTask) {
        // Use ? everywhere so a missing outlet can’t crash
        titleLabel?.text = task.title
        assigneeLabel?.text = task.assignee ?? "Unassigned"

        if let due = task.dueDate {
            let df = DateFormatter()
            df.dateStyle = .short
            dueDateLabel?.text = "Due: \(df.string(from: due))"
        } else {
            dueDateLabel?.text = "No due date"
        }

        // Layout for status chip
        if let statusButton = statusButton {
            statusButton.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                statusButton.heightAnchor.constraint(equalToConstant: 22),
                statusButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                statusButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
            ])
        }

        func setStatusButton(
            title: String,
            titleColor: UIColor,
            backgroundColor: UIColor,
            imageName: String,
            borderWidth: CGFloat = 0,
            borderColor: UIColor? = nil
        ) {
            guard let statusButton = statusButton else { return }

            let font = UIFont.systemFont(ofSize: 11, weight: .regular)
            let attributedTitle = NSAttributedString(
                string: " " + title,
                attributes: [.font: font, .foregroundColor: titleColor]
            )
            statusButton.setAttributedTitle(attributedTitle, for: .normal)

            let config = UIImage.SymbolConfiguration(pointSize: 11, weight: .regular)
            let icon = UIImage(systemName: imageName, withConfiguration: config)
            statusButton.setImage(icon, for: .normal)
            statusButton.tintColor = titleColor

            statusButton.backgroundColor = backgroundColor
            statusButton.layer.borderWidth = borderWidth
            statusButton.layer.borderColor = borderColor?.cgColor
            statusButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 0)
        }

        // Status colors
        let todoFill         = UIColor(hex: "#E89D33")
        let inProgressFill   = UIColor(hex: "#C7E3F6")
        let inProgressBorder = UIColor(hex: "#305B9D")
        let doneFill         = UIColor(hex: "#71BF6C")
        let doneBorder       = UIColor(hex: "#478B43")

        switch task.status {
        case .todo:
            setStatusButton(
                title: "To Do",
                titleColor: .black,
                backgroundColor: todoFill,
                imageName: "circle"
            )
        case .inProgress:
            setStatusButton(
                title: "In Progress",
                titleColor: .black,
                backgroundColor: inProgressFill,
                imageName: "clock",
                borderWidth: 0.5,
                borderColor: inProgressBorder
            )
        case .done:
            setStatusButton(
                title: "Done",
                titleColor: .black,
                backgroundColor: doneFill,
                imageName: "checkmark.circle.fill",
                borderWidth: 0.5,
                borderColor: doneBorder
            )
        }

        // Priority pill
        if let priorityLabel = priorityLabel {
            let text = task.priority.rawValue   // "Low", "Medium", "High"
            priorityLabel.setTitle(text, for: .normal)

            switch task.priority {
            case .low:
                priorityLabel.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.12)
                priorityLabel.setTitleColor(.systemGreen, for: .normal)
            case .medium:
                priorityLabel.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.14)
                priorityLabel.setTitleColor(.systemOrange, for: .normal)
            case .high:
                priorityLabel.backgroundColor = UIColor.systemRed.withAlphaComponent(0.14)
                priorityLabel.setTitleColor(.systemRed, for: .normal)
            }
        }
    }

    @IBAction func statusTapped(_ sender: UIButton) {
        onStatusTapped?()
    }
}
