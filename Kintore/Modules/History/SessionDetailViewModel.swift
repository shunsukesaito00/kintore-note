import Foundation
import SwiftData

@Observable
final class SessionDetailViewModel {
    var session: WorkoutSession?
    var loadError: String?
    var summary = SessionSummaryDTO(
        sessionId: UUID(),
        durationSeconds: nil,
        exerciseCount: 0,
        setCount: 0,
        repCount: 0,
        totalVolume: 0
    )
    /// このセッション中に更新された PR（表示用）
    var prsAchieved: [(PersonalRecord, String)] = []
    /// 直前セッション比の総負荷差（nil = 比較なし）
    var volumeVersusPrevious: (previousStartedAt: Date, deltaKg: Double)?
    /// 自由メモのある種目（振り返り用）
    var exerciseMemoItems: [(name: String, memo: String)] = []

    func load(sessionId: UUID, modelContext: ModelContext) {
        loadError = nil
        prsAchieved = []
        volumeVersusPrevious = nil
        exerciseMemoItems = []
        do {
            let repo = WorkoutRepository(modelContext: modelContext)
            session = try repo.fetchSession(by: sessionId)
            guard let session else { return }
            let review = SessionReviewService(modelContext: modelContext)
            summary = review.summary(for: session)
            prsAchieved = (try? review.personalRecordsAchieved(in: session)) ?? []
            volumeVersusPrevious = try? review.volumeDeltaVersusPreviousSession(session: session)
            exerciseMemoItems = session.workoutExercises
                .sorted { $0.orderIndex < $1.orderIndex }
                .compactMap { we -> (name: String, memo: String)? in
                    let m = we.freeMemo?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    guard !m.isEmpty else { return nil }
                    let name = we.exercise?.name ?? String(localized: "common_exercise")
                    return (name: name, memo: m)
                }
        } catch {
            loadError = error.localizedDescription
            session = nil
        }
    }
}
