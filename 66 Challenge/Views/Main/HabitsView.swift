// Move current habit list view logic here
struct HabitsView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var habitStore = HabitStore()
    @State private var showingAddHabit = false
    
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
        }
        .task {
            try? await habitStore.fetchHabits()
        }
    }
} 