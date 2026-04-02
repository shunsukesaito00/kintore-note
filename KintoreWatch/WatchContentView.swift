// File: KintoreWatch/WatchContentView.swift
// 最小版: 休憩タイマー表示（iPhone から WatchConnectivity で受信）、終了時 Haptic、メッセージ。

import SwiftUI
import WatchKit

struct WatchContentView: View {
    private let sessionManager = WatchSessionManager.shared
    @State private var previousRestSeconds: Int = 0

    var body: some View {
        Group {
            if sessionManager.restRemainingSeconds > 0 {
                WatchRestTimerView(
                    remainingSeconds: sessionManager.restRemainingSeconds,
                    exerciseName: sessionManager.currentExerciseName
                )
                .onChange(of: sessionManager.restRemainingSeconds) { _, newValue in
                    if previousRestSeconds > 0 && newValue == 0 {
                        WKInterfaceDevice.current().play(.notification)
                    }
                    previousRestSeconds = newValue
                }
                .onAppear { previousRestSeconds = sessionManager.restRemainingSeconds }
            } else if !sessionManager.isPremium {
                VStack(spacing: 6) {
                    Text(String(localized: "watch_idle_app_title", bundle: .main))
                        .font(.headline)
                    Text(String(localized: "watch_idle_non_premium_body", bundle: .main))
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
            } else {
                WatchSessionView(lastPrText: sessionManager.lastPrText)
            }
        }
        .tint(WatchBrandColors.accent)
    }
}

#Preview {
    WatchContentView()
}
