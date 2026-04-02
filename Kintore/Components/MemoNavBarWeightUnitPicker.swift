// File: Components/MemoNavBarWeightUnitPicker.swift
// 記録ナビの kg/lb — 参照アプリ寄せ: 選択＝白地・非選択＝半透明（B4）

import SwiftUI

/// ダークナビバー上のセグメント。`selection` は `"kg"` / `"lb"`。
struct MemoNavBarWeightUnitPicker: View {
    @Binding var selection: String

    private var accent: Color {
        AppTheme.accent
    }

    var body: some View {
        HStack(spacing: 0) {
            segment(title: String(localized: "weight_unit_symbol_kg"), tag: "kg")
            segment(title: String(localized: "weight_unit_symbol_lb"), tag: "lb")
        }
        .padding(2)
        .background(Color.white.opacity(0.22))
        .clipShape(Capsule())
        .frame(width: 88)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "settings_picker_weight_unit"))
    }

    private func segment(title: String, tag: String) -> some View {
        let isOn = selection == tag
        return Button {
            HapticHelper.light()
            selection = tag
        } label: {
            Text(title)
                .font(AppTheme.smallCaptionFont.weight(.semibold))
                .foregroundStyle(isOn ? accent : Color.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(isOn ? Color.white : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}
