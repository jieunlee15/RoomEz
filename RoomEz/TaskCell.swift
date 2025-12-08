//  TaskCell.swift
//  RoomEz
//  Created by Kirti Ganesh on 10/22/25.

import UIKit

class TaskCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var assigneeLabel: UILabel!
    @IBOutlet weak var dueDateLabel: UILabel!
    @IBOutlet weak var statusButton: UIButton!
    @IBOutlet weak var priorityLabel: UIButton!
    
    // VC will set this; we call it when the button is tapped
    var onStatusTapped: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Status button styling
        statusButton.layer.cornerRadius = 10
        statusButton.clipsToBounds = true
        
        // Priority “pill” styling
        priorityLabel.layer.cornerRadius = 8
        priorityLabel.clipsToBounds = true
        priorityLabel.contentEdgeInsets = UIEdgeInsets(top: 3, left: 8, bottom: 3, right: 8)
        priorityLabel.isUserInteractionEnabled = false   // purely display
        
        // Make fonts match
        let pillFont = UIFont.systemFont(ofSize: 12, weight: .semibold)
        priorityLabel.titleLabel?.font = pillFont
        statusButton.titleLabel?.font = pillFont
        priorityLabel.titleLabel?.adjustsFontSizeToFitWidth = true
        priorityLabel.titleLabel?.minimumScaleFactor = 0.8
        priorityLabel.titleLabel?.numberOfLines = 1
    }
    
    func configure(with task: RoomTask) {
        titleLabel.text = task.title
        assigneeLabel.text = task.assignee ?? "Unassigned"
        
        if let due = task.dueDate {
            let df = DateFormatter()
            df.dateStyle = .short
            dueDateLabel.text = "Due: \(df.string(from: due))"
        } else {
            dueDateLabel.text = "No due date"
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
    
    @IBAction func statusTapped(_ sender: UIButton) {
        onStatusTapped?()
    }
}
