// File: Components/RecentSessionCardView.swift
// 直近の実績1件カード。日付・種目サマリ・総セット数。タップで SessionDetail へ。

import SwiftUI

struct RecentSessionCardView: View {
    let item: HomeSessionDisplayItem

    var body: some View {
        NavigationLink(value: item.sessionId) {
            SectionCard(useElevatedSurface: true) {
                VStack(alignment: .leading, spacing: AppTheme.memoTitleSubtitleGap + 6) {
                    Text(item.dateText)
                        .font(AppTheme.bodySemiboldFont)
                        .foregroundStyle(AppTheme.primaryText)
                    Text(item.exerciseSummaryText)
                        .font(AppTheme.bodySecondaryFont)
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineLimit(2)
                    Text("\(item.totalSetCount) \(String(localized: "unit_sets"))")
                        .font(AppTheme.chipLabelFont)
                        .foregroundStyle(AppTheme.accent)
                }
            }
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: AppTheme.cardStrokeWidth * 4)
                    .fill(AppTheme.accent)
                    .frame(width: 4)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            String(
                format: String(localized: "recent_session_card_a11y_fmt"),
                item.dateText,
                item.exerciseSummaryText,
                item.totalSetCount
            )
        )
        .accessibilityHint(String(localized: "recent_session_card_a11y_hint"))
    }
}

#Preview {
    NavigationStack {
        List {
            RecentSessionCardView(item: HomeSessionDisplayItem(
                sessionId: UUID(),
                dateText: "3/13(木)",
                exerciseSummaryText: "ベンチプレス・ショルダープレス・ディップス",
                totalSetCount: 12
            ))
        }
    }
}
