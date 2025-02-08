import SwiftUI
import FSCalendar

struct CalendarView: UIViewRepresentable {
    @EnvironmentObject var habitStore: HabitStore
    
    func makeUIView(context: Context) -> FSCalendar {
        let calendar = FSCalendar()
        calendar.delegate = context.coordinator
        calendar.dataSource = context.coordinator
        
        // Basic styling
        calendar.appearance.titleDefaultColor = .label
        calendar.appearance.headerTitleColor = .label
        calendar.appearance.weekdayTextColor = .label
        calendar.appearance.todayColor = nil // Remove default today color
        calendar.appearance.selectionColor = .systemBlue
        
        return calendar
    }
    
    func updateUIView(_ uiView: FSCalendar, context: Context) {
        uiView.reloadData()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    @MainActor
    class Coordinator: NSObject, FSCalendarDelegate, FSCalendarDataSource, FSCalendarDelegateAppearance {
        var parent: CalendarView
        
        init(_ parent: CalendarView) {
            self.parent = parent
        }
        
        // This is the correct method for coloring dates
        @MainActor
        func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, fillSelectionColorFor date: Date) -> UIColor? {
            return .systemBlue
        }
        
        @MainActor
        func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, fillDefaultColorFor date: Date) -> UIColor? {
            if let stat = parent.habitStore.dailyStats.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
                let percentage = stat.completionPercentage
                
                switch percentage {
                case 0:
                    return .systemGray.withAlphaComponent(0.3)
                case 1...20:
                    return .systemGreen.withAlphaComponent(0.2)
                case 21...40:
                    return .systemGreen.withAlphaComponent(0.4)
                case 41...60:
                    return .systemGreen.withAlphaComponent(0.6)
                case 61...80:
                    return .systemGreen.withAlphaComponent(0.8)
                default:
                    return .systemGreen
                }
            }
            return nil
        }
        
        // Add this method to show today with a circle
        @MainActor
        func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, borderDefaultColorFor date: Date) -> UIColor? {
            if Calendar.current.isDateInToday(date) {
                return .systemBlue
            }
            return nil
        }
        
        // Add this method to customize border radius
        @MainActor
        func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, borderRadiusFor date: Date) -> CGFloat {
            return 0.5
        }
    }
} 