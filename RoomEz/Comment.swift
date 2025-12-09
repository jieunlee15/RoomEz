import Foundation

struct Comment {
    let id: String
    let text: String
    let author: String
    let timestamp: Date
    let replyToAuthor: String? // This is the new field for replies
}


