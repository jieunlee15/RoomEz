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

        // Fixed height constraint
        NSLayoutConstraint.activate([
            statusButton.heightAnchor.constraint(equalToConstant: 22),
            statusButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            statusButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])

        // Helper to set title + font reliably
        func setStatusButton(title: String, titleColor: UIColor, backgroundColor: UIColor, borderWidth: CGFloat = 0, borderColor: UIColor? = nil) {
            let font = UIFont.systemFont(ofSize: 12, weight: .regular)
            let attributedTitle = NSAttributedString(string: title, attributes: [.font: font, .foregroundColor: titleColor])
            statusButton.setAttributedTitle(attributedTitle, for: .normal)
            statusButton.backgroundColor = backgroundColor
            statusButton.layer.borderWidth = borderWidth
            if let borderColor = borderColor {
                statusButton.layer.borderColor = borderColor.cgColor
            } else {
                statusButton.layer.borderColor = nil
            }
        }

        switch task.status {
        case .todo:
            setStatusButton(title: "To Do", titleColor: .black, backgroundColor: .white, borderWidth: 1, borderColor: .black)
        case .inProgress:
            setStatusButton(title: "In Progress", titleColor: .white, backgroundColor: .black)
        case .done:
            setStatusButton(title: "Done", titleColor: .white, backgroundColor: .systemGray)
        }
    }

    @IBAction func statusTapped(_ sender: UIButton) {
        onStatusTapped?()
    }
}
