//
//  TaskManager.swift
//  RoomEz
//
//  Created by Jieun Lee on 11/9/25.
//
import Foundation

class TaskManager: ObservableObject {
    static let shared = TaskManager()
    
    @Published var tasks: [RoomTask] = []
    
    private init() {
        loadExampleTasks()
    }
    
    // MARK: - Example data
    private func loadExampleTasks() {
        tasks = [
            RoomTask(
                id: UUID(),
                title: "Payment",
                details: nil,
                dueDate: Date(),
                assignee: "Lucy",
                status: .todo,
                createdAt: Date()
            ),
            RoomTask(
                id: UUID(),
                title: "Cooking",
                details: nil,
                dueDate: Date().addingTimeInterval(86400),
                assignee: "Jieun",
                status: .inProgress,
                createdAt: Date()
            ),
            RoomTask(
                id: UUID(),
                title: "Cleaning",
                details: nil,
                dueDate: Date().addingTimeInterval(172800),
                assignee: "Ananya",
                status: .done,
                createdAt: Date()
            )
        ]
    }
    
    func addTask(_ task: RoomTask) {
        tasks.append(task)
        // This will automatically notify all observers
    }
    
    func updateTask(_ task: RoomTask, at index: Int) {
        guard index >= 0 && index < tasks.count else { return }
        tasks[index] = task
    }
    
    func updateStatus(for taskId: UUID, to newStatus: TaskStatus) {
        if let index = tasks.firstIndex(where: { $0.id == taskId }) {
            tasks[index].status = newStatus
        }
    }
    
    func deleteTask(_ taskId: UUID) {
        tasks.removeAll { $0.id == taskId }
    }
}
