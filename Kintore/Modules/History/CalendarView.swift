// File: Modules/History/CalendarView.swift

import SwiftUI
import SwiftData

let calendarBodyParts = ["", "胸", "背中", "脚", "肩", "腕", "体幹", "有酸素"]

@Observable
private final class CalendarReviewViewModel {
    var daySummaries: [Int: CalendarDaySummaryDTO] = [:]
    var monthSummary = CalendarMonthSummaryDTO(sessionCount: 0, totalVolume: 0)
    func load(displayedMonth: Date, modelContext: ModelContext, bodyPart: String?) {
        do {
            let service = CalendarReviewService(modelContext: modelContext)
            daySummaries = try service.monthDaySummaries(monthAnchor: displayedMonth, bodyPart: bodyPart)
            monthSummary = try service.monthTotals(monthAnchor: displayedMonth, bodyPart: bodyPart)
        } catch {
            daySummaries = [:]
            monthSummary = CalendarMonthSummaryDTO(sessionCount: 0, totalVolume: 0)
        }
    }
}

struct CalendarView: View {
    @AppStorage(AppTheme.weightUnitStorageKey) private var weightUnit: String = "kg"
    @Environment(\.modelContext) private var modelContext
    var onDaySelected: ((Date) -> Void)?
    var selectedBodyPart: String?
    var selectedDate: Date?
    /// 履歴など高密度画面では `screenHorizontalPaddingCompact` を渡す
    var horizontalInset: CGFloat = AppTheme.screenHorizontalPadding
    @State private var displayedMonth: Date = Date()
    @State private var viewModel = CalendarReviewViewModel()

    private let calendar = Calendar.current
    private let weekdays = ["日", "月", "火", "水", "木", "金", "土"]

    init(
        onDaySelected: ((Date) -> Void)? = nil,
        selectedBodyPart: String? = nil,
        selectedDate: Date? = nil,
        horizontalInset: CGFloat = AppTheme.screenHorizontalPadding
    ) {
        self.onDaySelected = onDaySelected
        self.selectedBodyPart = selectedBodyPart
        self.selectedDate = selectedDate
        self.horizontalInset = horizontalInset
    }

    var body: some View {
        VStack(spacing: AppTheme.spacingMD) {
            HStack {
                Button { previousMonth() } label: { Image(systemName: "chevron.left") }
                    .accessibilityLabel("前の月")
                Spacer()
                Text(monthYearString(displayedMonth))
                    .font(AppTheme.sectionTitleFont)
                Spacer()
                Button { nextMonth() } label: { Image(systemName: "chevron.right") }
                    .accessibilityLabel("次の月")
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: AppTheme.spacingSM) {
                ForEach(weekdays, id: \.self) { d in
                    Text(d)
                        .font(AppTheme.tableHeaderLabelFont)
                        .foregroundStyle(AppTheme.secondaryText)
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
            HStack {
                Text(String(localized: "calendar_month_total"))
                    .font(AppTheme.captionTypographyFont)
                    .foregroundStyle(AppTheme.secondaryText)
                Spacer()
                Text("\(viewModel.monthSummary.sessionCount)\(String(localized: "unit_times")) / \(AppFormatters.formatWeightNumber(viewModel.monthSummary.totalVolume))\(weightUnit)")
                    .font(AppTheme.captionTypographyFont)
                    .foregroundStyle(AppTheme.primaryText)
            }
        }
        .padding(.vertical, AppTheme.spacingSM)
        .padding(.horizontal, horizontalInset)
        .onAppear { loadSessions() }
        .onChange(of: displayedMonth) { _, _ in loadSessions() }
        .onChange(of: selectedBodyPart) { _, _ in loadSessions() }
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
        let summary = viewModel.daySummaries[dayNum]
        let count = summary?.sessionCount ?? 0
        let isToday = calendar.isDateInToday(day)
        let isSelected = selectedDate.map { calendar.isDate($0, inSameDayAs: day) } ?? false
        return Button {
            onDaySelected?(day)
        } label: {
            dayNumberLabel(dayNum: dayNum, emphasized: count > 0 || isSelected)
                .foregroundStyle(isSelected ? AppTheme.accent : (count > 0 ? AppTheme.primaryText : AppTheme.secondaryText))
                .frame(height: 36)
                .frame(maxWidth: .infinity)
                .background(
                    Circle()
                        .fill(backgroundForDayCell(isToday: isToday, hasWorkout: count > 0, workoutDensity: count))
                )
                .overlay(
                    Circle()
                        .stroke(AppTheme.accent, lineWidth: AppTheme.cardStrokeWidth * 4)
                        .frame(width: 34, height: 34)
                        .opacity(isSelected ? 1 : 0)
                )
                .overlay(
                    Group {
                        if count > 0 {
                            Circle()
                                .fill(AppTheme.accent)
                                .frame(width: 7, height: 7)
                                .offset(y: 12)
                        }
                    }
                )
                .overlay(alignment: .topTrailing) {
                    if count > 1 {
                        Text("\(count)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(AppTheme.accent.opacity(0.92)))
                            .offset(x: 10, y: -6)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(dayNum)日、ワークアウト\(count)回\(isSelected ? "、選択中" : "")")
        .accessibilityHint("タップでその日の履歴を表示")
    }

    private func dayNumberLabel(dayNum: Int, emphasized: Bool) -> some View {
        Text("\(dayNum)")
            .font(emphasized ? Font.subheadline.weight(.semibold) : Font.subheadline)
    }

    private func backgroundForDayCell(isToday: Bool, hasWorkout: Bool, workoutDensity: Int) -> Color {
        if isToday {
            return AppTheme.accent.opacity(0.22)
        }
        if hasWorkout {
            let alpha = min(0.9, 0.3 + Double(workoutDensity) * 0.2)
            return AppTheme.accentSoft.opacity(alpha)
        }
        return Color.clear
    }

    private func loadSessions() {
        viewModel.load(displayedMonth: displayedMonth, modelContext: modelContext, bodyPart: selectedBodyPart)
    }
}

#Preview {
    CalendarView()
        .modelContainer(for: [WorkoutSession.self], inMemory: true)
}
