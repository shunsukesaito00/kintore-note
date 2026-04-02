// File: Components/MetricChip.swift
// アクセント薄塗り背景・Phase 2: ヘアライン枠＋軽い Elevation（Phase 1 トークンと整合）

import SwiftUI

struct MetricChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(AppTheme.chipLabelFont)
            .foregroundStyle(AppTheme.pillForeground)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(AppTheme.pillBackground)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(AppTheme.cardBorder, lineWidth: AppTheme.cardStrokeWidth)
            )
            .shadow(
                color: AppTheme.chipShadowColor,
                radius: AppTheme.chipShadowRadius,
                x: 0,
                y: AppTheme.chipShadowY
            )
    }
}

#Preview("Light") {
    HStack {
        MetricChip(text: "3/6")
        MetricChip(text: "5種目")
    }
    .padding()
    .background(AppTheme.appBackground)
}

#Preview("Dark") {
    HStack {
        MetricChip(text: "3/6")
        MetricChip(text: "5種目")
    }
    .padding()
    .background(AppTheme.appBackground)
    .preferredColorScheme(.dark)
}
