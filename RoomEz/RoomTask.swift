//
//  RoomTask.swift
//  RoomEz
//
//  Created by Kirti Ganesh on 10/22/25.
//

import Foundation

enum TaskStatus: String, Codable {
    case todo = "To Do"
    case inProgress = "In Progress"
    case done = "Done"
}

class RoomTask {
    let id: UUID
    let title: String
    let details: String?
    let dueDate: Date?
    let assignee: String?
    var status: TaskStatus = .todo
    let createdAt: Date
        
    // Update your initializer
    init(id: UUID = UUID(), title: String, details: String?, dueDate: Date?, assignee: String?, status: TaskStatus?, createdAt: Date) {
        self.id = id
        self.title = title
        self.details = details
        self.dueDate = dueDate
        self.assignee = assignee
        self.status = status ?? .todo
        self.createdAt = createdAt
    }
}
