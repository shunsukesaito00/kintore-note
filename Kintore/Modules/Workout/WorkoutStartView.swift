// File: Modules/Workout/WorkoutStartView.swift
// ルーティン（常時表示・0件時も追加カード）+ 部位別メニュー（有酸素含む）。新規種目作成後は開始画面に戻る。

import SwiftUI
import SwiftData

private struct BodyPartSheetItem: Identifiable {
    let id: String
    var bodyPart: String { id }
}

struct WorkoutStartView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let initialTemplate: WorkoutTemplate?
    let onDismiss: () -> Void
    var onSessionCompleted: ((UUID) -> Void)? = nil

    @State private var viewModel: WorkoutStartViewModel?
    @State private var draftForSheet: WorkoutSessionDraft?
    @State private var didApplyInitialTemplate = false
    @State private var showExercisePicker = false
    @State private var bodyPartForList: BodyPartSheetItem?
    @State private var showCreateExerciseForBodyPart: String?
    @State private var showNewRoutineSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    startContent(vm: vm)
                } else {
                    ProgressView(String(localized: "home_loading"))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .background(AppTheme.appBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.memoNavBarBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                        onDismiss()
                    } label: {
                        HStack(spacing: AppTheme.spacingXS) {
                            Image(systemName: "chevron.left")
                                .font(AppTheme.bodyTypographyFont.weight(.semibold))
                            Text(AppFormatters.formatNavBarDateToday())
                                .font(AppTheme.bodySecondaryFont.weight(.medium))
                        }
                        .foregroundStyle(AppTheme.memoNavBarForeground)
                    }
                    .accessibilityLabel(String(localized: "workout_start_back_a11y"))
                }
                ToolbarItem(placement: .principal) {
                    Text(String(localized: "workout_nav_select_exercise"))
                        .font(AppTheme.headlineFont)
                        .foregroundStyle(AppTheme.memoNavBarForeground)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        RoutineListView()
                            .environment(\.modelContext, modelContext)
                    } label: {
                        Text(String(localized: "common_edit"))
                            .font(AppTheme.bodyTypographyFont.weight(.medium))
                            .foregroundStyle(AppTheme.memoNavBarForeground)
                    }
                    .accessibilityLabel(String(localized: "common_edit"))
                }
            }
            .fullScreenCover(item: $draftForSheet) { draft in
                WorkoutSessionFlowView(
                    draft: draft,
                    onDismiss: {
                        draftForSheet = nil
                    },
                    onSaveSuccess: { savedId in
                        draftForSheet = nil
                        onSessionCompleted?(savedId)
                    }
                )
                .environment(\.modelContext, modelContext)
            }
            .sheet(isPresented: $showExercisePicker) {
                ExercisePickerView(
                    onSelect: { exercise in
                        guard let vm = viewModel else { return }
                        draftForSheet = vm.makeDraftFromExercise(exercise)
                        showExercisePicker = false
                    },
                    memoSessionStyle: true
                )
                .environment(\.modelContext, modelContext)
                .standardSheetChrome()
            }
            .sheet(item: $bodyPartForList) { item in
                BodyPartExerciseListView(
                    bodyPart: item.bodyPart,
                    exercises: viewModel?.allExercisesForBodyPart(item.bodyPart) ?? [],
                    onSelect: { exercise in
                        guard let vm = viewModel else { return }
                        draftForSheet = vm.makeDraftFromExercise(exercise)
                        bodyPartForList = nil
                    }
                )
                .standardSheetChrome()
            }
            .sheet(isPresented: Binding(
                get: { showCreateExerciseForBodyPart != nil },
                set: { if !$0 { showCreateExerciseForBodyPart = nil } }
            )) {
                CreateExerciseView(initialBodyPart: showCreateExerciseForBodyPart, onSave: { name, bodyPart, equipment, kind in
                    guard let vm = viewModel else { return }
                    try? vm.insertCustomExercise(name: name, bodyPart: bodyPart, equipment: equipment, exerciseKind: kind)
                    showCreateExerciseForBodyPart = nil
                })
                .standardSheetChrome()
            }
            .sheet(isPresented: $showNewRoutineSheet) {
                RoutineEditView(template: nil, onDismiss: {
                    showNewRoutineSheet = false
                    viewModel?.loadTemplates()
                })
                .environment(\.modelContext, modelContext)
                .standardSheetChrome()
            }
        }
        .onAppear { createViewModelAndApplyInitialIfNeeded() }
    }

    @ViewBuilder
    private func startContent(vm: WorkoutStartViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.spacingXL) {
                HStack {
                    Spacer(minLength: 0)
                    Button {
                        HapticHelper.light()
                        showExercisePicker = true
                    } label: {
                        Text(String(localized: "workout_start_add_body_part_exercise"))
                            .font(AppTheme.bodySecondaryFont.weight(.medium))
                            .foregroundStyle(AppTheme.primaryText)
                            .padding(.horizontal, AppTheme.spacingMD)
                            .padding(.vertical, AppTheme.spacingSM)
                            .background(AppTheme.memoRecordSurface)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(AppTheme.accent, lineWidth: AppTheme.cardStrokeWidth * 2)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(localized: "workout_start_add_body_part_exercise"))
                }
                .padding(.horizontal, AppTheme.spacingLG)
                routinesSection(vm: vm)
                bodyPartSections(vm: vm)
            }
            .padding(.horizontal, AppTheme.spacingLG)
            .padding(.top, AppTheme.spacingMD)
            .padding(.bottom, AppTheme.spacingXL)
        }
    }

    private func routinesSection(vm: WorkoutStartViewModel) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
            SectionHeaderView(title: String(localized: "workout_start_routine_section"))
            VStack(spacing: AppTheme.spacingSM) {
                ForEach(vm.recentTemplates, id: \.id) { template in
                    Button {
                        draftForSheet = vm.makeDraft(from: template)
                    } label: {
                        routineCard(template: template)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("ルーティン、\(template.name)")
                }
                addRoutineCard()
                if vm.hasMoreRoutines {
                    NavigationLink {
                        RoutineListView()
                            .environment(\.modelContext, modelContext)
                    } label: {
                        SectionCard {
                            HStack {
                                Text(String(localized: "workout_start_show_more"))
                                    .font(AppTheme.bodyTypographyFont.weight(.medium))
                                    .foregroundStyle(AppTheme.accent)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(AppTheme.captionTypographyFont)
                                    .foregroundStyle(AppTheme.accent)
                            }
                            .frame(minHeight: AppTheme.touchTargetSecondary)
                            .contentShape(Rectangle())
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func routineCard(template: WorkoutTemplate) -> some View {
        SectionCard {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
                    Text(template.name)
                        .font(AppTheme.cardTitleFont)
                        .foregroundStyle(AppTheme.primaryText)
                    Text(routineSubtitle(template))
                        .font(AppTheme.captionTypographyFont)
                        .foregroundStyle(AppTheme.secondaryText)
                }
                Spacer()
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(AppTheme.accent)
            }
            .frame(minHeight: AppTheme.touchTargetSecondary)
            .contentShape(Rectangle())
        }
    }

    private func addRoutineCard() -> some View {
        Button {
            HapticHelper.light()
            showNewRoutineSheet = true
        } label: {
            SectionCard {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(AppTheme.accent)
                    Text(String(localized: "workout_start_add_routine"))
                        .font(AppTheme.bodyTypographyFont.weight(.medium))
                        .foregroundStyle(AppTheme.accent)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(AppTheme.captionTypographyFont)
                        .foregroundStyle(AppTheme.accent)
                }
                .frame(minHeight: AppTheme.touchTargetSecondary)
                .contentShape(Rectangle())
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("新規ルーティンを追加する")
    }

    private func routineSubtitle(_ template: WorkoutTemplate) -> String {
        if let date = template.lastUsedAt {
            return AppFormatters.formatDateWithWeekday(date)
        }
        return "未実施"
    }

    private func bodyPartSections(vm: WorkoutStartViewModel) -> some View {
        ForEach(WorkoutStartViewModel.orderedBodyParts, id: \.self) { bodyPart in
            bodyPartSection(vm: vm, bodyPart: bodyPart)
        }
    }

    private func bodyPartSection(vm: WorkoutStartViewModel, bodyPart: String) -> some View {
        let summary = vm.bodyPartLastTrainingSummary(for: bodyPart) ?? String(localized: "workout_body_part_never")
        let exercises = vm.exercisesForBodyPart(bodyPart)
        return VStack(alignment: .leading, spacing: 0) {
            VStack(spacing: 0) {
                HStack(alignment: .center) {
                    Text("\(bodyPart) - \(summary)")
                        .font(AppTheme.bodySemiboldFont)
                        .foregroundStyle(AppTheme.memoNavBarForeground)
                        .lineLimit(2)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, AppTheme.spacingLG)
                .padding(.vertical, AppTheme.spacingMD)
                .frame(maxWidth: .infinity)
                .background(AppTheme.memoSectionHeaderBackground)

                ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
                    if index > 0 {
                        Divider()
                            .padding(.leading, AppTheme.spacingLG)
                    }
                    Button {
                        draftForSheet = vm.makeDraftFromExercise(exercise)
                    } label: {
                        bodyPartExerciseRow(exercise: exercise)
                    }
                    .buttonStyle(.plain)
                }

                Rectangle()
                    .fill(AppTheme.separator.opacity(0.6))
                    .frame(height: 0.5)
                    .padding(.horizontal, AppTheme.spacingLG)

                HStack(spacing: 0) {
                    Button {
                        HapticHelper.light()
                        showCreateExerciseForBodyPart = bodyPart
                    } label: {
                        HStack(spacing: AppTheme.spacingXS) {
                            Text(String(localized: "workout_start_add_exercise"))
                                .font(AppTheme.bodyTypographyFont.weight(.medium))
                                .foregroundStyle(AppTheme.secondaryText)
                            Spacer()
                        }
                        .padding(.horizontal, AppTheme.spacingLG)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    if vm.hasMoreExercises(for: bodyPart) {
                        Rectangle()
                            .fill(AppTheme.separator.opacity(0.5))
                            .frame(width: 0.5)
                            .frame(maxHeight: .infinity)
                        Button {
                            HapticHelper.light()
                            bodyPartForList = BodyPartSheetItem(id: bodyPart)
                        } label: {
                            HStack {
                                Spacer()
                                Text(String(localized: "workout_start_show_all"))
                                    .font(AppTheme.captionTypographyFont.weight(.medium))
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                            .padding(.horizontal, AppTheme.spacingLG)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(height: AppTheme.touchTargetSecondary)
            }
            .background(AppTheme.memoRecordSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                    .stroke(AppTheme.cardBorder, lineWidth: AppTheme.cardStrokeWidth)
            )
            .appSubtleElevatedShadow()
        }
        .padding(.top, bodyPart == WorkoutStartViewModel.orderedBodyParts.first ? 0 : AppTheme.spacingMD)
    }

    private func bodyPartExerciseRow(exercise: Exercise) -> some View {
        HStack(spacing: AppTheme.spacingMD) {
            Text(exercise.name)
                .font(AppTheme.bodyTypographyFont.weight(.medium))
                .foregroundStyle(AppTheme.primaryText)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
            if !exercise.equipmentTag.isEmpty {
                Text(exercise.equipmentTag)
                    .font(AppTheme.captionTypographyFont)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            Image(systemName: "chevron.right")
                .font(AppTheme.captionTypographyFont)
                .foregroundStyle(AppTheme.tertiaryText)
        }
        .padding(.horizontal, AppTheme.spacingLG)
        .frame(minHeight: AppTheme.touchTargetSecondary, alignment: .center)
        .contentShape(Rectangle())
    }

    private func createViewModelAndApplyInitialIfNeeded() {
        if viewModel == nil {
            let vm = WorkoutStartViewModel(
                templateRepository: TemplateRepository(modelContext: modelContext),
                workoutRepository: WorkoutRepository(modelContext: modelContext),
                exerciseRepository: ExerciseRepository(modelContext: modelContext),
                lastUsedTemplateFromHome: initialTemplate
            )
            viewModel = vm
            vm.loadTemplates()
            if let t = initialTemplate, !didApplyInitialTemplate {
                didApplyInitialTemplate = true
                draftForSheet = vm.makeDraft(from: t)
            }
        }
    }
}

#Preview {
    WorkoutStartView(initialTemplate: nil, onDismiss: {})
        .modelContainer(for: [WorkoutTemplate.self, WorkoutTemplateItem.self, Exercise.self, WorkoutSession.self], inMemory: true)
}
