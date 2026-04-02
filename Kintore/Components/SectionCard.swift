// File: Components/SectionCard.swift
// STRONG 寄りカード・Phase 1 トークン（角丸・ヘアライン枠・軽い Elevation）

import SwiftUI

struct SectionCard<Content: View>: View {
    let content: () -> Content
    /// true のとき白に近い面（セッション詳細など・筋トレメモ風カード）
    var useElevatedSurface: Bool

    init(useElevatedSurface: Bool = false, @ViewBuilder content: @escaping () -> Content) {
        self.useElevatedSurface = useElevatedSurface
        self.content = content
    }

    var body: some View {
        content()
            .padding(AppTheme.spacingLG)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(useElevatedSurface ? AppTheme.memoRecordSurface : AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                    .stroke(AppTheme.cardBorder, lineWidth: AppTheme.cardStrokeWidth)
            )
            .shadow(
                color: .black.opacity(AppTheme.cardShadowOpacity),
                radius: AppTheme.cardShadowRadius,
                x: 0,
                y: AppTheme.cardShadowY
            )
    }
}

#Preview("Light") {
    SectionCard {
        Text(String(localized: "section_card_preview_placeholder"))
    }
    .padding()
    .background(AppTheme.appBackground)
}

#Preview("Dark") {
    SectionCard {
        Text(String(localized: "section_card_preview_placeholder"))
    }
    .padding()
    .background(AppTheme.appBackground)
    .preferredColorScheme(.dark)
}
