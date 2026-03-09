// File: Modules/Routine/RoutineListView.swift

import SwiftUI
import SwiftData

struct RoutineListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var templates: [WorkoutTemplate] = []
    @State private var showEdit: WorkoutTemplate?
    @State private var showNewRoutine = false
    @State private var loadError: String?

    var body: some View {
        List {
            Section {
                ForEach(templates, id: \.id) { template in
                    Button {
                        showEdit = template
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(template.name)
                                    .font(.headline)
                                Text("\(template.items.count)種目")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .onDelete(perform: deleteTemplates)
            } header: {
                Text("ルーティン")
            }
        }
        .navigationTitle("ルーティン管理")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("新規") {
                    showNewRoutine = true
                }
            }
        }
        .onAppear { loadTemplates() }
        .sheet(item: $showEdit) { template in
            RoutineEditView(template: template, onDismiss: {
                showEdit = nil
                loadTemplates()
            })
            .environment(\.modelContext, modelContext)
        }
        .sheet(isPresented: $showNewRoutine) {
            RoutineEditView(template: nil, onDismiss: {
                showNewRoutine = false
                loadTemplates()
            })
            .environment(\.modelContext, modelContext)
        }
    }

    private func loadTemplates() {
        do {
            templates = try TemplateRepository(modelContext: modelContext).fetchAllTemplates()
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func deleteTemplates(at offsets: IndexSet) {
        for index in offsets {
            guard index < templates.count else { continue }
            let t = templates[index]
            try? TemplateRepository(modelContext: modelContext).deleteTemplate(t)
        }
        templates.remove(atOffsets: offsets)
    }
}

extension WorkoutTemplate: Identifiable {}

#Preview {
    NavigationStack {
        RoutineListView()
    }
    .modelContainer(for: [WorkoutTemplate.self, WorkoutTemplateItem.self, Exercise.self], inMemory: true)
}
