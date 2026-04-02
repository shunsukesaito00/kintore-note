import SwiftUI
import SwiftData

struct WorkoutCompleteSummaryView: View {
    @AppStorage(AppTheme.weightUnitStorageKey) private var weightUnit: String = "kg"
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let sessionId: UUID
    let onDismiss: () -> Void

    @State private var session: WorkoutSession?
    @State private var summary: SessionSummaryDTO?
    @State private var newPRs: [(PersonalRecord, String)] = []

    @State private var loadFailed = false
    @State private var prCelebrationShown = false
    @State private var showHealthKitSaveErrorAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.spacingLG) {
                    if loadFailed {
                        VStack(spacing: AppTheme.spacingMD) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.title)
                                .foregroundStyle(AppTheme.destructive)
                            Text(String(localized: "complete_summary_load_error"))
                                .font(AppTheme.bodyTypographyFont)
                                .foregroundStyle(AppTheme.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, AppTheme.spacingXL)
                    } else {
                        congratsHeader

                        if let summary {
                            summaryMetrics(summary)
                        }

                        if !newPRs.isEmpty {
                            prSection
                        }

                        if let session {
                            exerciseBestSets(session)
                        }
                    }
                }
                .padding(.horizontal, AppTheme.sessionContentHorizontalPadding)
                .padding(.vertical, AppTheme.spacingLG)
            }
            .appTabRootChrome()
            .navigationTitle(String(localized: "complete_summary_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "common_close")) { onDismiss() }
                        .font(AppTheme.bodySemiboldFont)
                        .foregroundStyle(AppTheme.accent)
                        .accessibilityLabel(String(localized: "common_close"))
                        .accessibilityHint(String(localized: "complete_summary_close_a11y_hint"))
                }
            }
        }
        .onAppear {
            loadSession()
            if HealthKitSettings.shouldShowHealthSaveErrorOnSummary,
               HealthKitSettings.lastSaveErrorMessage != nil {
                showHealthKitSaveErrorAlert = true
            }
        }
        .alert(String(localized: "healthkit_summary_save_failed_title"), isPresented: $showHealthKitSaveErrorAlert) {
            Button(String(localized: "common_ok")) {
                HealthKitSettings.acknowledgeHealthSaveErrorOnSummary()
            }
        } message: {
            Text(HealthKitSettings.lastSaveErrorMessage ?? "")
        }
    }

    private var congratsHeader: some View {
        VStack(spacing: AppTheme.spacingMD) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(AppTheme.accent)
                .symbolRenderingMode(.hierarchical)
            Text(String(localized: "complete_summary_congrats"))
                .font(AppTheme.titleFont)
                .foregroundStyle(AppTheme.primaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.spacingLG)
    }

    private func summaryMetrics(_ s: SessionSummaryDTO) -> some View {
        SectionCard {
            VStack(spacing: AppTheme.spacingMD) {
                HStack(spacing: 0) {
                    metricBlock(icon: "figure.strengthtraining.traditional", value: "\(s.exerciseCount)", label: String(localized: "complete_summary_exercises"))
                    metricDivider
                    metricBlock(icon: "number", value: "\(s.setCount)", label: String(localized: "complete_summary_sets"))
                    metricDivider
                    metricBlock(icon: "repeat", value: "\(s.repCount)", label: String(localized: "complete_summary_reps"))
                }
                HStack(spacing: 0) {
                    metricBlock(
                        icon: "scalemass.fill",
                        value: AppFormatters.formatWeightNumber(s.totalVolume),
                        label: weightUnit
                    )
                    metricDivider
                    if let dur = s.durationSeconds {
                        metricBlock(icon: "clock.fill", value: AppFormatters.formatDuration(seconds: dur), label: String(localized: "complete_summary_duration"))
                    }
                }
            }
        }
    }

    private var metricDivider: some View {
        Rectangle()
            .fill(AppTheme.separator.opacity(0.3))
            .frame(width: 1, height: 44)
    }

    private func metricBlock(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.accent)
            Text(value)
                .font(AppTheme.numericEmphasisFont)
                .foregroundStyle(AppTheme.primaryText)
            Text(label)
                .font(AppTheme.captionTypographyFont)
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }

    private var prSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
            HStack(spacing: AppTheme.spacingSM) {
                Image(systemName: "trophy.fill")
                    .font(.title2)
                    .foregroundStyle(AppTheme.accent)
                    .symbolEffect(.bounce, value: prCelebrationShown)
                Text(String(localized: "complete_summary_pr_title"))
                    .font(AppTheme.bodySemiboldFont)
                    .foregroundStyle(AppTheme.primaryText)
            }
            ForEach(newPRs, id: \.0.id) { pr, name in
                HStack {
                    Text(name)
                        .font(AppTheme.bodyTypographyFont)
                        .foregroundStyle(AppTheme.primaryText)
                        .lineLimit(1)
                    Spacer()
                    Text("\(AppFormatters.formatWeightNumber(pr.weight))\(weightUnit) × \(pr.reps)\(String(localized: "unit_reps"))")
                        .font(AppTheme.bodySemiboldFont)
                        .foregroundStyle(AppTheme.accent)
                }
                .padding(.vertical, AppTheme.spacingXS)
            }
        }
        .padding(AppTheme.memoCardPadding)
        .background(AppTheme.accentSoft.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                .stroke(AppTheme.accent.opacity(0.35), lineWidth: AppTheme.cardStrokeWidth * 2)
        )
        .scaleEffect(reduceMotion ? 1.0 : (prCelebrationShown ? 1.0 : 0.92))
        .animation(AppTheme.animationCelebration(reduceMotion: reduceMotion), value: prCelebrationShown)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                prCelebrationShown = true
                Task { @MainActor in HapticHelper.success() }
            }
        }
    }

    private func exerciseBestSets(_ session: WorkoutSession) -> some View {
        let exercises = session.workoutExercises.sorted { $0.orderIndex < $1.orderIndex }
        return VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
            Text(String(localized: "complete_summary_best_sets"))
                .font(AppTheme.bodySemiboldFont)
                .foregroundStyle(AppTheme.primaryText)
            ForEach(exercises, id: \.id) { we in
                let sets = we.sets.sorted { $0.orderIndex < $1.orderIndex }
                let exKind = ExerciseKind(stored: we.exercise?.exerciseKind)
                let bestSet = sets.filter { $0.weight != nil && $0.reps != nil }
                    .max(by: { VolumeCalculator.volume(weight: $0.weight, reps: $0.reps) < VolumeCalculator.volume(weight: $1.weight, reps: $1.reps) })
                HStack {
                    Text(we.exercise?.name ?? "—")
                        .font(AppTheme.bodyTypographyFont)
                        .foregroundStyle(AppTheme.primaryText)
                        .lineLimit(1)
                    Spacer()
                    if exKind.usesLoadVolume, let best = bestSet {
                        Text("\(AppFormatters.formatWeightNumericOnly(best.weight))\(weightUnit) × \(best.reps ?? 0)\(String(localized: "unit_reps"))")
                            .font(AppTheme.bodySemiboldFont)
                            .foregroundStyle(AppTheme.accent)
                    } else if exKind == .time, let best = bestSet {
                        Text("\(best.durationSeconds ?? 0)\(String(localized: "unit_seconds"))")
                            .font(AppTheme.bodySemiboldFont)
                            .foregroundStyle(AppTheme.accent)
                    }
                    Text("\(sets.count)\(String(localized: "unit_sets_short"))")
                        .font(AppTheme.captionTypographyFont)
                        .foregroundStyle(AppTheme.tertiaryText)
                }
                .padding(.vertical, AppTheme.spacingXS)
                if we.id != exercises.last?.id {
                    Divider()
                }
            }
        }
        .padding(AppTheme.memoCardPadding)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                .stroke(AppTheme.cardBorder, lineWidth: AppTheme.cardStrokeWidth)
        )
        .appSubtleElevatedShadow()
    }

    private func loadSession() {
        do {
            let repo = WorkoutRepository(modelContext: modelContext)
            session = try repo.fetchSession(by: sessionId)
            if let session {
                summary = SessionReviewService(modelContext: modelContext).summary(for: session)
                loadSessionPRs(session)
                loadFailed = false
            } else {
                loadFailed = true
            }
        } catch {
            session = nil
            loadFailed = true
        }
    }

    private func loadSessionPRs(_ session: WorkoutSession) {
        newPRs = (try? SessionReviewService(modelContext: modelContext).personalRecordsAchieved(in: session)) ?? []
    }
}
