import SwiftUI

struct ContentView: View {
    @StateObject private var habitStore = HabitStore()
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        TabView {
            HabitsView()
                .environmentObject(habitStore)
                .tabItem {
                    Label("Habits", systemImage: "checkmark.circle.fill")
                }
            
            StatsView()
                .environmentObject(habitStore)
                .tabItem {
                    Label("Progress", systemImage: "chart.bar.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
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