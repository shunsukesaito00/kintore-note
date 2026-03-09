// File: Modules/History/CalendarView.swift

import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var displayedMonth: Date = Date()
    @State private var sessionsByDay: [Int: Int] = [:]
    @State private var selectedDay: Date?

    private let calendar = Calendar.current
    private let weekdays = ["日", "月", "火", "水", "木", "金", "土"]

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button { previousMonth() } label: { Image(systemName: "chevron.left") }
                Spacer()
                Text(monthYearString(displayedMonth))
                    .font(.headline)
                Spacer()
                Button { nextMonth() } label: { Image(systemName: "chevron.right") }
            }
            .padding(.horizontal)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(weekdays, id: \.self) { d in
                    Text(d)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                ForEach(daysInMonth(), id: \.self) { day in
                    if let day = day {
                        dayCell(day: day)
                    } else {
                        Color.clear
                            .frame(height: 36)
                    }
                }
            }
        }
        .padding()
        .onAppear { loadSessions() }
        .onChange(of: displayedMonth) { _, _ in loadSessions() }
    }

    private func previousMonth() {
        displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
    }

    private func nextMonth() {
        displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
    }

    private func monthYearString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }

    private func daysInMonth() -> [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth),
              let first = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)) else { return [] }
        let firstWeekday = calendar.component(.weekday, from: first) - 1
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        for day in range {
            if let d = calendar.date(byAdding: .day, value: day - 1, to: first) {
                days.append(d)
            }
        }
        return days
    }

    private func dayCell(day: Date) -> some View {
        let dayNum = calendar.component(.day, from: day)
        let count = sessionsByDay[dayNum] ?? 0
        let isToday = calendar.isDateInToday(day)
        return Text("\(dayNum)")
            .font(.subheadline)
            .frame(height: 36)
            .frame(maxWidth: .infinity)
            .background(isToday ? Color.accentColor.opacity(0.2) : Color.clear)
            .clipShape(Circle())
            .overlay(
                Group {
                    if count > 0 {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 6, height: 6)
                            .offset(y: 12)
                    }
                }
            )
    }

    private func loadSessions() {
        guard let start = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)),
              let end = calendar.date(byAdding: .month, value: 1, to: start) else { return }
        do {
            let sessions = try WorkoutRepository(modelContext: modelContext).fetchSessions(from: start, to: end)
            var byDay: [Int: Int] = [:]
            for s in sessions {
                let d = calendar.component(.day, from: s.startedAt)
                byDay[d, default: 0] += 1
            }
            sessionsByDay = byDay
        } catch {
            sessionsByDay = [:]
        }
    }
}

#Preview {
    CalendarView()
        .modelContainer(for: [WorkoutSession.self], inMemory: true)
}
