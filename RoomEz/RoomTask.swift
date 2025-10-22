//
//  RoomTask.swift
//  RoomEz
//
//  Created by Kirti Ganesh on 10/22/25.
//

import Foundation

// represents one task/chore in the app
struct RoomTask {
    var id: String = UUID().uuidString
    var title: String
    var details: String?
    var dueDate: Date?
    var assignee: String?        // roommate name
    var isCompleted: Bool = false
    var createdAt: Date = Date()
}
