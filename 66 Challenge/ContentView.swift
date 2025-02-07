//
//  ContentView.swift
//  66 Challenge
//
//  Created by Peter on 2025-02-06.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var habitStore = HabitStore()
    @State private var newHabitTitle = ""
    @State private var showingAddHabit = false
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        NavigationView {
            List {
                ForEach(habitStore.habits) { habit in
                    HStack {
                        Text(habit.title)
                        Spacer()
                        Image(systemName: habit.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(habit.isCompleted ? .green : .gray)
                            .onTapGesture {
                                Task {
                                    try? await habitStore.toggleHabit(habit)
                                }
                            }
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
                    Button(action: {
                        showingAddHabit = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddHabit) {
                NavigationView {
                    Form {
                        TextField("Habit Title", text: $newHabitTitle)
                    }
                    .navigationTitle("New Habit")
                    .navigationBarItems(
                        leading: Button("Cancel") {
                            showingAddHabit = false
                            newHabitTitle = ""
                        },
                        trailing: Button("Add") {
                            if !newHabitTitle.isEmpty {
                                Task {
                                    try? await habitStore.addHabit(title: newHabitTitle)
                                    newHabitTitle = ""
                                    showingAddHabit = false
                                }
                            }
                        }
                    )
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

#Preview {
    ContentView()
}
