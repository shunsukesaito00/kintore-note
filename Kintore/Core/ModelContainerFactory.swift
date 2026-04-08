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
        BodyMeasurement.self,
    ])

    private static let cloudContainerId = "iCloud.com.shunsukesaito.kintore"

    /// プレミアムで CloudKit を試したがローカルにフォールバックした場合に true（UI で注意表示に使う）
    static var didFallbackFromCloudKitToLocal: Bool {
        UserDefaults.standard.bool(forKey: "kintore.modelContainer.fallbackFromCloudToLocal")
    }

    /// アプリ本番用（永続化）。
    /// まずプライベート CloudKit、失敗時はローカルのみ（`.none`）で開き直し。
    static func makeProduction() throws -> ModelContainer {
        UserDefaults.standard.set(false, forKey: "kintore.modelContainer.fallbackFromCloudToLocal")

        let configurations: [ModelConfiguration] = [
            configuration(cloudKitDatabase: .private(cloudContainerId)),
            configuration(cloudKitDatabase: .none),
        ]

        var lastError: Error?
        var index = 0
        for config in configurations {
            do {
                let container = try ModelContainer(for: schema, configurations: [config])
                if index > 0 {
                    UserDefaults.standard.set(true, forKey: "kintore.modelContainer.fallbackFromCloudToLocal")
                }
                return container
            } catch {
                lastError = error
                #if DEBUG
                print("[ModelContainer] attempt \(index) failed: \(error)")
                #endif
            }
            index += 1
        }
        throw lastError ?? NSError(
            domain: "KintoreNote",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "ModelContainer を開けませんでした"]
        )
    }

    private static func configuration(cloudKitDatabase: ModelConfiguration.CloudKitDatabase) -> ModelConfiguration {
        ModelConfiguration(
            nil,
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            groupContainer: .automatic,
            cloudKitDatabase: cloudKitDatabase
        )
    }

    /// Preview / テスト用（インメモリ）
    static func makeInMemory() throws -> ModelContainer {
        let config = ModelConfiguration(
            nil,
            schema: schema,
            isStoredInMemoryOnly: true,
            allowsSave: true,
            groupContainer: .automatic,
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: [config])
    }
}
