// File: Components/SecondaryActionButton.swift
// 枠線・フォアグラウンドをアクセントでセカンダリだが主張あり

import SwiftUI

struct SecondaryActionButton: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let title: String
    let action: () -> Void
    var isDisabled: Bool = false

    @State private var isPressed = false

    var body: some View {
        Button {
            HapticHelper.light()
            action()
        } label: {
            Text(title)
                .font(AppTheme.subheadlineFont.weight(.semibold))
                .foregroundStyle(AppTheme.accent)
                .frame(maxWidth: .infinity)
                .frame(minHeight: AppTheme.touchTargetSecondary)
                .contentShape(Rectangle())
                .background(AppTheme.accentSoft)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius)
                        .stroke(AppTheme.cardBorder, lineWidth: AppTheme.cardStrokeWidth)
                )
                .shadow(
                    color: isDisabled ? .clear : AppTheme.secondaryButtonShadowColor,
                    radius: AppTheme.secondaryButtonShadowRadius,
                    x: 0,
                    y: AppTheme.secondaryButtonShadowY
                )
                .scaleEffect((reduceMotion || isDisabled) ? 1.0 : (isPressed ? 0.98 : 1.0))
                .opacity(isPressed ? 0.94 : 1.0)
                .animation(AppTheme.animationButtonPress(reduceMotion: reduceMotion), value: isPressed)
        }
        .buttonStyle(.plain)
        .opacity(isDisabled ? 0.5 : 1)
        .disabled(isDisabled)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if !isDisabled { isPressed = true } }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityLabel(title)
        .accessibilityHint(String(localized: "a11y_generic_button_hint"))
    }
}

struct SecondaryActionLink<Destination: View>: View {
    let title: String
    let destination: () -> Destination

    var body: some View {
        NavigationLink(destination: destination()) {
            Text(title)
                .font(AppTheme.subheadlineFont.weight(.semibold))
                .foregroundStyle(AppTheme.accent)
                .frame(maxWidth: .infinity)
                .frame(minHeight: AppTheme.touchTargetSecondary)
                .contentShape(Rectangle())
                .background(AppTheme.accentSoft)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius)
                        .stroke(AppTheme.cardBorder, lineWidth: AppTheme.cardStrokeWidth)
                )
                .shadow(
                    color: AppTheme.secondaryButtonShadowColor,
                    radius: AppTheme.secondaryButtonShadowRadius,
                    x: 0,
                    y: AppTheme.secondaryButtonShadowY
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 12) {
        SecondaryActionButton(title: "前回のルーティンで続ける", action: {})
        SecondaryActionButton(title: "ルーティンを選ぶ", action: {})
    }
    .padding()
}
