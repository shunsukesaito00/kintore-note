// 休憩タイマー表示（iPhone から WatchConnectivity で受信）、終了時 Haptic

import SwiftUI
import WatchKit

struct WatchRestTimerView: View {
    let remainingSeconds: Int
    let exerciseName: String?

    var body: some View {
        VStack(spacing: 8) {
            Text(String(localized: "watch_rest_title", bundle: .main))
                .font(.caption)
            Text(formatRest(remainingSeconds))
                .font(.title2.monospacedDigit())
                .fontWeight(.semibold)
            if let name = exerciseName, !name.isEmpty {
                Text(name)
                    .font(.caption2)
                    .lineLimit(1)
            }
        }
    }

    private func formatRest(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
