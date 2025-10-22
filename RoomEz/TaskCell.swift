//
//  TaskCell.swift
//  RoomEz
//
//  Created by Kirti Ganesh on 10/22/25.
//

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
        statusButton.layer.cornerRadius = 10
        statusButton.clipsToBounds = true
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
        if task.isCompleted {
            statusButton.setTitle("Done", for: .normal)
            statusButton.backgroundColor = .systemGreen
        } else {
            statusButton.setTitle("Mark", for: .normal)
            statusButton.backgroundColor = .systemGray4
        }
    }

    @IBAction func statusTapped(_ sender: UIButton) {
        onStatusTapped?()
    }
}
