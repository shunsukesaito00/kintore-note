import SwiftUI

/// 月のトレーニング回数目標（0…31）をタップで選ぶ。
struct MonthlyGoalQuickPickView: View {
    @Binding var selection: Int
    var onCommit: ((Int) -> Void)? = nil

    private let columns = [
        GridItem(.flexible(), spacing: AppTheme.spacingSM),
        GridItem(.flexible(), spacing: AppTheme.spacingSM),
        GridItem(.flexible(), spacing: AppTheme.spacingSM),
        GridItem(.flexible(), spacing: AppTheme.spacingSM),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
            offRow
            ScrollView {
                LazyVGrid(columns: columns, spacing: AppTheme.spacingSM) {
                    ForEach(1 ... 31, id: \.self) { n in
                        goalChip(value: n, title: "\(n)", accessibilityLabel: timesLabel(n))
                    }
                }
            }
            .frame(maxHeight: 320)
        }
        .accessibilityElement(children: .contain)
    }

    private var offRow: some View {
        let selected = selection == 0
        let title = String(localized: "settings_weekly_workout_goal_off")
        return Button {
            selection = 0
            HapticHelper.light()
            onCommit?(0)
        } label: {
            Text(title)
                .font(AppTheme.bodySemiboldFont)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.spacingMD)
                .padding(.horizontal, AppTheme.spacingSM)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                        .fill(selected ? AppTheme.accent.opacity(0.18) : AppTheme.cardBackground.opacity(0.9))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                        .stroke(selected ? AppTheme.accent : AppTheme.cardBorder, lineWidth: selected ? 2 : AppTheme.cardStrokeWidth)
                )
                .foregroundStyle(selected ? AppTheme.accent : AppTheme.primaryText)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    @ViewBuilder
    private func goalChip(value: Int, title: String, accessibilityLabel: String) -> some View {
        let selected = selection == value
        Button {
            selection = value
            HapticHelper.light()
            onCommit?(value)
        } label: {
            Text(title)
                .font(AppTheme.numericEmphasisFont)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.spacingSM + 2)
                .padding(.horizontal, AppTheme.spacingXS)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                        .fill(selected ? AppTheme.accent.opacity(0.18) : AppTheme.cardBackground.opacity(0.9))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                        .stroke(selected ? AppTheme.accent : AppTheme.cardBorder, lineWidth: selected ? 2 : AppTheme.cardStrokeWidth)
                )
                .foregroundStyle(selected ? AppTheme.accent : AppTheme.primaryText)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func timesLabel(_ n: Int) -> String {
        String(format: String(localized: "settings_monthly_workout_goal_times_format"), n)
    }
}
