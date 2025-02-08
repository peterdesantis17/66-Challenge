import SwiftUI

struct StatsView: View {
    @EnvironmentObject var habitStore: HabitStore
    @State private var isLoading = false
    @State private var error: String?
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading stats...")
                } else if let error = error {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                } else {
                    CalendarView()
                        .frame(height: 300)
                    
                    if habitStore.dailyStats.isEmpty {
                        Text("No stats available yet")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .navigationTitle("Progress")
        }
        .task {
            isLoading = true
            do {
                try await habitStore.fetchDailyStats()
            } catch {
                self.error = error.localizedDescription
            }
            isLoading = false
        }
    }
} 