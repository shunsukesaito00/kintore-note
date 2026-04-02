import SwiftData
import SwiftUI

/// 週のトレーニング回数目標を設定するシート（ホーム・成長記録の概要から共通利用）
struct WeeklyGoalEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var draft: Int
    let onSaved: () -> Void

    init(initialGoal: Int, onSaved: @escaping () -> Void) {
        _draft = State(initialValue: initialGoal)
        self.onSaved = onSaved
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: AppTheme.spacingMD) {
                Text(String(localized: "weekly_goal_sheet_instruction"))
                    .font(AppTheme.captionTypographyFont)
                    .foregroundStyle(AppTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                WeeklyGoalQuickPickView(selection: $draft) { newValue in
                    try? SettingsRepository(modelContext: modelContext).updateWeeklyWorkoutGoalSessions(newValue)
                    onSaved()
                    dismiss()
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(AppTheme.spacingLG)
            .background(AppTheme.appBackground)
            .navigationTitle(String(localized: "weekly_goal_sheet_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common_close")) { dismiss() }
                }
            }
        }
    }
}
