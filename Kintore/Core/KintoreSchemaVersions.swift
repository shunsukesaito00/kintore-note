// File: Core/KintoreSchemaVersions.swift
// SwiftData の VersionedSchema 足場。破壊的変更時は V2 を追加し、MigrationPlan で段階を定義する。

import SwiftData

enum KintoreSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            Exercise.self,
            WorkoutTemplate.self,
            WorkoutTemplateItem.self,
            WorkoutSession.self,
            WorkoutExercise.self,
            WorkoutSet.self,
            MemoTag.self,
            PersonalRecord.self,
            UserPreference.self,
            BodyMeasurement.self,
        ]
    }
}

/// 将来 V2 を追加するときは `schemas` に並べ、`stages` に `MigrationStage` を定義する。
enum KintoreMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [KintoreSchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}
