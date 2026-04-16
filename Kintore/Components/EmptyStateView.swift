// File: Components/EmptyStateView.swift
// Phase 2: アイコン台紙を角丸＋ヘアライン＋軽い影でカード系と統一

import SwiftUI

struct EmptyStateView: View {
    let message: String
    var icon: String = "tray"
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: AppTheme.emptyStateContentSpacing) {
            Image(systemName: icon)
                .font(.system(size: AppTheme.emptyStateIconGlyphSize))
                .foregroundStyle(AppTheme.accent)
                .frame(width: AppTheme.emptyStateIconPlateSize, height: AppTheme.emptyStateIconPlateSize)
                .background(AppTheme.accentTintBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.emptyStateIconCornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.emptyStateIconCornerRadius, style: .continuous)
                        .stroke(AppTheme.cardBorder, lineWidth: AppTheme.cardStrokeWidth)
                )
                .shadow(
                    color: .black.opacity(AppTheme.cardShadowOpacity * 0.45),
                    radius: AppTheme.cardShadowRadius * 0.55,
                    x: 0,
                    y: AppTheme.cardShadowY * 0.65
                )
            Text(message)
                .font(AppTheme.bodySecondaryFont)
                .foregroundStyle(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 520)
            if let title = actionTitle, let action {
                Button(action: action) {
                    Text(title)
                        .font(AppTheme.bodySemiboldFont)
                        .foregroundStyle(AppTheme.accent)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.emptyStateVerticalPadding)
        .padding(.horizontal, AppTheme.screenHorizontalPadding)
    }
}

#Preview("Light") {
    VStack(spacing: 40) {
        EmptyStateView(message: "まだ履歴がありません")
        EmptyStateView(
            message: "記録がありません",
            icon: "figure.stand",
            actionTitle: "追加する",
            action: {}
        )
    }
    .background(AppTheme.appBackground)
}

#Preview("Dark") {
    VStack(spacing: 40) {
        EmptyStateView(message: "まだ履歴がありません")
        EmptyStateView(
            message: "記録がありません",
            icon: "figure.stand",
            actionTitle: "追加する",
            action: {}
        )
    }
    .background(AppTheme.appBackground)
    .preferredColorScheme(.dark)
}
