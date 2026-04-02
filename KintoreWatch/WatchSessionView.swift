// 進行中セッション: 重量・回数を選んで送信して完了、または完了のみ。PR 表示。

import SwiftUI

struct WatchSessionView: View {
    let lastPrText: String?

    @State private var weightKg: Double = 60
    @State private var reps: Int = 10

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                if let prText = lastPrText, !prText.isEmpty {
                    Text(prText)
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
                Text(String(localized: "watch_weight_kg_hint", bundle: .main))
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "watch_weight_label", bundle: .main))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    HStack {
                        Button {
                            weightKg = max(0.5, weightKg - 2.5)
                        } label: {
                            Text("−2.5")
                                .font(.caption2)
                        }
                        .buttonStyle(.bordered)
                        Button {
                            weightKg = max(0.5, weightKg - 0.5)
                        } label: {
                            Text("−0.5")
                                .font(.caption2)
                        }
                        .buttonStyle(.bordered)
                        Spacer(minLength: 4)
                        Text(String(format: "%.1f", weightKg))
                            .font(.title3.monospacedDigit())
                            .frame(minWidth: 44)
                        Spacer(minLength: 4)
                        Button {
                            weightKg = min(300, weightKg + 0.5)
                        } label: {
                            Text("+0.5")
                                .font(.caption2)
                        }
                        .buttonStyle(.bordered)
                        Button {
                            weightKg = min(300, weightKg + 2.5)
                        } label: {
                            Text("+2.5")
                                .font(.caption2)
                        }
                        .buttonStyle(.bordered)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "watch_reps_label", bundle: .main))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    HStack {
                        Button {
                            reps = max(1, reps - 1)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                        }
                        .buttonStyle(.borderless)
                        Text("\(reps)")
                            .font(.title3.monospacedDigit())
                            .frame(minWidth: 36)
                        Button {
                            reps = min(100, reps + 1)
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                        .buttonStyle(.borderless)
                    }
                }

                Button {
                    WatchSessionManager.shared.sendWeightRepsComplete(weightKg: weightKg, reps: reps)
                } label: {
                    Text(String(localized: "watch_send_and_complete", bundle: .main))
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)

                Button {
                    WatchSessionManager.shared.sendSetComplete()
                } label: {
                    Text(String(localized: "watch_complete_without_input", bundle: .main))
                        .font(.caption2)
                }
                .buttonStyle(.bordered)

                Text(String(localized: "watch_iphone_session_hint", bundle: .main))
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)
        }
    }
}
