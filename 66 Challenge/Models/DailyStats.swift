import Foundation

struct DailyStats: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let date: Date
    let completionPercentage: Double
    let habitsCompleted: Int
    let totalHabits: Int
    let createdAt: Date
    
    // Add regular initializer
    init(id: UUID, userId: UUID, date: Date, completionPercentage: Double, 
         habitsCompleted: Int, totalHabits: Int, createdAt: Date) {
        self.id = id
        self.userId = userId
        self.date = date
        self.completionPercentage = completionPercentage
        self.habitsCompleted = habitsCompleted
        self.totalHabits = totalHabits
        self.createdAt = createdAt
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case date
        case completionPercentage = "completion_percentage"
        case habitsCompleted = "habits_completed"
        case totalHabits = "total_habits"
        case createdAt = "created_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        
        let dateString = try container.decode(String.self, forKey: .date)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        date = try dateFormatter.date(from: dateString) ?? { throw DecodingError.dataCorruptedError(forKey: .date, in: container, debugDescription: "Invalid date format") }()
        
        completionPercentage = try container.decode(Double.self, forKey: .completionPercentage)
        habitsCompleted = try container.decode(Int.self, forKey: .habitsCompleted)
        totalHabits = try container.decode(Int.self, forKey: .totalHabits)
        createdAt = try ISO8601DateFormatter().date(from: try container.decode(String.self, forKey: .createdAt)) ?? Date()
    }
} 