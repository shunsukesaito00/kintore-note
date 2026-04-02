// File: Components/InlineStatView.swift
// 値は metricFont・アクセント色で強調

import SwiftUI

struct InlineStatView: View {
    let label: String
    let value: String
    var valueEmphasis: Bool = true

    var body: some View {
        HStack {
            Text(label)
                .font(AppTheme.subheadlineFont)
                .foregroundStyle(AppTheme.secondaryText)
            Spacer()
            Text(value)
                .font(valueEmphasis ? AppTheme.metricFont : AppTheme.subheadlineFont)
                .foregroundStyle(valueEmphasis ? AppTheme.accent : .primary)
        }
    }
}

#Preview {
    SectionCard {
        VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
            InlineStatView(label: "実施", value: "3 回")
            InlineStatView(label: "総挙上", value: "12,500 kg")
        }
    }
    .padding()
}
