import Foundation

enum ExerciseTrendPeriod: String, CaseIterable {
    case oneMonth
    case threeMonths
    case sixMonths
    case twelveMonths
    case all

    var displayName: String {
        switch self {
        case .oneMonth:      return String(localized: "period_one_month")
        case .threeMonths:   return String(localized: "period_three_months")
        case .sixMonths:     return String(localized: "period_six_months")
        case .twelveMonths:  return String(localized: "period_twelve_months")
        case .all:           return String(localized: "period_all")
        }
    }

    func startDate(from now: Date = Date()) -> Date? {
        let cal = Calendar.current
        switch self {
        case .oneMonth:
            return cal.date(byAdding: .month, value: -1, to: now)
        case .threeMonths:
            return cal.date(byAdding: .month, value: -3, to: now)
        case .sixMonths:
            return cal.date(byAdding: .month, value: -6, to: now)
        case .twelveMonths:
            return cal.date(byAdding: .month, value: -12, to: now)
        case .all:
            return nil
        }
    }
}
