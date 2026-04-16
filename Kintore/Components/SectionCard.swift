// File: Components/SectionCard.swift
// STRONG 寄りカード・Phase 1 トークン（角丸・ヘアライン枠・軽い Elevation）

import SwiftUI

/// カード内の詰め具合。一覧・統計は `compact` / `dense`、説明多めの閲覧は `regular`。
enum SectionCardDensity: Equatable {
    case regular
    case compact
    case dense
}

struct SectionCard<Content: View>: View {
    let content: () -> Content
    /// true のとき白に近い面（セッション詳細など・筋トレメモ風カード）
    var useElevatedSurface: Bool
    var density: SectionCardDensity

    init(useElevatedSurface: Bool = false, density: SectionCardDensity = .regular, @ViewBuilder content: @escaping () -> Content) {
        self.useElevatedSurface = useElevatedSurface
        self.density = density
        self.content = content
    }

    private var innerPadding: CGFloat {
        switch density {
        case .regular: return AppTheme.cardContentPadding
        case .compact: return AppTheme.cardContentPaddingCompact
        case .dense: return AppTheme.cardContentPaddingDense
        }
    }

    var body: some View {
        content()
            .padding(innerPadding)
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
