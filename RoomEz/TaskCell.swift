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
            statusButton.layer.cornerRadius = 10
            statusButton.clipsToBounds = true
            statusButton.backgroundColor = .systemGray
        } else {
            statusButton.setTitle("To Do", for: .normal)
            statusButton.layer.cornerRadius = 10
            statusButton.backgroundColor = .black
            statusButton.setTitleColor(.white, for: .normal)
            statusButton.clipsToBounds = true
        }
    }

    @IBAction func statusTapped(_ sender: UIButton) {
        onStatusTapped?()
    }
}
