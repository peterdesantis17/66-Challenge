import SwiftUI

struct HabitRow: View {
    let habit: Habit
    let onToggle: () async throws -> Void
    
    var body: some View {
        HStack {
            Text(habit.title)
            Spacer()
            Image(systemName: habit.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(habit.isCompleted ? .green : .gray)
                .onTapGesture {
                    Task {
                        try? await onToggle()
                    }
                }
        }
    }
} 