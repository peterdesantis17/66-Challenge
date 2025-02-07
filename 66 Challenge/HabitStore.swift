import Foundation
import Supabase

@MainActor
class HabitStore: ObservableObject {
    @Published private(set) var habits: [Habit] = []
    private let supabase = SupabaseService.shared
    
    // Cache key
    private let cacheKey = "cached_habits"
    private let lastLoginKey = "last_login_date"
    
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
    
    private func checkForDayChange() async {
        let today = Calendar.current.startOfDay(for: Date())
        
        // Get last login date from UserDefaults
        let lastLogin = UserDefaults.standard.object(forKey: lastLoginKey) as? Date ?? today
        
        // If it's a new day
        if Calendar.current.compare(today, to: lastLogin, toGranularity: .day) != .orderedSame {
            // Save yesterday's stats
            Task {
                await saveDailyStats(forDate: lastLogin)
            }
            // Reset habits
            Task {
                await resetHabits()
            }
        }
        
        // Update last login
        UserDefaults.standard.set(today, forKey: lastLoginKey)
    }
    
    private func saveDailyStats(forDate date: Date) async {
        let completed = habits.filter { $0.isCompleted }.count
        let total = habits.count
        let percentage = total > 0 ? (Double(completed) / Double(total)) * 100 : 0
        
        guard let userId = try? await supabase.auth.session.user.id else { return }
        
        let stats: [String: Any] = [
            "user_id": userId,
            "date": date,
            "completion_percentage": percentage,
            "habits_completed": completed,
            "total_habits": total
        ]
        
        try? await supabase
            .from("daily_stats")
            .insert(stats)
            .execute()
    }
    
    private func resetHabits() async {
        // Reset local habits
        for (index, habit) in habits.enumerated() where habit.isCompleted {
            habits[index].isCompleted = false
        }
        saveToCache()
        
        // Reset habits in Supabase
        guard let userId = try? await supabase.auth.session.user.id else { return }
        try? await supabase
            .from("habits")
            .update(["is_completed": false])
            .eq("user_id", value: userId)
            .execute()
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