// File: Core/Services/WorkoutStatsService.swift
// 総挙上重量計算・ワークアウト回数集計の基礎。

import Foundation
import SwiftData

final class WorkoutStatsService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// 1 セットの総挙上 = weight × reps。nil は 0。
    static func volumeForSet(weight: Double?, reps: Int?) -> Double {
        guard let w = weight, let r = reps, w > 0, r > 0 else { return 0 }
        return w * Double(r)
    }

    /// 1 種目（WorkoutExercise）の総挙上
    func totalVolume(for workoutExercise: WorkoutExercise) -> Double {
        workoutExercise.sets.reduce(0) { sum, set in
            sum + Self.volumeForSet(weight: set.weight, reps: set.reps)
        }
    }

    /// 1 セッションの総挙上
    func totalVolume(for session: WorkoutSession) -> Double {
        session.workoutExercises.reduce(0) { sum, we in
            sum + totalVolume(for: we)
        }
    }

    /// 期間内の全セッションの総挙上合計（完了済みのみ）
    func totalVolume(from start: Date, to end: Date) throws -> Double {
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate<WorkoutSession> { session in
                session.endedAt != nil && session.startedAt >= start && session.startedAt <= end
            }
        )
        let sessions = try modelContext.fetch(descriptor)
        return sessions.reduce(0) { sum, session in sum + totalVolume(for: session) }
    }

    /// ワークアウト回数（完了済みセッション数）。期間指定可。nil の場合は全期間。
    func workoutCount(from start: Date? = nil, to end: Date? = nil) throws -> Int {
        if let s = start, let e = end {
            let descriptor = FetchDescriptor<WorkoutSession>(
                predicate: #Predicate<WorkoutSession> { session in
                    session.endedAt != nil && session.startedAt >= s && session.startedAt <= e
                }
            )
            return try modelContext.fetchCount(descriptor)
        } else {
            let descriptor = FetchDescriptor<WorkoutSession>(
                predicate: #Predicate<WorkoutSession> { $0.endedAt != nil }
            )
            return try modelContext.fetchCount(descriptor)
        }
    }
}
