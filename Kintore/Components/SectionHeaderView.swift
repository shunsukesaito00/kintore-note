// File: Components/SectionHeaderView.swift
// セクション見出し: 左アクセント（Phase 2: カプセル状で角に丸み）

import SwiftUI

struct SectionHeaderView: View {
    let title: String

    var body: some View {
        HStack(spacing: AppTheme.spacingSM) {
            Capsule()
                .fill(AppTheme.accent)
                .frame(width: 4, height: 18)
            Text(title)
                .font(AppTheme.sectionTitleFont)
                .foregroundStyle(AppTheme.primaryText)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, AppTheme.spacingSM)
        .padding(.bottom, AppTheme.spacingXS)
        .accessibilityAddTraits(.isHeader)
    }
}

#Preview {
    VStack(alignment: .leading) {
        SectionHeaderView(title: "直近の履歴")
        SectionHeaderView(title: "今週のサマリ")
    }
    .padding()
}
