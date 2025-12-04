import Foundation
import FirebaseFirestore
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
    var completionPercent: Double
    var reminderSet: Bool
    
    // MARK: - Initializer
    init(
        id: UUID = UUID(),
        title: String,
        details: String? = nil,
        dueDate: Date? = nil,
        assignee: String? = nil,
        status: TaskStatus = .todo,
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
        self.status = status
        self.priority = priority
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.completionPercent = completionPercent
        self.reminderSet = reminderSet
    }
    
    
    // MARK: - Encode (Swift → Firestore)
    func toDictionary() -> [String: Any] {
        return [
            "id": id.uuidString,
            "title": title,
            "details": details ?? "",
            "dueDate": dueDate as Any,
            "assignee": assignee as Any,
            "status": status.rawValue,
            "priority": priority.rawValue,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": updatedAt != nil ? Timestamp(date: updatedAt!) : NSNull(),
            "completionPercent": completionPercent,
            "reminderSet": reminderSet
        ]
    }
    
    
    // MARK: - Decode (Firestore → Swift)
    static func fromDocument(_ data: [String: Any]) -> RoomTask? {
        
        // Required fields
        guard let idString = data["id"] as? String,
              let uuid = UUID(uuidString: idString),
              let title = data["title"] as? String,
              let statusRaw = data["status"] as? String,
              let status = TaskStatus(rawValue: statusRaw),
              let priorityRaw = data["priority"] as? String,
              let priority = TaskPriority(rawValue: priorityRaw),
              let createdAtTS = data["createdAt"] as? Timestamp
        else {
            print("❌ RoomTask decoding failed — missing required fields")
            return nil
        }
        
        // Optional fields
        let details = data["details"] as? String
        let dueDate = (data["dueDate"] as? Timestamp)?.dateValue()
        let assignee = data["assignee"] as? String
        let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue()
        let completionPercent = data["completionPercent"] as? Double ?? 0.0
        let reminderSet = data["reminderSet"] as? Bool ?? false
        
        return RoomTask(
            id: uuid,
            title: title,
            details: details,
            dueDate: dueDate,
            assignee: assignee,
            status: status,
            priority: priority,
            createdAt: createdAtTS.dateValue(),
            updatedAt: updatedAt,
            completionPercent: completionPercent,
            reminderSet: reminderSet
        )
    }
}
