// File: Modules/History/SessionDetailView.swift

import SwiftUI
import SwiftData
import UIKit

private struct ShareDraft: Identifiable {
    let id = UUID()
    let kind: String
    let text: String
}

private struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}

private struct IdentifiableShareImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct SessionDetailView: View {
    @AppStorage(AppTheme.weightUnitStorageKey) private var weightUnit: String = "kg"
    @Environment(\.modelContext) private var modelContext

    /// 表示中のセッションID。履歴から「もう一度記録」で保存した直後に新セッションへ切り替える。
    @State private var activeSessionId: UUID
    @State private var viewModel = SessionDetailViewModel()
    @State private var repeatDraft: WorkoutSessionDraft?
    @State private var shareDraft: ShareDraft?
    @State private var exportFileURL: URL?
    @State private var shareImagePayload: IdentifiableShareImage?

    init(sessionId: UUID) {
        _activeSessionId = State(initialValue: sessionId)
    }

    var body: some View {
        Group {
            if let session = viewModel.session {
                sessionContent(session: session)
            } else if viewModel.loadError != nil {
                Text(viewModel.loadError ?? "")
                    .foregroundStyle(AppTheme.destructive)
            } else {
                ProgressView()
            }
        }
        .navigationTitle(String(localized: "nav_session_detail"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: ExerciseNavTarget.self) { target in
            ExerciseDetailView(exerciseId: target.id, exerciseName: target.name)
        }
        .toolbar {
            if let s = viewModel.session {
                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: AppTheme.spacingMD) {
                        Button {
                            startRepeatFromSession()
                        } label: {
                            Label(String(localized: "session_repeat_record"), systemImage: "arrow.counterclockwise")
                        }
                        .accessibilityLabel(String(localized: "session_repeat_record"))

                        Menu {
                            Button {
                                exportSessionCSV(session: s)
                            } label: {
                                Label(String(localized: "export_csv_session"), systemImage: "doc.plaintext")
                            }
                            Divider()
                            Button(String(localized: "session_share_session_card")) {
                                shareDraft = ShareDraft(kind: "session", text: ShareCardComposer.sessionCardText(session: s, weightUnit: weightUnit))
                            }
                            Button(String(localized: "session_share_pr_card")) {
                                shareDraft = ShareDraft(kind: "pr", text: ShareCardComposer.prCardText(session: s, weightUnit: weightUnit))
                            }
                            Button(String(localized: "session_share_monthly_report")) {
                                shareDraft = ShareDraft(
                                    kind: "monthly",
                                    text: ShareCardComposer.monthlyCardText(
                                        modelContext: modelContext,
                                        monthDate: s.startedAt,
                                        weightUnit: weightUnit
                                    )
                                )
                            }
                            Divider()
                            Button {
                                presentShareCardImage(text: ShareCardComposer.sessionCardText(session: s, weightUnit: weightUnit), analyticsKind: "session_image")
                            } label: {
                                Label(String(localized: "session_share_session_card_image"), systemImage: "photo")
                            }
                            Button {
                                presentShareCardImage(text: ShareCardComposer.prCardText(session: s, weightUnit: weightUnit), analyticsKind: "pr_image")
                            } label: {
                                Label(String(localized: "session_share_pr_card_image"), systemImage: "photo")
                            }
                            Button {
                                presentShareCardImage(
                                    text: ShareCardComposer.monthlyCardText(modelContext: modelContext, monthDate: s.startedAt, weightUnit: weightUnit),
                                    analyticsKind: "monthly_image"
                                )
                            } label: {
                                Label(String(localized: "session_share_monthly_report_image"), systemImage: "photo")
                            }
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .accessibilityLabel(String(localized: "session_share_a11y_menu"))
                    }
                }
            }
        }
        .fullScreenCover(item: $repeatDraft) { draft in
            WorkoutRecordView(
                draft: draft,
                onDismiss: { repeatDraft = nil },
                onSaveSuccess: { newSessionId in
                    repeatDraft = nil
                    activeSessionId = newSessionId
                }
            )
            .environment(\.modelContext, modelContext)
        }
        .onAppear { loadSession() }
        .onChange(of: activeSessionId) { _, _ in
            loadSession()
        }
        .sheet(item: $shareDraft) { draft in
            if let s = viewModel.session {
                SessionSharePreviewSheet(
                    shareKind: draft.kind,
                    shareText: draft.text,
                    session: s,
                    summary: viewModel.summary,
                    weightUnit: weightUnit,
                    modelContext: modelContext,
                    onDismiss: { shareDraft = nil }
                )
            }
        }
        .sheet(item: Binding(
            get: { exportFileURL.map { IdentifiableURL(url: $0) } },
            set: { exportFileURL = $0?.url }
        )) { identifiable in
            ShareSheet(activityItems: [identifiable.url], onDismiss: { exportFileURL = nil })
        }
        .sheet(item: $shareImagePayload) { payload in
            ShareSheet(activityItems: [payload.image], onDismiss: { shareImagePayload = nil })
        }
    }

    private func startRepeatFromSession() {
        guard let s = viewModel.session, let draft = WorkoutSessionDraft(repeating: s) else { return }
        repeatDraft = draft
    }

    private func loadSession() {
        viewModel.load(sessionId: activeSessionId, modelContext: modelContext)
    }

    private func sessionContent(session: WorkoutSession) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.spacingLG) {
                SectionCard(useElevatedSurface: true) {
                    VStack(alignment: .leading, spacing: AppTheme.spacingMD) {
                        Text(AppFormatters.formatDateWithWeekday(session.startedAt))
                            .font(AppTheme.sessionDateTitleFont)
                            .foregroundStyle(AppTheme.primaryText)
                        if let end = session.endedAt {
                            Text(String(format: String(localized: "session_detail_time_range_fmt"), AppFormatters.formatShortTime(session.startedAt), AppFormatters.formatShortTime(end)))
                                .font(AppTheme.captionTypographyFont)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                        HStack(spacing: AppTheme.spacingSM) {
                            if let d = viewModel.summary.durationSeconds {
                                MetricChip(text: AppFormatters.formatDuration(seconds: d))
                            }
                            MetricChip(text: "\(viewModel.summary.exerciseCount)\(String(localized: "unit_exercises"))")
                            MetricChip(text: "\(viewModel.summary.setCount)\(String(localized: "unit_sets"))")
                            MetricChip(text: "\(AppFormatters.formatWeightNumber(viewModel.summary.totalVolume))\(weightUnit)")
                        }
                        if viewModel.summary.exerciseCount > 0 {
                            let avgWeight = viewModel.summary.totalVolume / max(1, Double(viewModel.summary.setCount))
                            VStack(spacing: AppTheme.spacingSM) {
                                InlineStatView(
                                    label: String(localized: "session_detail_total_volume_label"),
                                    value: "\(AppFormatters.formatWeightNumber(viewModel.summary.totalVolume))\(weightUnit)"
                                )
                                InlineStatView(
                                    label: String(localized: "session_detail_total_reps"),
                                    value: "\(viewModel.summary.repCount)\(String(localized: "unit_reps"))"
                                )
                                InlineStatView(
                                    label: String(localized: "session_detail_avg_per_set"),
                                    value: "\(AppFormatters.formatWeightNumber(avgWeight))\(weightUnit)"
                                )
                            }
                        }
                    }
                }

                if !viewModel.exerciseMemoItems.isEmpty {
                    sessionMemoRollupSection
                }

                if !viewModel.prsAchieved.isEmpty {
                    sessionPRAchievedSection
                }

                if let hint = volumeVersusPreviousHint {
                    sessionNextHintSection(text: hint)
                }

                SessionReviewContentView(
                    session: session,
                    summary: nil,
                    weightUnit: weightUnit,
                    showSessionHeader: false
                )
            }
            .padding(.horizontal, AppTheme.sessionContentHorizontalPadding)
            .padding(.vertical, AppTheme.spacingMD)
        }
        .background(AppTheme.appBackground)
    }

    private var sessionMemoRollupSection: some View {
        SectionCard(useElevatedSurface: true) {
            VStack(alignment: .leading, spacing: AppTheme.spacingMD) {
                SectionHeaderView(title: String(localized: "session_detail_memos_title"))
                ForEach(Array(viewModel.exerciseMemoItems.enumerated()), id: \.offset) { _, item in
                    VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
                        Text(item.name)
                            .font(AppTheme.bodySemiboldFont)
                            .foregroundStyle(AppTheme.primaryText)
                        Text(item.memo)
                            .font(AppTheme.bodyTypographyFont)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var sessionPRAchievedSection: some View {
        SectionCard(useElevatedSurface: true) {
            VStack(alignment: .leading, spacing: AppTheme.spacingMD) {
                HStack(spacing: AppTheme.spacingSM) {
                    Image(systemName: "trophy.fill")
                        .foregroundStyle(AppTheme.accent)
                    Text(String(localized: "session_detail_pr_section_title"))
                        .font(AppTheme.bodySemiboldFont)
                        .foregroundStyle(AppTheme.primaryText)
                }
                ForEach(Array(viewModel.prsAchieved.enumerated()), id: \.element.0.id) { idx, pair in
                    HStack {
                        Text(pair.1)
                            .font(AppTheme.bodyTypographyFont)
                            .foregroundStyle(AppTheme.primaryText)
                            .lineLimit(1)
                        Spacer()
                        Text("\(AppFormatters.formatWeightNumber(pair.0.weight))\(weightUnit) × \(pair.0.reps)\(String(localized: "unit_reps"))")
                            .font(AppTheme.bodySemiboldFont)
                            .foregroundStyle(AppTheme.accent)
                    }
                    .padding(.vertical, AppTheme.spacingXS)
                    if idx < viewModel.prsAchieved.count - 1 {
                        Divider().opacity(0.35)
                    }
                }
            }
        }
    }

    private func sessionNextHintSection(text: String) -> some View {
        SectionCard(useElevatedSurface: true) {
            VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                HStack(spacing: AppTheme.spacingSM) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(AppTheme.accent)
                    Text(String(localized: "session_detail_next_hint_title"))
                        .font(AppTheme.bodySemiboldFont)
                        .foregroundStyle(AppTheme.primaryText)
                }
                Text(text)
                    .font(AppTheme.bodyTypographyFont)
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
    }


    private func exportSessionCSV(session: WorkoutSession) {
        let csv = ExportService.buildSessionCSV(session: session, weightUnit: weightUnit)
        guard let url = ExportService.writeSessionExportToTempFile(csv: csv) else { return }
        AnalyticsEventService.log(.csvExported(kind: "workout_session"))
        exportFileURL = url
    }

    private func presentShareCardImage(text: String, analyticsKind: String) {
        let lines = text.components(separatedBy: "\n")
        guard let img = ShareCardImageRenderer.uiImage(lines: lines) else { return }
        shareImagePayload = IdentifiableShareImage(image: img)
        AnalyticsEventService.log(.shareCardShared(kind: analyticsKind, source: "session_detail", screen: "history_detail", paywallState: "premium"))
    }

    /// 直前セッションとの総負荷比較文（次回の参考）
    private var volumeVersusPreviousHint: String? {
        guard let v = viewModel.volumeVersusPrevious else { return nil }
        let delta = v.deltaKg
        let prevLabel = AppFormatters.formatDateWithWeekday(v.previousStartedAt)
        if abs(delta) < 0.5 {
            return String(format: String(localized: "session_detail_insight_volume_flat_fmt"), prevLabel)
        }
        if delta > 0 {
            return String(format: String(localized: "session_detail_insight_volume_up_fmt"), prevLabel, AppFormatters.formatWeightNumber(delta), weightUnit)
        }
        return String(format: String(localized: "session_detail_insight_volume_down_fmt"), prevLabel, AppFormatters.formatWeightNumber(abs(delta)), weightUnit)
    }
}

#Preview {
    NavigationStack {
        SessionDetailView(sessionId: UUID())
    }
    .modelContainer(for: [WorkoutSession.self, WorkoutExercise.self, WorkoutSet.self, Exercise.self], inMemory: true)
}
