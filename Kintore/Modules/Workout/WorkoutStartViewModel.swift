// File: Modules/Workout/WorkoutStartViewModel.swift

import Foundation
import SwiftData

@Observable
final class WorkoutStartViewModel {
    var templates: [WorkoutTemplate] = []
    var isLoading = false
    var errorMessage: String?

    private let templateRepository: TemplateRepositoryProtocol

    init(templateRepository: TemplateRepositoryProtocol) {
        self.templateRepository = templateRepository
    }

    func loadTemplates() {
        isLoading = true
        errorMessage = nil
        do {
            templates = try templateRepository.fetchAllTemplates()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func makeDraftForNew() -> WorkoutSessionDraft {
        WorkoutSessionDraft(startedAt: Date())
    }

    func makeDraft(from template: WorkoutTemplate) -> WorkoutSessionDraft {
        let items = template.items.sorted { $0.orderIndex < $1.orderIndex }
        let exercises = items.enumerated().compactMap { index, item -> WorkoutExerciseDraft? in
            guard let ex = item.exercise else { return nil }
            return WorkoutExerciseDraft(
                exerciseId: ex.id,
                exerciseName: ex.name,
                orderIndex: index,
                sets: [WorkoutSetDraft(orderIndex: 0)]
            )
        }
        return WorkoutSessionDraft(
            startedAt: Date(),
            templateId: template.id,
            templateName: template.name,
            exercises: exercises
        )
    }
}
