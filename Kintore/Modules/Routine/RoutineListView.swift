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
            if let error = loadError {
                Section {
                    HStack(spacing: AppTheme.spacingSM) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(AppTheme.destructive)
                        Text(error)
                            .font(AppTheme.captionTypographyFont)
                            .foregroundStyle(AppTheme.destructive)
                        Spacer()
                        Button(String(localized: "common_retry")) { loadTemplates() }
                            .font(AppTheme.captionTypographyFont)
                            .foregroundStyle(AppTheme.accent)
                    }
                }
            }

            if templates.isEmpty && loadError == nil {
                Section {
                    VStack(spacing: AppTheme.spacingMD) {
                        Image(systemName: "list.clipboard")
                            .font(.largeTitle)
                            .foregroundStyle(AppTheme.tertiaryText)
                        Text(String(localized: "routine_empty_title"))
                            .font(AppTheme.bodyTypographyFont)
                            .foregroundStyle(AppTheme.secondaryText)
                        Text(String(localized: "routine_empty_hint"))
                            .font(AppTheme.captionTypographyFont)
                            .foregroundStyle(AppTheme.tertiaryText)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.spacingXL)
                }
            } else {
                Section {
                    ForEach(templates, id: \.id) { template in
                        Button {
                            showEdit = template
                        } label: {
                            HStack(spacing: AppTheme.spacingMD) {
                                VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
                                    Text(template.name)
                                        .font(AppTheme.cardTitleFont)
                                        .foregroundStyle(AppTheme.primaryText)
                                    Text(String(format: String(localized: "routine_exercise_count_format"), template.items.count))
                                        .font(AppTheme.captionTypographyFont)
                                        .foregroundStyle(AppTheme.secondaryText)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                            .padding(.vertical, AppTheme.spacingXS)
                        }
                    }
                    .onDelete(perform: deleteTemplates)
                } header: {
                    SectionHeaderView(title: String(localized: "routine_section_header"))
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .tint(AppTheme.accent)
        .appTabRootChrome()
        .navigationTitle(String(localized: "nav_routine_management"))
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(String(localized: "common_new")) {
                    showNewRoutine = true
                }
                .fontWeight(.medium)
            }
        }
        .onAppear { loadTemplates() }
        .sheet(item: $showEdit) { template in
            RoutineEditView(template: template, onDismiss: {
                showEdit = nil
                loadTemplates()
            })
            .environment(\.modelContext, modelContext)
            .standardSheetChrome()
        }
        .sheet(isPresented: $showNewRoutine) {
            RoutineEditView(template: nil, onDismiss: {
                showNewRoutine = false
                loadTemplates()
            })
            .environment(\.modelContext, modelContext)
            .standardSheetChrome()
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
