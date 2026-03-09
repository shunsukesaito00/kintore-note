// File: Modules/Workout/WorkoutStartView.swift

import SwiftUI
import SwiftData

struct WorkoutStartView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let onDismiss: () -> Void

    @State private var viewModel: WorkoutStartViewModel?
    @State private var showRecord = false
    @State private var draftToStart: WorkoutSessionDraft?

    var body: some View {
        let vm = viewModel ?? WorkoutStartViewModel(templateRepository: TemplateRepository(modelContext: modelContext))
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    PrimaryButton(title: "新規で開始") {
                        draftToStart = vm.makeDraftForNew()
                        showRecord = true
                    }
                    .onAppear { if viewModel == nil { viewModel = vm; vm.loadTemplates() } }

                    if !vm.templates.isEmpty {
                        Text("ルーティンから開始")
                            .font(.headline)
                        ForEach(vm.templates, id: \.id) { template in
                            Button {
                                draftToStart = vm.makeDraft(from: template)
                                showRecord = true
                            } label: {
                                SectionCard {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(template.name)
                                            .font(.subheadline)
                                        Text("\(template.items.count)種目")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("ワークアウト開始")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                        onDismiss()
                    }
                }
            }
            .fullScreenCover(isPresented: $showRecord) {
                if let draft = draftToStart {
                    WorkoutRecordView(
                        draft: draft,
                        onDismiss: {
                            showRecord = false
                            draftToStart = nil
                            dismiss()
                            onDismiss()
                        }
                    )
                    .environment(\.modelContext, modelContext)
                }
            }
        }
    }
}

#Preview {
    WorkoutStartView(onDismiss: {})
        .modelContainer(for: [WorkoutTemplate.self, WorkoutTemplateItem.self, Exercise.self], inMemory: true)
}
