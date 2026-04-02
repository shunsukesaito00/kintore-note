// File: App/MainTabView.swift
// シェル: タブバー見た目を AppTheme と一致（記録フローは各画面で個別にナビを上書き）

import SwiftUI
import SwiftData
import UIKit

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var openWorkoutAfterOnboarding: Bool
    @AppStorage(AppDeepLinkHandler.mainTabIndexStorageKey) private var selectedTabIndex = 0

    init(openWorkoutAfterOnboarding: Binding<Bool>) {
        _openWorkoutAfterOnboarding = openWorkoutAfterOnboarding
        let tabBar = UITabBarAppearance()
        tabBar.configureWithDefaultBackground()
        tabBar.backgroundColor = AppTheme.tabBarBackgroundUIColor
        let item = UITabBarItemAppearance()
        let normal = UIColor.secondaryLabel
        let selected = AppTheme.accentUIColor
        item.normal.iconColor = normal
        item.normal.titleTextAttributes = [.foregroundColor: normal]
        item.selected.iconColor = selected
        item.selected.titleTextAttributes = [.foregroundColor: selected]
        tabBar.stackedLayoutAppearance = item
        tabBar.inlineLayoutAppearance = item
        tabBar.compactInlineLayoutAppearance = item
        UITabBar.appearance().standardAppearance = tabBar
        UITabBar.appearance().scrollEdgeAppearance = tabBar
    }

    var body: some View {
        TabView(selection: $selectedTabIndex) {
            NavigationStack {
                HomeView(openWorkoutAfterOnboarding: $openWorkoutAfterOnboarding)
                    .navigationDestination(for: UUID.self) { sessionId in
                        SessionDetailView(sessionId: sessionId)
                    }
                    .navigationDestination(for: ExerciseNavTarget.self) { target in
                        ExerciseDetailView(exerciseId: target.id, exerciseName: target.name)
                    }
            }
            .tabItem {
                Label(String(localized: "tab_home"), systemImage: "house")
            }
            .tag(0)
            .accessibilityLabel(String(localized: "tab_home"))
            .accessibilityHint(String(localized: "tab_home_a11y_hint"))
            NavigationStack {
                HistoryListView()
                    .navigationDestination(for: UUID.self) { sessionId in
                        SessionDetailView(sessionId: sessionId)
                    }
                    .navigationDestination(for: ExerciseNavTarget.self) { target in
                        ExerciseDetailView(exerciseId: target.id, exerciseName: target.name)
                    }
            }
            .tabItem {
                Label(String(localized: "tab_history"), systemImage: "list.bullet.clipboard")
            }
            .tag(1)
            .accessibilityLabel(String(localized: "tab_history"))
            .accessibilityHint(String(localized: "tab_history_a11y_hint"))
            NavigationStack {
                GrowthDashboardView()
                    .navigationDestination(for: ExerciseNavLinkTarget.self) { target in
                        ExerciseDetailView(exerciseId: target.id, exerciseName: target.name)
                    }
            }
            .tabItem {
                Label(String(localized: "tab_statistics"), systemImage: "chart.line.uptrend.xyaxis")
            }
            .tag(2)
            .accessibilityLabel(String(localized: "tab_statistics"))
            .accessibilityHint(String(localized: "tab_statistics_a11y_hint"))
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label(String(localized: "tab_settings"), systemImage: "gearshape")
            }
            .tag(3)
            .accessibilityLabel(String(localized: "tab_settings"))
            .accessibilityHint(String(localized: "tab_settings_a11y_hint"))
        }
        .animation(AppTheme.animationTabTransition(reduceMotion: reduceMotion), value: selectedTabIndex)
        .tint(AppTheme.accent)
        .toolbarBackground(AppTheme.tabBarChromeBackground, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}

#Preview {
    MainTabView(openWorkoutAfterOnboarding: .constant(false))
        .modelContainer(for: [WorkoutSession.self, Exercise.self, WorkoutExercise.self, WorkoutSet.self], inMemory: true)
}
