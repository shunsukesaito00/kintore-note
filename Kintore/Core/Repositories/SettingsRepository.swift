// File: Core/Repositories/SettingsRepository.swift

import Foundation
import SwiftData

protocol SettingsRepositoryProtocol {
    func fetchUserPreference() throws -> UserPreference?
    func createDefaultIfNeeded() throws
    func updateWeightUnit(_ unit: String) throws
    func updateTheme(_ theme: String) throws
    func updateDefaultRestSeconds(_ seconds: Int) throws
    func updateWeeklyWorkoutGoalSessions(_ count: Int) throws
}

final class SettingsRepository: SettingsRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchUserPreference() throws -> UserPreference? {
        var descriptor = FetchDescriptor<UserPreference>()
        descriptor.fetchLimit = 1
        let list = try modelContext.fetch(descriptor)
        return list.first
    }

    func createDefaultIfNeeded() throws {
        if try fetchUserPreference() != nil { return }
        let pref = UserPreference(defaultRestSeconds: 90, weightUnit: "kg", theme: "system", weeklyWorkoutGoalSessions: 0)
        modelContext.insert(pref)
        try modelContext.save()
    }

    func updateWeightUnit(_ unit: String) throws {
        guard let pref = try fetchUserPreference() else { return }
        pref.weightUnit = unit
        pref.updatedAt = Date()
        try modelContext.save()
    }

    func updateTheme(_ theme: String) throws {
        guard let pref = try fetchUserPreference() else { return }
        pref.theme = theme
        pref.updatedAt = Date()
        try modelContext.save()
    }

    func updateDefaultRestSeconds(_ seconds: Int) throws {
        guard let pref = try fetchUserPreference() else { return }
        pref.defaultRestSeconds = seconds
        pref.updatedAt = Date()
        try modelContext.save()
    }

    func updateWeeklyWorkoutGoalSessions(_ count: Int) throws {
        guard let pref = try fetchUserPreference() else { return }
        pref.weeklyWorkoutGoalSessions = max(0, min(7, count))
        pref.updatedAt = Date()
        try modelContext.save()
    }
}
