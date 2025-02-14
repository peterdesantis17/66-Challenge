import Foundation

struct Habit: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let title: String
    var isCompleted: Bool
    let createdAt: Date
    let order: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case isCompleted = "is_completed"
        case createdAt = "created_at"
        case order
    }
} 