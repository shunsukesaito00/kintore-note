import SwiftUI

struct TrainingHeatmapView: View {
    let dailyCounts: [Date: Int]
    private let calendar = Calendar.current
    private let weekCount = 12

    private var weekdayFrequency: [Int] {
        var counts = [Int](repeating: 0, count: 7)
        for (date, count) in dailyCounts where count > 0 {
            let wd = (calendar.component(.weekday, from: date) + 5) % 7
            counts[wd] += count
        }
        return counts
    }

    private var weeklyHistory: [(label: String, count: Int)] {
        let today = calendar.startOfDay(for: Date())
        guard let todayWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) else { return [] }
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ja_JP")
        fmt.dateFormat = "M/d"
        var result: [(String, Int)] = []
        for offset in (0..<weekCount).reversed() {
            guard let ws = calendar.date(byAdding: .weekOfYear, value: -offset, to: todayWeekStart) else { continue }
            var total = 0
            for dayOffset in 0..<7 {
                guard let d = calendar.date(byAdding: .day, value: dayOffset, to: ws) else { continue }
                total += dailyCounts[calendar.startOfDay(for: d)] ?? 0
            }
            result.append((fmt.string(from: ws), total))
        }
        return result
    }

    private var totalDays: Int { dailyCounts.values.filter { $0 > 0 }.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            weekdaySection
            Divider().opacity(0.3)
            weeklySection
        }
    }

    // MARK: - 曜日別

    private var weekdaySection: some View {
        let days = ["月", "火", "水", "木", "金", "土", "日"]
        let freq = weekdayFrequency
        let maxVal = max(freq.max() ?? 1, 1)

        return VStack(alignment: .leading, spacing: 8) {
            Text("曜日別トレーニング回数")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.primaryText)

            ForEach(0..<7, id: \.self) { i in
                HStack(spacing: 8) {
                    Text(days[i])
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.secondaryText)
                        .frame(width: 20, alignment: .center)

                    GeometryReader { geo in
                        let ratio = CGFloat(freq[i]) / CGFloat(maxVal)
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color(uiColor: .systemGray5))
                            Capsule()
                                .fill(barColor(for: freq[i], max: maxVal))
                                .frame(width: max(0, geo.size.width * ratio))
                        }
                    }
                    .frame(height: 16)

                    Text("\(freq[i])")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(freq[i] > 0 ? AppTheme.accent : AppTheme.tertiaryText)
                        .frame(width: 24, alignment: .trailing)
                }
            }
        }
    }

    private func barColor(for value: Int, max: Int) -> Color {
        guard max > 0, value > 0 else { return Color.clear }
        let ratio = Double(value) / Double(max)
        if ratio > 0.7 { return AppTheme.accent }
        if ratio > 0.3 { return AppTheme.accent.opacity(0.6) }
        return AppTheme.accent.opacity(0.35)
    }

    // MARK: - 週別

    private var weeklySection: some View {
        let history = weeklyHistory
        let maxWeek = max(history.map(\.count).max() ?? 1, 1)

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("週ごとの実績")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.primaryText)
                Spacer()
                Text("直近\(weekCount)週 / 合計\(totalDays)日")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(AppTheme.secondaryText)
            }

            HStack(alignment: .bottom, spacing: 3) {
                ForEach(Array(history.enumerated()), id: \.offset) { _, item in
                    VStack(spacing: 4) {
                        Text("\(item.count)")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(item.count > 0 ? AppTheme.accent : AppTheme.tertiaryText)

                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(item.count > 0 ? AppTheme.accent.opacity(Double(item.count) / Double(maxWeek) * 0.6 + 0.3) : Color(uiColor: .systemGray5))
                            .frame(height: max(8, CGFloat(item.count) / CGFloat(maxWeek) * 60))

                        Text(item.label)
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(AppTheme.tertiaryText)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 90)
        }
    }
}
