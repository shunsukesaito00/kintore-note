// File: Modules/Routine/RoutineEditView.swift

import SwiftUI
import SwiftData

struct RoutineEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let template: WorkoutTemplate?
    let onDismiss: () -> Void

    @State private var name: String = ""
    @State private var items: [WorkoutTemplateItem] = []
    @State private var pendingExercises: [Exercise] = []
    @State private var showExercisePicker = false
    @State private var saveError: String?

    private var templateRepository: TemplateRepository { TemplateRepository(modelContext: modelContext) }

    var body: some View {
        NavigationStack {
            List {
                Section("名前") {
                    TextField("ルーティン名", text: $name)
                }
                Section("種目") {
                    if let _ = template {
                        ForEach(items.sorted(by: { $0.orderIndex < $1.orderIndex }), id: \.id) { item in
                            Text(item.exercise?.name ?? "—")
                        }
                        .onDelete(perform: deleteItems)
                        .onMove(perform: moveItems)
                    } else {
                        ForEach(pendingExercises, id: \.id) { ex in
                            Text(ex.name)
                        }
                        .onDelete(perform: deletePending)
                        .onMove(perform: movePending)
                    }
                    Button("種目を追加") {
                        showExercisePicker = true
                    }
                }
            }
            .navigationTitle(template == nil ? "新規ルーティン" : "ルーティン編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                        onDismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        save()
                    }
                    .disabled(
                        name.trimmingCharacters(in: .whitespaces).isEmpty
                        || (template == nil && pendingExercises.isEmpty)
                    )
                }
            }
            .onAppear {
                if let t = template {
                    name = t.name
                    items = Array(t.items)
                } else {
                    name = "新規ルーティン"
                    pendingExercises = []
                }
            }
            .sheet(isPresented: $showExercisePicker) {
                ExercisePickerView { exercise in
                    addExercise(exercise)
                    showExercisePicker = false
                }
                .environment(\.modelContext, modelContext)
            }
        }
    }

    private func addExercise(_ exercise: Exercise) {
        if let t = template {
            let order = items.count
            try? templateRepository.addItem(to: t, exercise: exercise, orderIndex: order)
            items = Array(t.items)
        } else {
            pendingExercises.append(exercise)
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        guard let t = template else { return }
        let sorted = items.sorted { $0.orderIndex < $1.orderIndex }
        for index in offsets {
            guard index < sorted.count else { continue }
            try? templateRepository.removeItem(sorted[index])
        }
        items = t.items
    }

    private func moveItems(from source: IndexSet, to destination: Int) {
        guard let t = template else { return }
        var sorted = items.sorted { $0.orderIndex < $1.orderIndex }
        sorted.move(fromOffsets: source, toOffset: destination)
        for (i, item) in sorted.enumerated() {
            item.orderIndex = i
        }
        try? templateRepository.reorderItems(t, orderedItems: sorted)
        items = t.items
    }

    private func deletePending(at offsets: IndexSet) {
        pendingExercises.remove(atOffsets: offsets)
    }

    private func movePending(from source: IndexSet, to destination: Int) {
        pendingExercises.move(fromOffsets: source, toOffset: destination)
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if let t = template {
            t.name = trimmed
            try? templateRepository.updateTemplate(t)
        } else if !pendingExercises.isEmpty {
            let newTemplate = WorkoutTemplate(name: trimmed)
            try? templateRepository.insertTemplate(newTemplate)
            for (i, ex) in pendingExercises.enumerated() {
                try? templateRepository.addItem(to: newTemplate, exercise: ex, orderIndex: i)
            }
        }
        dismiss()
        onDismiss()
    }
}

#Preview {
    RoutineEditView(template: nil, onDismiss: {})
        .modelContainer(for: [WorkoutTemplate.self, WorkoutTemplateItem.self, Exercise.self], inMemory: true)
}
