import Foundation
import SwiftData

struct SessionSummaryDTO {
    let sessionId: UUID
    let durationSeconds: Int?
    let exerciseCount: Int
    let setCount: Int
    let repCount: Int
    let totalVolume: Double
}

final class SessionReviewService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func summary(for session: WorkoutSession) -> SessionSummaryDTO {
        let stats = WorkoutStatsService(modelContext: modelContext)
        return SessionSummaryDTO(
            sessionId: session.id,
            durationSeconds: session.durationSeconds,
            exerciseCount: stats.sessionExerciseCount(session: session),
            setCount: stats.sessionTotalSetCount(session: session),
            repCount: stats.sessionTotalRepCount(session: session),
            totalVolume: stats.totalVolume(for: session)
        )
    }

    /// `achievedAt` がセッションの開始〜終了時刻の範囲に入る PR（種目は当該セッションに含まれるもの）。
    func personalRecordsAchieved(in session: WorkoutSession) throws -> [(PersonalRecord, String)] {
        let prService = PersonalRecordService(modelContext: modelContext)
        let exRepo = ExerciseRepository(modelContext: modelContext)
        let end = session.endedAt ?? session.startedAt.addingTimeInterval(TimeInterval(max(0, session.durationSeconds ?? 0)))
        let exerciseIds = Set(session.workoutExercises.compactMap { $0.exercise?.id })
        var out: [(PersonalRecord, String)] = []
        for eid in exerciseIds {
            guard let pr = try? prService.fetchPersonalRecord(exerciseId: eid) else { continue }
            guard pr.achievedAt >= session.startedAt && pr.achievedAt <= end else { continue }
            guard let ex = try? exRepo.fetchExercise(by: eid) else { continue }
            out.append((pr, ex.name))
        }
        return out.sorted { $0.0.achievedAt < $1.0.achievedAt }
    }

    /// このセッションの直前に完了したセッションとの総負荷差（総挙上ベース）。
    func volumeDeltaVersusPreviousSession(session: WorkoutSession) throws -> (previousStartedAt: Date, deltaKg: Double)? {
        let repo = WorkoutRepository(modelContext: modelContext)
        guard let prev = try repo.fetchRecentSessions(limit: 1, before: session.startedAt).first else { return nil }
        let stats = WorkoutStatsService(modelContext: modelContext)
        let v = stats.totalVolume(for: session)
        let pv = stats.totalVolume(for: prev)
        return (prev.startedAt, v - pv)
    }
}
