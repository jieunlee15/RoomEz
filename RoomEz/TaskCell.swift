import UIKit

class TaskCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var assigneeLabel: UILabel?
    @IBOutlet weak var dueDateLabel: UILabel?
    @IBOutlet weak var statusButton: UIButton?
    @IBOutlet weak var priorityLabel: UIButton?   // pill-style button
    
    // VC will set this; we call it when the button is tapped
    var onStatusTapped: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Make sure Auto Layout isn't trying to control these
        [titleLabel, assigneeLabel, dueDateLabel, statusButton, priorityLabel].forEach {
            $0?.translatesAutoresizingMaskIntoConstraints = true
        }
        
        // Status button styling
        if let statusButton = statusButton {
            statusButton.layer.cornerRadius = 10
            statusButton.clipsToBounds = true
        }
        
        // Priority “pill” styling
        if let priorityLabel = priorityLabel {
            priorityLabel.layer.cornerRadius = 8
            priorityLabel.clipsToBounds = true
            priorityLabel.contentEdgeInsets = UIEdgeInsets(top: 3, left: 8, bottom: 3, right: 8)
            priorityLabel.isUserInteractionEnabled = false   // purely display
            
            let pillFont = UIFont.systemFont(ofSize: 12, weight: .semibold)
            priorityLabel.titleLabel?.font = pillFont
            priorityLabel.titleLabel?.adjustsFontSizeToFitWidth = true
            priorityLabel.titleLabel?.minimumScaleFactor = 0.8
            priorityLabel.titleLabel?.numberOfLines = 1
        }
        
        // Labels styling
        titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        
        assigneeLabel?.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        assigneeLabel?.textColor = .secondaryLabel
        
        dueDateLabel?.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        dueDateLabel?.textColor = .secondaryLabel
    }
    
    // Manual layout – NO CONSTRAINTS
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard let titleLabel = titleLabel,
              let assigneeLabel = assigneeLabel,
              let dueDateLabel = dueDateLabel,
              let statusButton = statusButton,
              let priorityLabel = priorityLabel else {
            // If any outlet isn’t wired, just skip layout to avoid crash
            return
        }
        
        let padding: CGFloat = 12
        let content = contentView.bounds.insetBy(dx: padding, dy: padding)
        
        let rightColumnWidth: CGFloat = 120
        let spacingY: CGFloat = 4
        
        // Left column width (title/assignee/due date)
        let leftWidth = content.width - rightColumnWidth - padding
        
        // Title
        titleLabel.frame = CGRect(
            x: content.minX,
            y: content.minY,
            width: leftWidth,
            height: 22
        )
        
        // Assignee
        assigneeLabel.frame = CGRect(
            x: content.minX,
            y: titleLabel.frame.maxY + spacingY,
            width: leftWidth,
            height: 18
        )
        
        // Due date
        dueDateLabel.frame = CGRect(
            x: content.minX,
            y: assigneeLabel.frame.maxY + spacingY,
            width: leftWidth,
            height: 18
        )
        
        // Right column X origin
        let rightX = content.maxX - rightColumnWidth
        
        // Priority pill
        priorityLabel.sizeToFit()
        let priorityHeight: CGFloat = 24
        priorityLabel.frame = CGRect(
            x: rightX,
            y: content.minY,
            width: rightColumnWidth,
            height: priorityHeight
        )
        
        // Status button
        let statusHeight: CGFloat = 28
        statusButton.frame = CGRect(
            x: rightX,
            y: content.maxY - statusHeight,
            width: rightColumnWidth,
            height: statusHeight
        )
    }
    
    func configure(with task: RoomTask) {
        titleLabel?.text = task.title
        assigneeLabel?.text = task.assignee ?? "Unassigned"
        
        if let due = task.dueDate {
            let df = DateFormatter()
            df.dateStyle = .short
            dueDateLabel?.text = "Due: \(df.string(from: due))"
        } else {
            dueDateLabel?.text = "No due date"
        }
        
        // Helper to style status button
        func setStatusButton(
            title: String,
            titleColor: UIColor,
            backgroundColor: UIColor,
            imageName: String,
            borderWidth: CGFloat = 0,
            borderColor: UIColor? = nil
        ) {
            guard let statusButton = statusButton else { return }
            
            let font = UIFont.systemFont(ofSize: 12, weight: .semibold)
            
            let attributedTitle = NSAttributedString(
                string: " " + title,
                attributes: [.font: font, .foregroundColor: titleColor]
            )
            statusButton.setAttributedTitle(attributedTitle, for: .normal)
            
            let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .regular)
            let icon = UIImage(systemName: imageName, withConfiguration: config)
            statusButton.setImage(icon, for: .normal)
            statusButton.tintColor = titleColor
            
            statusButton.backgroundColor = backgroundColor
            statusButton.layer.borderWidth = borderWidth
            statusButton.layer.borderColor = borderColor?.cgColor
            
            statusButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 0)
        }
        
        // Status colors
        let todoFill = UIColor(hex: "#E89D33")
        let inProgressFill = UIColor(hex: "#C7E3F6")
        let inProgressBorder = UIColor(hex: "#305B9D")
        let doneFill = UIColor(hex: "#71BF6C")
        let doneBorder = UIColor(hex: "#478B43")
        
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
            priorityLabel.setTitle(task.priority.rawValue, for: .normal)
            switch task.priority {
            case .low:
                priorityLabel.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.12)
                priorityLabel.setTitleColor(.systemGreen, for: .normal)
            case .medium:
                priorityLabel.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.12)
                priorityLabel.setTitleColor(.systemOrange, for: .normal)
            case .high:
                priorityLabel.backgroundColor = UIColor.systemRed.withAlphaComponent(0.12)
                priorityLabel.setTitleColor(.systemRed, for: .normal)
            }
        }
    }
    
    @IBAction func statusTapped(_ sender: UIButton) {
        onStatusTapped?()
    }
}
