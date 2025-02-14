import SwiftUI
import Supabase

// Move current habit list view logic here
struct HabitsView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var habitStore: HabitStore
    @State private var showingAddHabit = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(habitStore.habits) { habit in
                    HabitRow(habit: habit) {
                        try await habitStore.toggleHabit(habit)
                    }
                }
                .onMove { from, to in
                    Task {
                        try? await habitStore.reorderHabits(from: from, to: to)
                    }
                }
            }
            .navigationTitle("Habits")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddHabit = true }) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showingAddHabit) {
                AddHabitSheet(isPresented: $showingAddHabit) { title in
                    try await habitStore.addHabit(title: title)
                }
            }
        }
        .task {
            try? await habitStore.fetchHabits()
        }
    }
} 