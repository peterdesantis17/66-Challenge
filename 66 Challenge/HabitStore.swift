import Foundation
import Supabase
import SwiftUI

@MainActor
class HabitStore: ObservableObject {
    @Published private(set) var habits: [Habit] = []
    private let supabase = SupabaseService.shared
    
    // Cache key
    private let cacheKey = "cached_habits"
    
    init() {
        loadFromCache()
        Task {
            await checkForDayChange()
        }
    }
    
    private func loadFromCache() {
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let cached = try? JSONDecoder().decode([Habit].self, from: data) {
            self.habits = cached
        }
    }
    
    private func saveToCache() {
        if let encoded = try? JSONEncoder().encode(habits) {
            UserDefaults.standard.set(encoded, forKey: cacheKey)
        }
    }
    
    private struct LastLoginUpdate: Encodable {
        let userId: UUID
        let lastSeen: Date
        
        enum CodingKeys: String, CodingKey {
            case userId = "user_id"
            case lastSeen = "last_seen"
        }
    }
    
    func checkForDayChange() async {
        let today = Calendar.current.startOfDay(for: Date())
        print("DEBUG: Checking for day change. Current time: \(today)")
        
        do {
            // Get user's last login from Supabase
            let userId = try await supabase.auth.session.user.id
            let response: [LastLogin] = try await supabase
                .from("last_logins")
                .select()
                .eq("user_id", value: userId)
                .limit(1)
                .execute()
                .value
            
            let lastLogin = response.first?.lastSeen ?? today
            print("DEBUG: Last login time: \(lastLogin)")
            
            // If it's a new day
            if Calendar.current.compare(today, to: lastLogin, toGranularity: .day) != .orderedSame {
                print("DEBUG: 📅 New day detected! Saving stats and resetting habits...")
                await saveDailyStats(forDate: lastLogin)
                await resetHabits()
            } else {
                print("DEBUG: 📅 Same day - no reset needed")
            }
            
            // Update last login in Supabase
            let update = LastLoginUpdate(userId: userId, lastSeen: today)
            try await supabase
                .from("last_logins")
                .upsert(update)
                .execute()
            
        } catch {
            print("DEBUG: ❌ Failed to check day change: \(error)")
        }
    }
    
    private struct DailyStat: Encodable {
        let userId: UUID
        let date: Date
        let completionPercentage: Double
        let habitsCompleted: Int
        let totalHabits: Int
        
        enum CodingKeys: String, CodingKey {
            case userId = "user_id"
            case date
            case completionPercentage = "completion_percentage"
            case habitsCompleted = "habits_completed"
            case totalHabits = "total_habits"
        }
    }
    
    private func saveDailyStats(forDate date: Date) async {
        let completed = habits.filter { $0.isCompleted }.count
        let total = habits.count
        let percentage = total > 0 ? (Double(completed) / Double(total)) * 100 : 0
        
        guard let userId = try? await supabase.auth.session.user.id else { return }
        
        let stats = DailyStat(
            userId: userId,
            date: date,
            completionPercentage: percentage,
            habitsCompleted: completed,
            totalHabits: total
        )
        
        do {
            try await supabase
                .from("daily_stats")
                .insert(stats)
                .execute()
        } catch {
            print("Failed to save daily stats: \(error)")
        }
    }
    
    private func resetHabits() async {
        // Reset local habits
        for (index, habit) in habits.enumerated() where habit.isCompleted {
            habits[index].isCompleted = false
        }
        saveToCache()
        
        // Reset habits in Supabase
        do {
            guard let userId = try? await supabase.auth.session.user.id else { return }
            try await supabase
                .from("habits")
                .update(["is_completed": false])
                .eq("user_id", value: userId)
                .execute()
        } catch {
            print("Failed to reset habits in Supabase: \(error)")
        }
    }
    
    func fetchHabits() async throws {
        let response: [Habit] = try await supabase
            .from("habits")
            .select()
            .execute()
            .value
        
        habits = response
        saveToCache()
    }
    
    func addHabit(title: String) async throws {
        let session = try await supabase.auth.session
        let userId = session.user.id
        
        let newHabit = Habit(
            id: UUID(),
            userId: userId,
            title: title,
            isCompleted: false,
            createdAt: Date()
        )
        
        try await supabase
            .from("habits")
            .insert(newHabit)
            .execute()
        
        habits.append(newHabit)
        saveToCache()
    }
    
    func toggleHabit(_ habit: Habit) async throws {
        let updated = Habit(
            id: habit.id,
            userId: habit.userId,
            title: habit.title,
            isCompleted: !habit.isCompleted,
            createdAt: habit.createdAt
        )
        
        try await supabase
            .from("habits")
            .update(updated)
            .eq("id", value: habit.id)
            .execute()
        
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[index] = updated
            saveToCache()
        }
    }
}

// Model for last login
private struct LastLogin: Decodable {
    let userId: UUID
    let lastSeen: Date
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case lastSeen = "last_seen"
    }
} 