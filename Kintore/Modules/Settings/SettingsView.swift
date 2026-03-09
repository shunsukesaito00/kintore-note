// File: Modules/Settings/SettingsView.swift

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var defaultRestSeconds: Int = 90
    @State private var loaded = false

    var body: some View {
        Form {
            Section {
                Picker("休憩デフォルト", selection: $defaultRestSeconds) {
                    Text("60秒").tag(60)
                    Text("90秒").tag(90)
                    Text("120秒").tag(120)
                    Text("180秒").tag(180)
                }
            } header: {
                Text("記録")
            }
            Section {
                HStack {
                    Text("アプリ名")
                    Spacer()
                    Text("RepLog")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("About")
            }
        }
        .navigationTitle("設定")
        .onAppear {
            if !loaded {
                loadPreference()
                loaded = true
            }
        }
        .onChange(of: defaultRestSeconds) { _, newValue in
            saveRestSeconds(newValue)
        }
    }

    private func loadPreference() {
        guard let pref = try? SettingsRepository(modelContext: modelContext).fetchUserPreference() else { return }
        defaultRestSeconds = pref.defaultRestSeconds
    }

    private func saveRestSeconds(_ seconds: Int) {
        try? SettingsRepository(modelContext: modelContext).updateDefaultRestSeconds(seconds)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(for: [UserPreference.self], inMemory: true)
}
