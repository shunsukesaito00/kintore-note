// File: Core/Repositories/TemplateRepository.swift

import Foundation
import SwiftData

protocol TemplateRepositoryProtocol {
    func fetchAllTemplates() throws -> [WorkoutTemplate]
    func fetchTemplate(by id: UUID) throws -> WorkoutTemplate?
    func insertTemplate(_ template: WorkoutTemplate) throws
    func updateTemplate(_ template: WorkoutTemplate) throws
    func deleteTemplate(_ template: WorkoutTemplate) throws
    func markTemplateUsed(_ template: WorkoutTemplate, at date: Date) throws
    func buildSessionFromTemplate(_ template: WorkoutTemplate, modelContext: ModelContext) throws -> WorkoutSession
}

final class TemplateRepository: TemplateRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAllTemplates() throws -> [WorkoutTemplate] {
        let descriptor = FetchDescriptor<WorkoutTemplate>(sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.createdAt, order: .reverse)])
        return try modelContext.fetch(descriptor)
    }

    func fetchTemplate(by id: UUID) throws -> WorkoutTemplate? {
        var descriptor = FetchDescriptor<WorkoutTemplate>(predicate: #Predicate<WorkoutTemplate> { $0.id == id })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    func insertTemplate(_ template: WorkoutTemplate) throws {
        modelContext.insert(template)
        try modelContext.save()
    }

    func updateTemplate(_ template: WorkoutTemplate) throws {
        try modelContext.save()
    }

    func deleteTemplate(_ template: WorkoutTemplate) throws {
        modelContext.delete(template)
        try modelContext.save()
    }

    func markTemplateUsed(_ template: WorkoutTemplate, at date: Date) throws {
        template.lastUsedAt = date
        try modelContext.save()
    }

    /// テンプレの種目順で WorkoutSession と WorkoutExercise（セットなし）を生成。セットは記録画面で追加する。
    /// - Parameter modelContext: 使用する ModelContext（通常は呼び出し元の context）
    func buildSessionFromTemplate(_ template: WorkoutTemplate, modelContext: ModelContext) throws -> WorkoutSession {
        let session = WorkoutSession(startedAt: Date(), template: template)
        modelContext.insert(session)
        let items = template.items.sorted { $0.orderIndex < $1.orderIndex }
        for (index, item) in items.enumerated() {
            guard let ex = item.exercise else { continue }
            let we = WorkoutExercise(orderIndex: index, session: session, exercise: ex)
            modelContext.insert(we)
        }
        try modelContext.save()
        return session
    }
}
