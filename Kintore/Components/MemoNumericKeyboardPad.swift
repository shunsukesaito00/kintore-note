// File: Components/MemoNumericKeyboardPad.swift
// O1: カスタムテンキー（重量・回数入力の補助）。ルーラー連動は今後 `rulerValue` で拡張可能。

import SwiftUI

/// シートやオーバーレイで使う簡易テンキー。標準キーボードの代替・補助用。
struct MemoNumericKeyboardPad: View {
    @Binding var text: String
    /// 小数点を許可（重量用）
    var allowsDecimal: Bool = true
    /// 将来: ルーラー／プリセットと連動する値
    var rulerValue: Binding<Double?>? = nil

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        VStack(spacing: AppTheme.spacingSM) {
            if let ruler = rulerValue {
                Text(String(format: "%.2f", ruler.wrappedValue ?? 0))
                    .font(AppTheme.captionTypographyFont.monospacedDigit())
                    .foregroundStyle(AppTheme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(1 ... 9, id: \.self) { n in
                    keyButton("\(n)") { appendDigit(n) }
                }
                if allowsDecimal {
                    keyButton(".") {
                        if !text.contains(".") {
                            text += text.isEmpty ? "0." : "."
                        }
                    }
                } else {
                    Color.clear.frame(height: 44)
                }
                keyButton("0") { appendDigit(0) }
                Button {
                    HapticHelper.light()
                    if !text.isEmpty { _ = text.popLast() }
                } label: {
                    Image(systemName: "delete.left")
                        .font(AppTheme.setInputNumericFont)
                        .foregroundStyle(AppTheme.primaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(AppTheme.memoInputCellFill)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "memo_key_delete_a11y"))
            }
        }
        .padding(AppTheme.spacingMD)
        .background(AppTheme.memoRecordSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .stroke(Color(uiColor: .separator).opacity(0.35), lineWidth: 0.5)
        )
    }

    private func appendDigit(_ n: Int) {
        text.append(String(n))
    }

    private func keyButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticHelper.light()
            action()
        }) {
            Text(title)
                .font(AppTheme.setInputNumericFont)
                .foregroundStyle(AppTheme.primaryText)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(AppTheme.memoInputCellFill)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
        }
        .buttonStyle(.plain)
    }
}
