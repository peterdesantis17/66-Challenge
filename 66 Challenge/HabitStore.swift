import Foundation
import Supabase
import SwiftUI

@MainActor
class HabitStore: ObservableObject {
    @Published private(set) var habits: [Habit] = []
    @Published private(set) var dailyStats: [DailyStats] = []
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
            
            // If it's a different day
            if Calendar.current.compare(today, to: lastLogin, toGranularity: .day) != .orderedSame {
                print("DEBUG: 📅 Days missed detected! Saving stats for each day...")
                
                // Save stats for the last active day with actual completion
                await saveDailyStats(forDate: lastLogin, wasPresent: true)
                
                // Save 0% stats for all missed days in between
                var currentDate = Calendar.current.date(byAdding: .day, value: 1, to: lastLogin) ?? today
                while Calendar.current.startOfDay(for: currentDate) < today {
                    print("DEBUG: 📊 Saving stats for missed day \(currentDate)")
                    await saveDailyStats(forDate: currentDate, wasPresent: false)
                    currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? today
                }
                
                // Reset habits only once after saving all stats
                print("DEBUG: 🔄 Resetting habits for new day")
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
    
    private func saveDailyStats(forDate date: Date, wasPresent: Bool = true) async {
        let completed = wasPresent ? habits.filter { $0.isCompleted }.count : 0
        let total = habits.count
        let percentage = total > 0 ? (Double(completed) / Double(total)) * 100 : 0
        
        guard let userId = try? await supabase.auth.session.user.id else { return }
        
        let stats = DailyStats(
            id: UUID(),  // New stat gets new UUID
            userId: userId,
            date: date,
            completionPercentage: percentage,
            habitsCompleted: completed,
            totalHabits: total,
            createdAt: Date()  // Current timestamp
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
            .order("order")
            .execute()
            .value
        
        habits = response
        saveToCache()
    }
    
    func addHabit(title: String) async throws {
        let session = try await supabase.auth.session
        let userId = session.user.id
        
        // Fix the next order calculation
        let nextOrder = (habits.map { $0.order }.max() ?? 0) + 1  // Add parentheses
        
        let newHabit = Habit(
            id: UUID(),
            userId: userId,
            title: title,
            isCompleted: false,
            createdAt: Date(),
            order: nextOrder
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
            createdAt: habit.createdAt,
            order: habit.order
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
    
    func fetchDailyStats() async throws {
        guard let userId = try? await supabase.auth.session.user.id else { return }
        
        let response = try await supabase
            .from("daily_stats")
            .select()
            .eq("user_id", value: userId)
            .order("date", ascending: false)
            .limit(30)
            .execute()
        
        dailyStats = try JSONDecoder().decode([DailyStats].self, from: response.data)
    }
    
    func reorderHabits(from source: IndexSet, to destination: Int) async throws {
        // Update local order
        habits.move(fromOffsets: source, toOffset: destination)
        
        // Update order numbers for all habits
        for (index, var habit) in habits.enumerated() {
            if habit.order != index + 1 {
                // Only update if order changed
                habit = Habit(
                    id: habit.id,
                    userId: habit.userId,
                    title: habit.title,
                    isCompleted: habit.isCompleted,
                    createdAt: habit.createdAt,
                    order: index + 1
                )
                
                try await supabase
                    .from("habits")
                    .update(["order": index + 1])
                    .eq("id", value: habit.id)
                    .execute()
                
                habits[index] = habit
            }
        }
        
        saveToCache()
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