// File: Core/Repositories/ExerciseRepository.swift

import Foundation
import SwiftData

protocol ExerciseRepositoryProtocol {
    func fetchAllExercises() throws -> [Exercise]
    func fetchFavoriteExercises() throws -> [Exercise]
    func searchExercises(keyword: String) throws -> [Exercise]
    func fetchExercise(by id: UUID) throws -> Exercise?
    func insertExercise(_ exercise: Exercise) throws
    func updateExercise(_ exercise: Exercise) throws
    func deleteExercise(_ exercise: Exercise) throws
    func seedDefaultExercisesIfNeeded() throws
}

final class ExerciseRepository: ExerciseRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAllExercises() throws -> [Exercise] {
        let descriptor = FetchDescriptor<Exercise>(sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.name)])
        return try modelContext.fetch(descriptor)
    }

    func fetchFavoriteExercises() throws -> [Exercise] {
        var descriptor = FetchDescriptor<Exercise>(predicate: #Predicate<Exercise> { $0.isFavorite })
        descriptor.sortBy = [SortDescriptor(\.sortOrder), SortDescriptor(\.name)]
        return try modelContext.fetch(descriptor)
    }

    func searchExercises(keyword: String) throws -> [Exercise] {
        let k = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        if k.isEmpty { return try fetchAllExercises() }
        let all = try fetchAllExercises()
        return all.filter { $0.name.localizedCaseInsensitiveContains(k) }
    }

    func fetchExercise(by id: UUID) throws -> Exercise? {
        var descriptor = FetchDescriptor<Exercise>(predicate: #Predicate<Exercise> { $0.id == id })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    func insertExercise(_ exercise: Exercise) throws {
        modelContext.insert(exercise)
        try modelContext.save()
    }

    func updateExercise(_ exercise: Exercise) throws {
        try modelContext.save()
    }

    func deleteExercise(_ exercise: Exercise) throws {
        modelContext.delete(exercise)
        try modelContext.save()
    }

    func seedDefaultExercisesIfNeeded() throws {
        DefaultExercisesSeed.seedIfNeeded(modelContext: modelContext)
    }
}
