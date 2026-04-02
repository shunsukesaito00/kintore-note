// File: Components/PrimaryButton.swift
// Strong 風ソリッドブルーCTA・大型タップ領域・スプリング反応・ハプティクス

import SwiftUI

struct PrimaryButton: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let title: String
    let action: () -> Void
    var isDisabled: Bool = false

    @State private var isPressed = false

    var body: some View {
        Button {
            HapticHelper.medium()
            action()
        } label: {
            Text(title)
                .font(AppTheme.buttonLabelFont)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: AppTheme.touchTargetPrimary)
                .contentShape(Rectangle())
                .background(AppTheme.accent)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius))
                .shadow(
                    color: isDisabled ? .clear : AppTheme.primaryButtonShadowColor,
                    radius: AppTheme.primaryButtonShadowRadius,
                    x: 0,
                    y: AppTheme.primaryButtonShadowY
                )
                .scaleEffect((reduceMotion || isDisabled) ? 1.0 : (isPressed ? 0.97 : 1.0))
                .opacity(isPressed ? 0.92 : 1.0)
                .animation(AppTheme.animationButtonPress(reduceMotion: reduceMotion), value: isPressed)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.6 : 1)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if !isDisabled { isPressed = true } }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityLabel(title)
        .accessibilityHint(String(localized: "a11y_generic_button_hint"))
    }
}

#Preview("Light") {
    PrimaryButton(title: "今日のワークアウトを記録", action: {})
        .padding()
        .background(AppTheme.appBackground)
}

#Preview("Dark") {
    PrimaryButton(title: "今日のワークアウトを記録", action: {})
        .padding()
        .background(AppTheme.appBackground)
        .preferredColorScheme(.dark)
}
