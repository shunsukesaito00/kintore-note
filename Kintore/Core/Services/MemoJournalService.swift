// File: Core/Services/MemoJournalService.swift
// メモ検索用: 完了セッションから自由メモのある種目を抽出。

import Foundation
import SwiftData

struct MemoJournalEntry: Identifiable, Hashable {
    let id: UUID
    let sessionId: UUID
    let sessionDate: Date
    let exerciseName: String
    let freeMemo: String?

    init(workoutExercise: WorkoutExercise, session: WorkoutSession) {
        self.id = workoutExercise.id
        self.sessionId = session.id
        self.sessionDate = session.startedAt
        self.exerciseName = workoutExercise.exercise?.name ?? "—"
        let m = workoutExercise.freeMemo?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.freeMemo = (m?.isEmpty == false) ? m : nil
    }

    var hasMemoContent: Bool {
        !(freeMemo ?? "").isEmpty
    }
}

enum MemoJournalService {
    /// 完了セッション配列から、自由メモのある種目だけを新しい順に返す。
    static func entries(from sessions: [WorkoutSession]) -> [MemoJournalEntry] {
        var list: [MemoJournalEntry] = []
        for session in sessions where session.endedAt != nil {
            for we in session.workoutExercises {
                let e = MemoJournalEntry(workoutExercise: we, session: session)
                guard e.hasMemoContent else { continue }
                list.append(e)
            }
        }
        return list.sorted { $0.sessionDate > $1.sessionDate }
    }
}
