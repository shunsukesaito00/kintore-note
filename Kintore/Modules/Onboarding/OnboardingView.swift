// File: Modules/Onboarding/OnboardingView.swift
// Phase 10: 3画面オンボーディング（記録体験 → 前回値説明 → 通知許可）

import SwiftUI
import UserNotifications

private let onboardingCompletedKey = "kintore.onboardingCompleted"

struct OnboardingView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var onComplete: () -> Void
    var onStartRecording: (() -> Void)?

    @State private var page: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                page1
                page2
                page3
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            pageIndicator
        }
        .background(AppTheme.appBackground)
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(page == i ? AppTheme.accent : Color(.tertiarySystemFill))
                    .frame(width: 8, height: 8)
                    .animation(AppTheme.animationOnboardingPage(reduceMotion: reduceMotion), value: page)
            }
        }
        .padding(.bottom, 24)
    }

    private var page1: some View {
        VStack(spacing: AppTheme.spacingXL) {
            Spacer()
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 56))
                .foregroundStyle(AppTheme.accent)
            Text(String(localized: "onboarding_p1_title"))
                .font(.title.bold())
            Text(String(localized: "onboarding_p1_body"))
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            VStack(spacing: AppTheme.spacingLG) {
                if let onStart = onStartRecording {
                    Button {
                        HapticHelper.medium()
                        onStart()
                    } label: {
                        Text(String(localized: "onboarding_start_now"))
                            .font(AppTheme.headlineFont)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: AppTheme.touchTargetPrimary)
                            .contentShape(Rectangle())
                            .background(AppTheme.accentGradient)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius))
                    }
                    .buttonStyle(.plain)
                }
                Button {
                    HapticHelper.light()
                    withAnimation(AppTheme.animationOnboardingPage(reduceMotion: reduceMotion)) { page = 1 }
                } label: {
                    Text(String(localized: "onboarding_next"))
                        .font(AppTheme.subheadlineFont.weight(.semibold))
                        .foregroundStyle(AppTheme.accent)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: AppTheme.touchTargetSecondary)
                        .contentShape(Rectangle())
                        .background(AppTheme.accent.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius)
                                .stroke(AppTheme.accent.opacity(0.5), lineWidth: 1.5)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .tag(0)
    }

    private var page2: some View {
        VStack(spacing: AppTheme.spacingXL) {
            Spacer()
            Image(systemName: "arrow.counterclockwise")
                .font(.system(size: 56))
                .foregroundStyle(AppTheme.accent)
            Text(String(localized: "onboarding_p2_title"))
                .font(.title.bold())
            Text(String(localized: "onboarding_p2_body"))
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            Button {
                HapticHelper.light()
                withAnimation(AppTheme.animationOnboardingPage(reduceMotion: reduceMotion)) { page = 2 }
            } label: {
                Text(String(localized: "onboarding_next"))
                    .font(AppTheme.headlineFont)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: AppTheme.touchTargetPrimary)
                    .contentShape(Rectangle())
                    .background(AppTheme.accentGradient)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .tag(1)
    }

    private var page3: some View {
        VStack(spacing: AppTheme.spacingXL) {
            Spacer()
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 56))
                .foregroundStyle(AppTheme.accent)
            Text(String(localized: "onboarding_p3_title"))
                .font(.title.bold())
            Text(String(localized: "onboarding_p3_body"))
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            VStack(spacing: AppTheme.spacingLG) {
                Button {
                    HapticHelper.medium()
                    requestNotificationPermission {
                        Task { @MainActor in
                            HapticHelper.success()
                            onComplete()
                        }
                    }
                } label: {
                    Text(String(localized: "onboarding_allow"))
                        .font(AppTheme.headlineFont)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: AppTheme.touchTargetPrimary)
                        .contentShape(Rectangle())
                        .background(AppTheme.accentGradient)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius))
                }
                .buttonStyle(.plain)
                Button {
                    HapticHelper.light()
                    onComplete()
                } label: {
                    Text(String(localized: "onboarding_skip"))
                        .font(AppTheme.subheadlineFont.weight(.semibold))
                        .foregroundStyle(AppTheme.accent)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: AppTheme.touchTargetSecondary)
                        .contentShape(Rectangle())
                        .background(AppTheme.accent.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius)
                                .stroke(AppTheme.accent.opacity(0.5), lineWidth: 1.5)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .tag(2)
    }

    private func requestNotificationPermission(completion: @escaping () -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            if granted { AnalyticsEventService.log(.notificationPermissionGranted) }
            DispatchQueue.main.async { completion() }
        }
    }
}

/// オンボーディング完了済みか（UserDefaults）。初回起動判定に使用。
enum OnboardingStore {
    static var isCompleted: Bool {
        get { UserDefaults.standard.bool(forKey: onboardingCompletedKey) }
        set { UserDefaults.standard.set(newValue, forKey: onboardingCompletedKey) }
    }
}

#Preview {
    OnboardingView(onComplete: {}, onStartRecording: {})
}
