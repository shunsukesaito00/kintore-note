// File: Core/ModelContainerFactory.swift
// 本番用・Preview/テスト用の ModelContainer を生成する。

import Foundation
import SwiftData

enum ModelContainerFactory {

    private static let schema = Schema([
        Exercise.self,
        WorkoutTemplate.self,
        WorkoutTemplateItem.self,
        WorkoutSession.self,
        WorkoutExercise.self,
        WorkoutSet.self,
        MemoTag.self,
        PersonalRecord.self,
        UserPreference.self,
    ])

    /// アプリ本番用（永続化）
    static func makeProduction() throws -> ModelContainer {
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        return try ModelContainer(for: schema, configurations: [config])
    }

    /// Preview / テスト用（インメモリ）
    static func makeInMemory() throws -> ModelContainer {
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        return try ModelContainer(for: schema, configurations: [config])
    }
}
