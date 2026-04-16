// File: Components/ShareCardImageRenderer.swift
// 共有カード文面を画像化（ImageRenderer）。

import SwiftUI
import UIKit

private struct ShareCardSnapshotView: View {
    let lines: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                Text(line)
                    .font(AppTheme.bodyTypographyFont)
                    .foregroundStyle(AppTheme.primaryText)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(AppTheme.cardContentPadding)
        .frame(width: 340, alignment: .leading)
        .background(AppTheme.memoInputCellFill)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .strokeBorder(AppTheme.accent.opacity(0.35), lineWidth: 1)
        )
    }
}

enum ShareCardImageRenderer {
    /// テキスト行をカード風にレンダリングした画像。メインスレッドで呼ぶ。
    @MainActor
    static func uiImage(lines: [String], scale: CGFloat = UIScreen.main.scale) -> UIImage? {
        let view = ShareCardSnapshotView(lines: lines)
        let renderer = ImageRenderer(content: view)
        renderer.scale = scale
        return renderer.uiImage
    }
}
