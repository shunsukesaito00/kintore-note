import SwiftUI

struct ChartAnnotationBubble: View {
    let date: Date
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(AppFormatters.formatDate(date))
                .font(.caption2)
                .foregroundStyle(AppTheme.secondaryText)
            Text("\(label): \(value)")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(AppTheme.primaryText)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(AppTheme.cardBorder, lineWidth: 0.5))
    }
}
