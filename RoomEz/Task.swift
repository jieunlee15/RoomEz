//
//  Task.swift
//  RoomEz
//
//  Created by Kirti Ganesh on 10/20/25.
//

import Foundation

// simple model for each chore/task
struct Task {
    var id: String = UUID().uuidString
    var title: String            // name of the task
    var assignedTo: String?      // who’s doing it (optional for now)
    var dueDate: Date            // when it’s due
    var completed: Bool = false  // true if it’s marked done
    var createdAt: Date = Date() // timestamp when made
}
