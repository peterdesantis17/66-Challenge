//
//  ContentView.swift
//  66 Challenge
//
//  Created by Peter on 2025-02-06.
//

import SwiftUI

struct Habit: Identifiable {
    let id = UUID()
    let title: String
    var isCompleted: Bool
}

struct ContentView: View {
    @State private var habits: [Habit] = []
    @State private var newHabitTitle = ""
    @State private var showingAddHabit = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(habits) { habit in
                    HStack {
                        Text(habit.title)
                        Spacer()
                        Image(systemName: habit.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(habit.isCompleted ? .green : .gray)
                            .onTapGesture {
                                if let index = habits.firstIndex(where: { $0.id == habit.id }) {
                                    habits[index].isCompleted.toggle()
                                }
                            }
                    }
                }
                .onDelete(perform: deleteHabits)
            }
            .navigationTitle("Habits")
            .toolbar {
                Button(action: {
                    showingAddHabit = true
                }) {
                    Image(systemName: "plus")
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
                                habits.append(Habit(title: newHabitTitle, isCompleted: false))
                                newHabitTitle = ""
                                showingAddHabit = false
                            }
                        }
                    )
                }
            }
        }
    }
    
    func deleteHabits(at offsets: IndexSet) {
        habits.remove(atOffsets: offsets)
    }
}

#Preview {
    ContentView()
}
