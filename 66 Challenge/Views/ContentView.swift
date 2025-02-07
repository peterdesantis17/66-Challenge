import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var habitStore = HabitStore()
    @State private var showingAddHabit = false
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        NavigationView {
            List {
                ForEach(habitStore.habits) { habit in
                    HabitRow(habit: habit) {
                        try await habitStore.toggleHabit(habit)
                    }
                }
            }
            .navigationTitle("Habits")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        Task {
                            await authManager.signOut()
                        }
                    }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddHabit = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddHabit) {
                AddHabitSheet(isPresented: $showingAddHabit) { title in
                    try await habitStore.addHabit(title: title)
                }
            }
            .task {
                try? await habitStore.fetchHabits()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task {
                    await habitStore.checkForDayChange()
                }
            }
        }
    }
} 