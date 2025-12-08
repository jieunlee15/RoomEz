//  TaskCell.swift
//  RoomEz
//  Created by Kirti Ganesh on 10/22/25.

import UIKit

// simple custom cell for showing one task in the list
// TaskCell.swift

class TaskCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var assigneeLabel: UILabel!
    @IBOutlet weak var dueDateLabel: UILabel!
    @IBOutlet weak var statusButton: UIButton!

    // VC will set this; we call it when the button is tapped
    var onStatusTapped: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func configure(with task: RoomTask) {
        titleLabel.text = task.title
        assigneeLabel.text = task.assignee ?? "Unassigned"
        
        if let due = task.dueDate {
            let df = DateFormatter(); df.dateStyle = .short
            dueDateLabel.text = "Due: \(df.string(from: due))"
        } else {
            dueDateLabel.text = "No due date"
        }
        
        statusButton.layer.cornerRadius = 10
        statusButton.clipsToBounds = true
        statusButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            statusButton.heightAnchor.constraint(equalToConstant: 22),
            statusButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            statusButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
        
        func setStatusButton(
            title: String,
            titleColor: UIColor,
            backgroundColor: UIColor,
            imageName: String,
            borderWidth: CGFloat = 0,
            borderColor: UIColor? = nil
        ) {
            let font = UIFont.systemFont(ofSize: 12, weight: .regular)
            
            // TEXT
            let attributedTitle = NSAttributedString(
                string: " " + title,   // space before text for spacing
                attributes: [.font: font, .foregroundColor: titleColor]
            )
            statusButton.setAttributedTitle(attributedTitle, for: .normal)
            
            // ICON
            let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .regular)
            let icon = UIImage(systemName: imageName, withConfiguration: config)
            statusButton.setImage(icon, for: .normal)
            
            statusButton.tintColor = titleColor   // make icon same color as text
            
            // COLORS + BORDER
            statusButton.backgroundColor = backgroundColor
            statusButton.layer.borderWidth = borderWidth
            statusButton.layer.borderColor = borderColor?.cgColor
            
            // Ensure spacing between icon + text
            statusButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 0)
        }
        
        
        // 🎨 Your requested colors
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
                imageName: "circle"   // ⭕ empty circle
            )
            
        case .inProgress:
            setStatusButton(
                title: "In Progress",
                titleColor: .black,
                backgroundColor: inProgressFill,
                imageName: "clock",   // 🕒 or choose another
                borderWidth: 0.5,
                borderColor: inProgressBorder
            )
            
        case .done:
            setStatusButton(
                title: "Done",
                titleColor: .black,
                backgroundColor: doneFill,
                imageName: "checkmark.circle.fill",  // ✔️ filled circle w/ check
                borderWidth: 0.5,
                borderColor: doneBorder
            )
        }
    }

    @IBAction func statusTapped(_ sender: UIButton) {
        onStatusTapped?()
    }
}
