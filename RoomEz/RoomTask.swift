//
//  RoomTask.swift
//  RoomEz
//
//  Created by Kirti Ganesh on 10/22/25.
//

import Foundation


class RoomTask {
    let id: UUID
    let title: String
    let details: String?
    let dueDate: Date?
    let assignee: String?
    var isCompleted: Bool
    let createdAt: Date
        
    // Update your initializer
    init(id: UUID = UUID(), title: String, details: String?, dueDate: Date?, assignee: String?, isCompleted: Bool, createdAt: Date) {
        self.id = id
        self.title = title
        self.details = details
        self.dueDate = dueDate
        self.assignee = assignee
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }
}
