// File: Modules/Home/HomeView.swift
// ホーム: MEMO 風ダッシュボード + セッションフローへのエントリ

import SwiftUI
import SwiftData

private struct SessionFlowRequest: Identifiable {
    let id = UUID()
    let draft: WorkoutSessionDraft
}

private struct CompletedSessionItem: Identifiable {
    let id: UUID
}

struct HomeView: View {
    @AppStorage(AppTheme.weightUnitStorageKey) private var weightUnit: String = "kg"
    @Environment(\.modelContext) private var modelContext
    @Bindable private var premium = PremiumService.shared
    @Binding var openWorkoutAfterOnboarding: Bool
    @State private var viewModel: HomeViewModel?
    @State private var sessionFlowRequest: SessionFlowRequest?
    @State private var showWorkoutStart = false
    @State private var completedSession: CompletedSessionItem?
    @State private var showWeeklyGoalSheet = false

    private var horizontalPadding: CGFloat { AppTheme.sessionContentHorizontalPadding }

    var body: some View {
        Group {
            if let vm = viewModel {
                mainContent(vm: vm)
            } else {
                ProgressView(String(localized: "home_loading"))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .appTabRootChrome()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                NavigationLink {
                    SettingsView()
                        .environment(\.modelContext, modelContext)
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.body.weight(.medium))
                        .foregroundStyle(AppTheme.accent)
                }
                .accessibilityLabel(String(localized: "nav_settings_title"))
                .accessibilityHint(String(localized: "home_toolbar_settings_a11y_hint"))
            }
            ToolbarItem(placement: .principal) {
                Text(String(localized: "app_display_name"))
                    .font(AppTheme.headlineFont)
                    .foregroundStyle(AppTheme.primaryText)
                    .dynamicTypeNavigationPrincipal()
            }
        }
        .fullScreenCover(item: $sessionFlowRequest) { request in
            WorkoutSessionFlowView(
                draft: request.draft,
                onDismiss: {
                    sessionFlowRequest = nil
                    viewModel?.loadRecentSessions()
                    WidgetDataStore.updateFrom(modelContext: modelContext)
                },
                onSaveSuccess: { savedId in
                    sessionFlowRequest = nil
                    viewModel?.loadRecentSessions()
                    completedSession = CompletedSessionItem(id: savedId)
                }
            )
            .environment(\.modelContext, modelContext)
        }
        .fullScreenCover(isPresented: $showWorkoutStart) {
            WorkoutStartView(
                initialTemplate: nil,
                onDismiss: {
                    showWorkoutStart = false
                    viewModel?.loadRecentSessions()
                    WidgetDataStore.updateFrom(modelContext: modelContext)
                },
                onSessionCompleted: { savedId in
                    showWorkoutStart = false
                    viewModel?.loadRecentSessions()
                    WidgetDataStore.updateFrom(modelContext: modelContext)
                    completedSession = CompletedSessionItem(id: savedId)
                }
            )
            .environment(\.modelContext, modelContext)
        }
        .sheet(item: $completedSession) { item in
            WorkoutCompleteSummaryView(sessionId: item.id) {
                completedSession = nil
            }
            .environment(\.modelContext, modelContext)
            .standardSheetChrome()
        }
        .sheet(isPresented: $showWeeklyGoalSheet) {
            WeeklyGoalEditorSheet(initialGoal: viewModel?.weeklyWorkoutGoalSessions ?? 0) {
                viewModel?.loadRecentSessions()
            }
            .environment(\.modelContext, modelContext)
            .standardSheetChrome()
        }
        .onAppear {
            createViewModelAndLoadIfNeeded()
            WidgetDataStore.updateFrom(modelContext: modelContext)
        }
    }

    @ViewBuilder
    private func mainContent(vm: HomeViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.memoSectionGap) {
                if let error = vm.errorMessage {
                    HStack(spacing: AppTheme.spacingSM) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(AppTheme.destructive)
                        Text(error)
                            .font(AppTheme.captionTypographyFont)
                            .foregroundStyle(AppTheme.destructive)
                        Spacer()
                        Button { vm.loadRecentSessions() } label: {
                            Text(String(localized: "common_retry"))
                                .font(AppTheme.captionTypographyFont)
                                .foregroundStyle(AppTheme.accent)
                        }
                    }
                    .padding(AppTheme.spacingMD)
                    .background(AppTheme.destructive.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.chipCornerRadius, style: .continuous))
                    .padding(.horizontal, horizontalPadding)
                }
                // 1. 今週のハイライト
                HomeWeeklySummaryCard(viewModel: vm, weightUnit: weightUnit)
                    .padding(.horizontal, horizontalPadding)

                // 2. 週のトレーニング目標を設定
                if vm.weeklyWorkoutGoalSessions == 0 {
                    Button {
                        showWeeklyGoalSheet = true
                    } label: {
                        HStack(spacing: AppTheme.spacingSM) {
                            Image(systemName: "target")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(AppTheme.accent)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(String(localized: "home_weekly_goal_prompt_title"))
                                    .font(AppTheme.bodyTypographyFont.weight(.semibold))
                                    .foregroundStyle(AppTheme.primaryText)
                                    .multilineTextAlignment(.leading)
                                Text(String(localized: "home_weekly_goal_prompt_subtitle"))
                                    .font(AppTheme.captionTypographyFont)
                                    .foregroundStyle(AppTheme.secondaryText)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppTheme.tertiaryText)
                        }
                        .padding(AppTheme.spacingMD)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                                .stroke(AppTheme.cardBorder, lineWidth: AppTheme.cardStrokeWidth)
                        )
                        .shadow(
                            color: .black.opacity(AppTheme.cardShadowOpacity * 0.45),
                            radius: AppTheme.cardShadowRadius * 0.5,
                            x: 0,
                            y: AppTheme.cardShadowY * 0.5
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, horizontalPadding)
                }

                // 3. カレンダー
                HomeMemoBlueHeader(viewModel: vm, onGoalTap: {
                    showWeeklyGoalSheet = true
                })

                // 4. トレーニング開始 / 続きから再開
                VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                    if vm.incompleteSession != nil {
                        PrimaryButton(title: String(localized: "home_continue_session")) {
                            sessionFlowRequest = SessionFlowRequest(draft: draftForSessionFlow())
                        }
                        .accessibilityHint(String(localized: "home_continue_session_a11y_hint"))
                    } else {
                        PrimaryButton(
                            title: String(localized: "home_cta_add_today_workout")
                        ) {
                            showWorkoutStart = true
                        }
                    }
                }
                .padding(.horizontal, horizontalPadding)

                // 5. 本日のログ + 直近の実績
                VStack(alignment: .leading, spacing: AppTheme.memoSectionGap) {
                    HomeMemoDayLogSection(
                        sessions: vm.todaySessions,
                        weightUnit: weightUnit,
                        sectionTitle: "本日のトレーニング"
                    )

                    if !vm.recentDisplayItems.isEmpty {
                        VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                            SectionHeaderView(title: String(localized: "home_recent_sessions_section"))
                            VStack(spacing: AppTheme.spacingSM) {
                                ForEach(vm.recentDisplayItems) { item in
                                    NavigationLink(value: item.sessionId) {
                                        RecentSessionCardView(item: item)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            Button {
                                UserDefaults.standard.set(1, forKey: AppDeepLinkHandler.mainTabIndexStorageKey)
                            } label: {
                                HStack {
                                    Text(String(localized: "home_open_full_history"))
                                        .font(AppTheme.captionTypographyFont.weight(.medium))
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                }
                                .foregroundStyle(AppTheme.accent)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, horizontalPadding)

                if !premium.isPremium {
                    HomeNativeAdCard()
                        .padding(.horizontal, horizontalPadding)
                        .padding(.top, AppTheme.spacingSM)
                }
            }
            .padding(.top, AppTheme.spacingMD)
            .padding(.bottom, AppTheme.spacingXL)
        }
    }

    private func createViewModelAndLoadIfNeeded() {
        if viewModel == nil {
            let vm = HomeViewModel(
                workoutRepository: WorkoutRepository(modelContext: modelContext),
                templateRepository: TemplateRepository(modelContext: modelContext),
                statsService: WorkoutStatsService(modelContext: modelContext),
                modelContext: modelContext
            )
            viewModel = vm
            vm.loadRecentSessions()
        } else {
            viewModel?.loadRecentSessions()
        }
        if openWorkoutAfterOnboarding {
            sessionFlowRequest = SessionFlowRequest(draft: draftForSessionFlow())
            openWorkoutAfterOnboarding = false
        }
    }

    /// 同一日は1セッションにまとめる（未完了優先 → 当日完了済みを再開して追記）。
    private func draftForSessionFlow(base: WorkoutSessionDraft = WorkoutSessionDraft()) -> WorkoutSessionDraft {
        let repo = WorkoutRepository(modelContext: modelContext)
        do {
            return try repo.resolveDraftForStartingWorkoutToday(base: base)
        } catch {
            return base
        }
    }

}

private func retentionHintCard(title: String, message: String, systemImage: String) -> some View {
    HStack(alignment: .top, spacing: AppTheme.spacingSM) {
        Image(systemName: systemImage)
            .font(.body.weight(.semibold))
            .foregroundStyle(AppTheme.accent)
            .frame(width: 20, height: 20)
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(AppTheme.captionTypographyFont.weight(.semibold))
                .foregroundStyle(AppTheme.primaryText)
            Text(message)
                .font(AppTheme.captionTypographyFont)
                .foregroundStyle(AppTheme.secondaryText)
                .lineLimit(3)
                .minimumScaleFactor(0.9)
        }
        Spacer(minLength: 0)
    }
    .padding(.horizontal, AppTheme.spacingMD)
    .padding(.vertical, AppTheme.spacingSM)
    .background(AppTheme.memoInputCellFill)
    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
    .overlay(
        RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
            .stroke(AppTheme.cardBorder.opacity(0.65), lineWidth: AppTheme.cardStrokeWidth)
    )
}

#Preview {
    HomeView(openWorkoutAfterOnboarding: .constant(false))
        .modelContainer(for: [WorkoutSession.self, Exercise.self], inMemory: true)
}
