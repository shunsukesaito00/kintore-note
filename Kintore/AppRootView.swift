// File: App/AppRootView.swift
// テーマ（常にダーク/ライト/システム）を適用。T4-5

import SwiftUI
import SwiftData

private let onboardingCompletedKey = "kintore.onboardingCompleted"
private let openWorkoutAfterOnboardingKey = "kintore.openWorkoutAfterOnboarding"

struct AppRootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(AppTheme.appThemeStorageKey) private var appTheme: String = "system"
    @AppStorage(onboardingCompletedKey) private var onboardingCompleted: Bool = false
    @AppStorage(openWorkoutAfterOnboardingKey) private var openWorkoutAfterOnboarding: Bool = false
    @AppStorage("kintore.needsRestartForCloudSync") private var needsCloudRestartNotice = false
    @State private var showModelStoreInMemoryAlert = false
    @State private var showCloudKitLocalFallbackAlert = false

    var body: some View {
        Group {
            if onboardingCompleted {
                MainTabView(openWorkoutAfterOnboarding: $openWorkoutAfterOnboarding)
            } else {
                OnboardingView(
                    onComplete: {
                        AnalyticsEventService.log(.onboardingCompleted)
                        onboardingCompleted = true
                    },
                    onStartRecording: {
                        AnalyticsEventService.log(.onboardingCompleted)
                        openWorkoutAfterOnboarding = true
                        onboardingCompleted = true
                    }
                )
            }
        }
        .animation(AppTheme.animationTabTransition(reduceMotion: reduceMotion), value: onboardingCompleted)
        .preferredColorScheme(colorSchemeFrom(appTheme))
        .onAppear {
            if onboardingCompleted { syncThemeFromPreference() }
            if PremiumService.isCloudSyncRestartPending {
                needsCloudRestartNotice = true
            }
            if AppModelBootstrap.usedInMemoryStoreDueToLoadFailure {
                showModelStoreInMemoryAlert = true
            } else if ModelContainerFactory.didFallbackFromCloudKitToLocal {
                showCloudKitLocalFallbackAlert = true
            }
        }
        .alert(String(localized: "model_store_inmemory_title"), isPresented: $showModelStoreInMemoryAlert) {
            Button(String(localized: "common_ok"), role: .cancel) {}
        } message: {
            Text(String(localized: "model_store_inmemory_message"))
        }
        .alert(String(localized: "model_store_cloud_fallback_title"), isPresented: $showCloudKitLocalFallbackAlert) {
            Button(String(localized: "common_ok"), role: .cancel) {}
        } message: {
            Text(String(localized: "model_store_cloud_fallback_message"))
        }
        .alert(String(localized: "icloud_restart_title"), isPresented: $needsCloudRestartNotice) {
            Button(String(localized: "common_ok")) {
                PremiumService.acknowledgeCloudSyncRestartPrompt()
            }
        } message: {
            Text(String(localized: "icloud_restart_message"))
        }
    }

    private func colorSchemeFrom(_ raw: String) -> ColorScheme? {
        switch raw {
        case "dark": return .dark
        case "light": return .light
        default: return nil
        }
    }

    private func syncThemeFromPreference() {
        guard let pref = try? SettingsRepository(modelContext: modelContext).fetchUserPreference() else { return }
        if appTheme != pref.theme {
            appTheme = pref.theme
        }
    }
}

#Preview {
    AppRootView()
        .modelContainer(for: [WorkoutSession.self, Exercise.self], inMemory: true)
}
