// File: Modules/Settings/SettingsView.swift
// T4-2: 休憩デフォルト・About・種目/ルーティンへの導線・テーマ切替

import SwiftUI
import SwiftData
import UIKit
import UserNotifications

private struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}

private let requestedReviewAfterPremiumKey = "kintore.requestedReviewAfterPremium"

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.requestReview) private var requestReview
    @Environment(\.openURL) private var openURL
    @State private var defaultRestSeconds: Int = 90
    @State private var weightUnit: String = "kg"
    @State private var themeRaw: String = "system"
    @State private var weeklyWorkoutGoalSessions: Int = 0
    @State private var loaded = false
    @State private var sessionCount: Int = 0
    @State private var setCount: Int = 0
    @State private var exportFileURL: URL?
    @State private var showWorkoutRangeExportSheet = false
    @AppStorage(AppTheme.appThemeStorageKey) private var appTheme: String = "system"
    @AppStorage(AppTheme.autoStartRestOnSetCompleteKey) private var autoStartRestOnSetComplete = true
    @AppStorage(HealthKitSettings.saveWorkoutsKey) private var saveWorkoutsToHealth = false
    private let premium = PremiumService.shared
    @State private var healthKitFooterTick = 0
    @State private var reengagementOn = RetentionNotificationService.isReengagementEnabled
    @State private var weeklySummaryOn = RetentionNotificationService.isWeeklySummaryEnabled
    @State private var notificationAuthStatus: UNAuthorizationStatus = .notDetermined
    @State private var suppressNotificationToggleHandlers = false

    var body: some View {
        Form {
            Section {
                if premium.isPremium {
                    Label(String(localized: "settings_premium_active"), systemImage: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.accent)
                } else {
                    if let product = premium.product {
                        Text(product.displayPrice)
                            .font(AppTheme.title3Font)
                        Button {
                            Task {
                                await premium.purchase()
                                if premium.isPremium,
                                   !UserDefaults.standard.bool(forKey: requestedReviewAfterPremiumKey) {
                                    UserDefaults.standard.set(true, forKey: requestedReviewAfterPremiumKey)
                                    requestReview()
                                }
                            }
                        } label: {
                            if premium.isPurchasing {
                                ProgressView()
                            } else {
                                Text(String(localized: "settings_purchase_premium"))
                            }
                        }
                        .disabled(premium.isPurchasing)
                    }
                    Button(String(localized: "settings_restore_purchase")) {
                        Task { await premium.restore() }
                    }
                }
                if let msg = premium.errorMessage {
                    Text(msg)
                        .font(AppTheme.captionTypographyFont)
                        .foregroundStyle(AppTheme.destructive)
                }
            } header: {
                Text(String(localized: "settings_section_premium"))
            } footer: {
                Text(String(localized: "settings_premium_footer_ads_only"))
                    .font(AppTheme.captionTypographyFont)
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Section {
                Picker(String(localized: "settings_rest_default"), selection: $defaultRestSeconds) {
                    Text(String(localized: "settings_rest_60s")).tag(60)
                    Text(String(localized: "settings_rest_90s")).tag(90)
                    Text(String(localized: "settings_rest_120s")).tag(120)
                    Text(String(localized: "settings_rest_180s")).tag(180)
                }
                Toggle(String(localized: "settings_auto_start_rest"), isOn: $autoStartRestOnSetComplete)
                Picker(String(localized: "settings_picker_weight_unit"), selection: $weightUnit) {
                    Text(String(localized: "weight_unit_symbol_kg")).tag("kg")
                    Text(String(localized: "weight_unit_symbol_lb")).tag("lb")
                }
                .onChange(of: weightUnit) { _, newValue in
                    saveWeightUnit(newValue)
                }
                Toggle(
                    String(localized: "settings_weekly_workout_goal"),
                    isOn: Binding(
                        get: { weeklyWorkoutGoalSessions > 0 },
                        set: { enabled in
                            let newValue = enabled ? max(weeklyWorkoutGoalSessions, 7) : 0
                            weeklyWorkoutGoalSessions = newValue
                            saveWeeklyWorkoutGoal(newValue)
                        }
                    )
                )
                NavigationLink(destination: PlateCalculatorView()) {
                    Label(String(localized: "settings_plate_calculator"), systemImage: "scalemass")
                }
                .accessibilityHint(String(localized: "settings_a11y_plate_calculator_hint"))
                NavigationLink(destination: BodyMetricsView()) {
                    Label(String(localized: "settings_body_metrics"), systemImage: "figure.stand")
                }
                .accessibilityHint(String(localized: "settings_a11y_body_metrics_hint"))
                NavigationLink(destination: MemoJournalView()) {
                    Label(String(localized: "settings_memo_journal"), systemImage: "note.text")
                }
            } header: {
                Text(String(localized: "settings_section_recording"))
            } footer: {
                Text(String(localized: "settings_weekly_workout_goal_footer"))
                    .font(AppTheme.captionTypographyFont)
            }

            Section {
                Toggle(String(localized: "settings_save_workouts_healthkit"), isOn: $saveWorkoutsToHealth)
                    .disabled(!HealthKitWorkoutService.isHealthDataAvailable)
                    .onChange(of: saveWorkoutsToHealth) { _, enabled in
                        if enabled {
                            Task { await HealthKitWorkoutService.shared.requestAuthorizationIfNeeded() }
                        } else {
                            HealthKitSettings.clearLastSaveError()
                            healthKitFooterTick += 1
                        }
                    }
            } header: {
                Text(String(localized: "settings_section_healthkit"))
            } footer: {
                healthKitSectionFooter
            }

            #if os(iOS)
            Section {
                Label(String(localized: "settings_watch_features_intro"), systemImage: "applewatch")
                    .font(AppTheme.bodyTypographyFont)
                    .foregroundStyle(AppTheme.primaryText)
            } header: {
                Text(String(localized: "settings_section_watch"))
            } footer: {
                VStack(alignment: .leading, spacing: 8) {
                    Text(WatchSettingsHelper.footerText)
                    Text(String(localized: "settings_watch_detail_bullets"))
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .font(AppTheme.captionTypographyFont)
            }
            #endif

            Section {
                Toggle(String(localized: "settings_reengagement_reminder"), isOn: $reengagementOn)
                    .accessibilityHint(String(localized: "settings_a11y_reengagement_hint"))
                    .onChange(of: reengagementOn) { _, new in
                        guard !suppressNotificationToggleHandlers else { return }
                        Task { await applyReengagementNotificationToggle(new) }
                    }
                Toggle(String(localized: "settings_weekly_summary"), isOn: $weeklySummaryOn)
                    .accessibilityHint(String(localized: "settings_a11y_weekly_summary_hint"))
                    .onChange(of: weeklySummaryOn) { _, new in
                        guard !suppressNotificationToggleHandlers else { return }
                        Task { await applyWeeklySummaryNotificationToggle(new) }
                    }
                if notificationAuthStatus == .denied {
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            openURL(url)
                        }
                    } label: {
                        Label(String(localized: "settings_notification_open_system_settings"), systemImage: "gear")
                    }
                }
            } header: {
                Text(String(localized: "settings_section_notifications"))
            } footer: {
                notificationSectionFooter
            }

            Section {
                Picker(String(localized: "settings_appearance"), selection: $themeRaw) {
                    Text(String(localized: "settings_theme_system")).tag("system")
                    Text(String(localized: "settings_theme_light")).tag("light")
                    Text(String(localized: "settings_theme_dark")).tag("dark")
                }
                .onChange(of: themeRaw) { _, newValue in
                    saveTheme(newValue)
                }
            } header: {
                Text(String(localized: "settings_section_display"))
            }

            Section {
                NavigationLink(destination: ExerciseListView()) {
                    Label(String(localized: "settings_exercise_list"), systemImage: "list.bullet.rectangle")
                }
                .accessibilityLabel(String(localized: "settings_exercise_list"))
                .accessibilityHint(String(localized: "settings_a11y_exercise_list_hint"))
                NavigationLink(destination: RoutineListView()) {
                    Label(String(localized: "settings_routine_management"), systemImage: "square.stack.3d.up")
                }
                .accessibilityLabel(String(localized: "settings_routine_management"))
                .accessibilityHint(String(localized: "settings_a11y_routine_management_hint"))
            } header: {
                Text(String(localized: "settings_section_management"))
            }

            Section {
                Label(String(localized: "settings_icloud_backup"), systemImage: "icloud.fill")
                    .foregroundStyle(AppTheme.accent)
                    .accessibilityLabel(String(localized: "settings_icloud_backup"))
                HStack {
                    Text(String(localized: "settings_data_records"))
                    Spacer()
                    Text(String(format: String(localized: "settings_data_record_summary"), sessionCount, setCount))
                        .foregroundStyle(.secondary)
                }
                Button {
                    exportToCSV()
                } label: {
                    Label(String(localized: "settings_csv_export_all"), systemImage: "square.and.arrow.up")
                }
                Button {
                    showWorkoutRangeExportSheet = true
                } label: {
                    Label(String(localized: "settings_csv_export_range"), systemImage: "calendar.badge.clock")
                }
            } header: {
                Text(String(localized: "settings_section_data"))
            } footer: {
                dataSectionFooter
            }

            Section {
                HStack {
                    Text(String(localized: "settings_about_app_name"))
                    Spacer()
                    Text(String(localized: "app_display_name"))
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text(String(localized: "settings_about_version"))
                    Spacer()
                    Text(appVersion)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text(String(localized: "settings_about_section_title"))
            }
        }
        .scrollContentBackground(.hidden)
        .tint(AppTheme.accent)
        .appTabRootChrome()
        .navigationTitle(String(localized: "nav_settings_title"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if !loaded {
                loadPreference()
                loaded = true
            } else {
                refreshDataCount()
            }
            syncNotificationToggleStatesFromService()
            Task {
                await refreshNotificationAuthorizationStatus()
                await premium.loadProduct()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            syncNotificationToggleStatesFromService()
            Task { await refreshNotificationAuthorizationStatus() }
        }
        .onChange(of: defaultRestSeconds) { _, newValue in
            saveRestSeconds(newValue)
        }
        .sheet(item: Binding(get: { exportFileURL.map { IdentifiableURL(url: $0) } }, set: { exportFileURL = $0?.url })) { identifiable in
            ShareSheet(activityItems: [identifiable.url], onDismiss: { exportFileURL = nil })
        }
        .sheet(isPresented: $showWorkoutRangeExportSheet) {
            CSVWorkoutRangeExportSheet(weightUnit: weightUnit) { url in
                exportFileURL = url
            }
            .environment(\.modelContext, modelContext)
            .standardSheetChrome()
        }
    }

    private var appVersion: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0.0"
    }

    @ViewBuilder
    private var healthKitSectionFooter: some View {
        let _ = healthKitFooterTick
        VStack(alignment: .leading, spacing: 8) {
            if HealthKitWorkoutService.isHealthDataAvailable {
                Text(String(localized: "settings_healthkit_footer_available"))
            } else {
                Text(String(localized: "settings_healthkit_footer_unavailable"))
            }
            if saveWorkoutsToHealth, let err = HealthKitSettings.lastSaveErrorMessage, !err.isEmpty {
                Text(err)
                    .foregroundStyle(AppTheme.destructive)
                Button(String(localized: "settings_healthkit_clear_error")) {
                    HealthKitSettings.clearLastSaveError()
                    healthKitFooterTick += 1
                }
                .font(AppTheme.captionTypographyFont)
            }
        }
        .font(AppTheme.captionTypographyFont)
    }

    @ViewBuilder
    private var notificationSectionFooter: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(notificationAuthorizationStatusText)
            Text(String(localized: "settings_notifications_footer"))
                .foregroundStyle(AppTheme.secondaryText)
            Text(String(localized: "settings_notification_footer"))
                .foregroundStyle(AppTheme.secondaryText)
        }
        .font(AppTheme.captionTypographyFont)
    }

    private var notificationAuthorizationStatusText: String {
        switch notificationAuthStatus {
        case .authorized:
            return String(localized: "settings_notification_auth_status_authorized")
        case .denied:
            return String(localized: "settings_notification_auth_status_denied")
        case .notDetermined:
            return String(localized: "settings_notification_auth_status_not_determined")
        case .provisional:
            return String(localized: "settings_notification_auth_status_provisional")
        case .ephemeral:
            return String(localized: "settings_notification_auth_status_ephemeral")
        @unknown default:
            return String(localized: "settings_notification_auth_status_not_determined")
        }
    }

    private func syncNotificationToggleStatesFromService() {
        suppressNotificationToggleHandlers = true
        reengagementOn = RetentionNotificationService.isReengagementEnabled
        weeklySummaryOn = RetentionNotificationService.isWeeklySummaryEnabled
        suppressNotificationToggleHandlers = false
    }

    @MainActor
    private func refreshNotificationAuthorizationStatus() async {
        notificationAuthStatus = await RetentionNotificationService.currentAuthorizationStatus()
    }

    @MainActor
    private func applyReengagementNotificationToggle(_ newValue: Bool) async {
        if newValue {
            let status = await RetentionNotificationService.currentAuthorizationStatus()
            switch status {
            case .authorized, .provisional, .ephemeral:
                RetentionNotificationService.isReengagementEnabled = true
            case .denied:
                reengagementOn = false
                RetentionNotificationService.isReengagementEnabled = false
            case .notDetermined:
                let granted = await RetentionNotificationService.requestAuthorizationForAlerts()
                await refreshNotificationAuthorizationStatus()
                if granted {
                    RetentionNotificationService.isReengagementEnabled = true
                } else {
                    reengagementOn = false
                    RetentionNotificationService.isReengagementEnabled = false
                }
            @unknown default:
                reengagementOn = false
                RetentionNotificationService.isReengagementEnabled = false
            }
        } else {
            RetentionNotificationService.isReengagementEnabled = false
            RetentionNotificationService.cancelReengagementPending()
        }
        await refreshNotificationAuthorizationStatus()
    }

    @MainActor
    private func applyWeeklySummaryNotificationToggle(_ newValue: Bool) async {
        if newValue {
            let status = await RetentionNotificationService.currentAuthorizationStatus()
            switch status {
            case .authorized, .provisional, .ephemeral:
                RetentionNotificationService.isWeeklySummaryEnabled = true
                RetentionNotificationService.syncWeeklySummarySchedule(modelContext: modelContext)
            case .denied:
                weeklySummaryOn = false
                RetentionNotificationService.isWeeklySummaryEnabled = false
            case .notDetermined:
                let granted = await RetentionNotificationService.requestAuthorizationForAlerts()
                await refreshNotificationAuthorizationStatus()
                if granted {
                    RetentionNotificationService.isWeeklySummaryEnabled = true
                    RetentionNotificationService.syncWeeklySummarySchedule(modelContext: modelContext)
                } else {
                    weeklySummaryOn = false
                    RetentionNotificationService.isWeeklySummaryEnabled = false
                }
            @unknown default:
                weeklySummaryOn = false
                RetentionNotificationService.isWeeklySummaryEnabled = false
            }
        } else {
            RetentionNotificationService.isWeeklySummaryEnabled = false
            RetentionNotificationService.syncWeeklySummarySchedule(modelContext: modelContext)
        }
        await refreshNotificationAuthorizationStatus()
    }

    @ViewBuilder
    private var dataSectionFooter: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "settings_data_footer_offline_core"))
            if PremiumService.isCloudSyncRestartPending {
                Text(String(localized: "settings_icloud_restart_notice"))
                    .foregroundStyle(AppTheme.accent)
            }
            Text(String(localized: "settings_data_footer_export_info"))
            Text(String(localized: "settings_data_footer_icloud_sync"))
                .foregroundStyle(AppTheme.secondaryText)
            Text(String(localized: "settings_data_footer_icloud_first_sync"))
                .foregroundStyle(AppTheme.secondaryText)
            Text(String(localized: "settings_data_footer_icloud_network"))
                .foregroundStyle(AppTheme.secondaryText)
            Text(String(localized: "settings_data_footer_conflict"))
                .foregroundStyle(AppTheme.secondaryText)
        }
        .font(AppTheme.captionTypographyFont)
    }

    private func loadPreference() {
        let repo = SettingsRepository(modelContext: modelContext)
        try? repo.createDefaultIfNeeded()
        guard let pref = try? repo.fetchUserPreference() else { return }
        defaultRestSeconds = pref.defaultRestSeconds
        weightUnit = pref.weightUnit
        themeRaw = pref.theme
        weeklyWorkoutGoalSessions = pref.weeklyWorkoutGoalSessions
        if appTheme != pref.theme {
            appTheme = pref.theme
        }
        UserDefaults.standard.set(pref.weightUnit, forKey: AppTheme.weightUnitStorageKey)
        refreshDataCount()
    }

    private func refreshDataCount() {
        let workoutRepo = WorkoutRepository(modelContext: modelContext)
        sessionCount = (try? workoutRepo.countCompletedSessions()) ?? 0
        setCount = (try? workoutRepo.countSetsInCompletedSessions()) ?? 0
    }

    private func exportToCSV() {
        guard let csv = try? ExportService.buildSessionsCSV(modelContext: modelContext, weightUnit: weightUnit),
              let url = ExportService.writeExportToTempFile(csv: csv) else { return }
        AnalyticsEventService.log(.csvExported(kind: "workout_all"))
        exportFileURL = url
    }

    private func saveRestSeconds(_ seconds: Int) {
        try? SettingsRepository(modelContext: modelContext).updateDefaultRestSeconds(seconds)
    }

    private func saveTheme(_ theme: String) {
        appTheme = theme
        try? SettingsRepository(modelContext: modelContext).updateTheme(theme)
    }

    private func saveWeightUnit(_ unit: String) {
        try? SettingsRepository(modelContext: modelContext).updateWeightUnit(unit)
        UserDefaults.standard.set(unit, forKey: AppTheme.weightUnitStorageKey)
    }

    private func saveWeeklyWorkoutGoal(_ count: Int) {
        try? SettingsRepository(modelContext: modelContext).updateWeeklyWorkoutGoalSessions(count)
    }
}

// MARK: - CSV Export (Range)

private struct CSVWorkoutRangeExportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let weightUnit: String
    let onExported: (URL) -> Void

    @State private var startDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    @State private var endDate = Date()
    @State private var validationMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(String(localized: "settings_export_start_date"), selection: $startDate, displayedComponents: .date)
                    DatePicker(String(localized: "settings_export_end_date"), selection: $endDate, displayedComponents: .date)
                } footer: {
                    Text(String(localized: "settings_export_range_footer"))
                        .font(AppTheme.captionTypographyFont)
                }
                if let validationMessage {
                    Section {
                        Text(validationMessage)
                            .font(AppTheme.captionTypographyFont)
                            .foregroundStyle(AppTheme.destructive)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.appBackground)
            .navigationTitle(String(localized: "settings_export_specify_range"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.appBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "settings_cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "settings_export")) { runExport() }
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.accent)
                }
            }
        }
    }

    private func runExport() {
        validationMessage = nil
        guard let range = ExportService.sessionExportRange(from: startDate, to: endDate) else {
            validationMessage = String(localized: "settings_export_validation_date_order")
            return
        }
        guard let csv = try? ExportService.buildSessionsCSV(
            modelContext: modelContext,
            weightUnit: weightUnit,
            from: range.start,
            to: range.end
        ),
            let url = ExportService.writeRangedSessionsExportToTempFile(csv: csv) else {
            validationMessage = String(localized: "settings_export_csv_failed")
            return
        }
        AnalyticsEventService.log(.csvExported(kind: "workout_range"))
        onExported(url)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(for: [UserPreference.self], inMemory: true)
}
