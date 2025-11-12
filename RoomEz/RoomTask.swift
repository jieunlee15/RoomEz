//  RoomTask.swift
//  RoomEz
//  Created by Kirti Ganesh on 10/22/25.

import Foundation

enum TaskStatus: String, Codable {
    case todo = "To Do"
    case inProgress = "In Progress"
    case done = "Done"
}

enum TaskPriority: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}

class RoomTask: Codable {
    let id: UUID
    var title: String
    var details: String?
    var dueDate: Date?
    var assignee: String?
    var status: TaskStatus
    var priority: TaskPriority
    var createdAt: Date
    var updatedAt: Date?
    var completionPercent: Double  // 0.0 – 1.0
    var reminderSet: Bool
    
    init(
        id: UUID = UUID(),
        title: String,
        details: String? = nil,
        dueDate: Date? = nil,
        assignee: String? = nil,
        status: TaskStatus? = nil,
        priority: TaskPriority = .medium,
        createdAt: Date = Date(),
        updatedAt: Date? = nil,
        completionPercent: Double = 0.0,
        reminderSet: Bool = false
    ) {
        self.id = id
        self.title = title
        self.details = details
        self.dueDate = dueDate
        self.assignee = assignee
        self.status = status ?? .todo
        self.priority = priority
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.completionPercent = completionPercent
        self.reminderSet = reminderSet
    }
}

