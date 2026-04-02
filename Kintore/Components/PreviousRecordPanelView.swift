// File: Components/PreviousRecordPanelView.swift
// 前回記録（セッション詳細と同系のタイポ）

import SwiftUI

struct PreviousRecordPanelView: View {
    let dateString: String
    let setLines: [String]
    /// MEMO 風: 履歴リンク・一括コピー
    var memoChrome: Bool = false
    var exerciseId: UUID?
    var exerciseName: String = ""
    var onCopyAll: (() -> Void)?

    /// 「前回：」と日付を同一行（例: 前回：2026/03/21）
    private var memoChromeTitleLine: String {
        String(localized: "previous_record_title_prefix") + dateString
    }

    var body: some View {
        VStack(alignment: .leading, spacing: memoChrome ? 4 : 8) {
            if memoChrome {
                HStack(alignment: .center, spacing: 6) {
                    Text(memoChromeTitleLine)
                        .font(AppTheme.previousRecordPanelUnifiedFont)
                        .foregroundStyle(AppTheme.primaryText)
                        .lineLimit(2)
                        .minimumScaleFactor(0.88)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    HStack(spacing: AppTheme.spacingSM) {
                        if let id = exerciseId {
                            NavigationLink {
                                ExerciseDetailView(exerciseId: id, exerciseName: exerciseName)
                            } label: {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(AppTheme.previousRecordPanelUnifiedFont)
                                    .foregroundStyle(AppTheme.accent)
                                    .frame(width: 28, height: 28)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(String(localized: "previous_record_history_link"))
                        }
                        if let onCopy = onCopyAll {
                            Button {
                                HapticHelper.light()
                                onCopy()
                            } label: {
                                Image(systemName: "doc.on.doc")
                                    .font(AppTheme.previousRecordPanelUnifiedFont)
                                    .foregroundStyle(AppTheme.accent)
                                    .frame(width: 28, height: 28)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(String(localized: "previous_record_copy_all_a11y"))
                        }
                    }
                }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(String(localized: "previous_record_simple_title"))
                        .font(AppTheme.tableHeaderLabelFont)
                        .foregroundStyle(AppTheme.secondaryText)
                    Text(dateString)
                        .font(AppTheme.exerciseVolumeSubtitleFont)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }

            VStack(alignment: .leading, spacing: memoChrome ? 2 : 4) {
                ForEach(Array(setLines.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(memoChrome ? AppTheme.previousRecordPanelUnifiedFont.monospacedDigit() : AppTheme.bodySecondaryFont)
                        .foregroundStyle(AppTheme.primaryText)
                        .lineLimit(2)
                        .minimumScaleFactor(memoChrome ? 0.88 : 0.92)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(memoChrome ? 6 : 12)
        .background(memoChrome ? AppTheme.memoInputCellFill : Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: memoChrome ? 10 : 8, style: .continuous))
        .overlay {
            if memoChrome {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color(uiColor: .separator).opacity(0.45), lineWidth: 0.5)
            }
        }
    }
}

#Preview {
    PreviousRecordPanelView(
        dateString: "2026/03/14",
        setLines: ["1  60kg × 10回", "2  60kg × 10回", "3  55kg × 8回"]
    )
    .padding()
}
