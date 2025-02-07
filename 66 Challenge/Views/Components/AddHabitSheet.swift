import SwiftUI

struct AddHabitSheet: View {
    @Binding var isPresented: Bool
    @State private var title = ""
    let onAdd: (String) async throws -> Void
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Habit Title", text: $title)
            }
            .navigationTitle("New Habit")
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                    title = ""
                },
                trailing: Button("Add") {
                    if !title.isEmpty {
                        Task {
                            try? await onAdd(title)
                            title = ""
                            isPresented = false
                        }
                    }
                }
            )
        }
    }
} 