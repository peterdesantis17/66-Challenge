import SwiftUI

struct StatsView: View {
    @EnvironmentObject var habitStore: HabitStore
    @State private var isLoading = false
    @State private var error: String?
    
    var body: some View {
        List {
            if isLoading {
                ProgressView("Loading stats...")
            } else if let error = error {
                Text("Error: \(error)")
                    .foregroundColor(.red)
            } else if habitStore.dailyStats.isEmpty {
                Text("No stats available yet")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(habitStore.dailyStats) { stat in
                    VStack(alignment: .leading) {
                        Text(stat.date, style: .date)
                            .font(.headline)
                        Text("Completion: \(Int(stat.completionPercentage))%")
                        Text("Completed: \(stat.habitsCompleted)/\(stat.totalHabits)")
                            .font(.caption)
                    }
                }
            }
        }
        .navigationTitle("Progress")
        .task {
            isLoading = true
            do {
                try await habitStore.fetchDailyStats()
            } catch {
                self.error = error.localizedDescription
                print("DEBUG: ❌ Failed to fetch stats: \(error)")
            }
            isLoading = false
        }
    }
} 