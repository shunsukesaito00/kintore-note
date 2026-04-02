// File: Core/Repositories/WorkoutRepository.swift

import Foundation
import SwiftData

protocol WorkoutRepositoryProtocol {
    func createSession(template: WorkoutTemplate?) throws -> WorkoutSession
    /// 完了セッション件数（`endedAt != nil`）。一覧をフェッチせず `fetchCount` のみ。
    func countCompletedSessions() throws -> Int
    /// 完了セッションに属するセット総数。設定画面の集計用。
    func countSetsInCompletedSessions() throws -> Int
    func fetchRecentSessions(limit: Int, before startedAt: Date?) throws -> [WorkoutSession]
    /// 未完了（endedAt == nil）のセッションのうち最も新しい1件。
    func fetchIncompleteSession() throws -> WorkoutSession?
    /// 未完了のうち、開始日が「今日」（カレンダー日）のもののみ。続きから記録は当日分に限定。
    func fetchIncompleteSessionStartedToday(referenceDate: Date) throws -> WorkoutSession?
    func fetchSessions(from start: Date, to end: Date) throws -> [WorkoutSession]
    func fetchSession(by id: UUID) throws -> WorkoutSession?
    func saveWorkoutSession(_ session: WorkoutSession) throws
    func deleteSession(_ session: WorkoutSession) throws
    func fetchHistoryForExercise(exerciseId: UUID, limit: Int, from: Date?, to: Date?) throws -> [(WorkoutExercise, WorkoutSession)]
    func fetchPreviousWorkoutExercise(for exerciseId: UUID) throws -> WorkoutExercise?
    /// 種目の最終実施日（完了セッションのうち最も新しい startedAt / endedAt 基準）
    func fetchLastPerformedDate(for exerciseId: UUID) throws -> Date?
    /// 複数種目の最終実施日を一括取得（完了セッションを新しい順に走査し、各 exerciseId の初出日を採用）
    func fetchLastPerformedDates(for exerciseIds: [UUID]) throws -> [UUID: Date]
    func fetchWorkoutExercises(for session: WorkoutSession) -> [WorkoutExercise]
    func fetchWorkoutSets(for workoutExercise: WorkoutExercise) -> [WorkoutSet]
    /// Draft から永続モデルを生成して保存。PR 更新は呼び出し側で行う。
    func saveSession(from draft: WorkoutSessionDraft, exerciseLookup: [UUID: Exercise], template: WorkoutTemplate?) throws -> WorkoutSession
    /// 未完了セッションをドラフト内容で置き換えて完了させる（続きから保存用）。
    func completeIncompleteSession(sessionId: UUID, from draft: WorkoutSessionDraft, exerciseLookup: [UUID: Exercise], template: WorkoutTemplate?) throws -> WorkoutSession
    /// 同一カレンダー日は1トレーニングとする: 未完了があればそのドラフトに base を追記、なければ当日完了済みがあれば再開して追記、なければ base をそのまま返す。
    func resolveDraftForStartingWorkoutToday(base: WorkoutSessionDraft) throws -> WorkoutSessionDraft
}

final class WorkoutRepository: WorkoutRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func createSession(template: WorkoutTemplate?) throws -> WorkoutSession {
        let session = WorkoutSession(startedAt: Date(), template: template)
        modelContext.insert(session)
        try modelContext.save()
        return session
    }

    func countCompletedSessions() throws -> Int {
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate<WorkoutSession> { $0.endedAt != nil }
        )
        return try modelContext.fetchCount(descriptor)
    }

    func countSetsInCompletedSessions() throws -> Int {
        // SwiftData の #Predicate は `a?.b?.c` のようなオプショナルチェーンを
        // SQL に落とせず実行時に TERNARY(...).endedAt でクラッシュすることがあるため、
        // 完了セッションをフェッチしてから Swift 側でセット数を合算する。
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate<WorkoutSession> { $0.endedAt != nil }
        )
        let sessions = try modelContext.fetch(descriptor)
        return sessions.reduce(0) { total, session in
            total + session.workoutExercises.reduce(0) { $0 + $1.sets.count }
        }
    }

    func fetchRecentSessions(limit: Int, before startedAt: Date? = nil) throws -> [WorkoutSession] {
        let predicate: Predicate<WorkoutSession>
        if let before = startedAt {
            predicate = #Predicate<WorkoutSession> { session in
                session.endedAt != nil && session.startedAt < before
            }
        } else {
            predicate = #Predicate<WorkoutSession> { $0.endedAt != nil }
        }
        var descriptor = FetchDescriptor<WorkoutSession>(predicate: predicate, sortBy: [SortDescriptor(\.startedAt, order: .reverse)])
        descriptor.fetchLimit = limit
        return try modelContext.fetch(descriptor)
    }

    func fetchIncompleteSession() throws -> WorkoutSession? {
        var descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate<WorkoutSession> { $0.endedAt == nil },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    func fetchIncompleteSessionStartedToday(referenceDate: Date = Date()) throws -> WorkoutSession? {
        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: referenceDate)
        guard let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart) else { return nil }
        var descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate<WorkoutSession> { session in
                session.endedAt == nil && session.startedAt >= dayStart && session.startedAt < dayEnd
            },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    func fetchSessions(from start: Date, to end: Date) throws -> [WorkoutSession] {
        let predicate = #Predicate<WorkoutSession> { session in
            session.endedAt != nil && session.startedAt >= start && session.startedAt < end
        }
        var descriptor = FetchDescriptor<WorkoutSession>(predicate: predicate, sortBy: [SortDescriptor(\.startedAt, order: .reverse)])
        descriptor.fetchLimit = 0
        return try modelContext.fetch(descriptor)
    }

    func fetchSession(by id: UUID) throws -> WorkoutSession? {
        var descriptor = FetchDescriptor<WorkoutSession>(predicate: #Predicate<WorkoutSession> { $0.id == id })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    func saveWorkoutSession(_ session: WorkoutSession) throws {
        try modelContext.save()
    }

    func deleteSession(_ session: WorkoutSession) throws {
        modelContext.delete(session)
        try modelContext.save()
    }

    /// 指定種目の履歴（完了セッション内の WorkoutExercise）を endedAt 降順で取得。`from` / `to` はセッションの `endedAt` でフィルタ。
    func fetchHistoryForExercise(exerciseId: UUID, limit: Int = 100, from start: Date? = nil, to end: Date? = nil) throws -> [(WorkoutExercise, WorkoutSession)] {
        let predicate: Predicate<WorkoutSession>
        switch (start, end) {
        case (nil, nil):
            predicate = #Predicate<WorkoutSession> { $0.endedAt != nil }
        case let (s?, e?):
            predicate = #Predicate<WorkoutSession> { session in
                session.endedAt != nil && session.endedAt! >= s && session.endedAt! < e
            }
        case let (s?, nil):
            predicate = #Predicate<WorkoutSession> { session in
                session.endedAt != nil && session.endedAt! >= s
            }
        case (nil, let e?):
            predicate = #Predicate<WorkoutSession> { session in
                session.endedAt != nil && session.endedAt! < e
            }
        }
        var sessionDescriptor = FetchDescriptor<WorkoutSession>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.endedAt, order: .reverse)]
        )
        if start == nil && end == nil {
            sessionDescriptor.fetchLimit = limit
        } else {
            sessionDescriptor.fetchLimit = max(limit * 4, 500)
        }
        let sessions = try modelContext.fetch(sessionDescriptor)
        var result: [(WorkoutExercise, WorkoutSession)] = []
        for session in sessions {
            if let we = session.workoutExercises.first(where: { $0.exercise?.id == exerciseId }) {
                result.append((we, session))
                if result.count >= limit { break }
            }
        }
        return result
    }

    /// 同一種目（exerciseId）で、endedAt が存在するセッションに含まれる WorkoutExercise のうち、セッションの endedAt が最も新しい 1 件。
    func fetchPreviousWorkoutExercise(for exerciseId: UUID) throws -> WorkoutExercise? {
        // 完了済みセッションのみ。endedAt 降順でセッションを取得し、その中から該当種目の WorkoutExercise を探す。
        var sessionDescriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate<WorkoutSession> { session in
                session.endedAt != nil
            },
            sortBy: [SortDescriptor(\.endedAt, order: .reverse)]
        )
        sessionDescriptor.fetchLimit = 100
        let sessions = try modelContext.fetch(sessionDescriptor)

        for session in sessions {
            let exercises = session.workoutExercises.filter { we in
                we.exercise?.id == exerciseId
            }
            if let first = exercises.first {
                return first
            }
        }
        return nil
    }

    func fetchLastPerformedDate(for exerciseId: UUID) throws -> Date? {
        var sessionDescriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate<WorkoutSession> { $0.endedAt != nil },
            sortBy: [SortDescriptor(\.endedAt, order: .reverse)]
        )
        sessionDescriptor.fetchLimit = 200
        let sessions = try modelContext.fetch(sessionDescriptor)
        for session in sessions {
            if session.workoutExercises.contains(where: { $0.exercise?.id == exerciseId }) {
                return session.endedAt ?? session.startedAt
            }
        }
        return nil
    }

    func fetchLastPerformedDates(for exerciseIds: [UUID]) throws -> [UUID: Date] {
        guard !exerciseIds.isEmpty else { return [:] }
        let wanted = Set(exerciseIds)
        var sessionDescriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate<WorkoutSession> { $0.endedAt != nil },
            sortBy: [SortDescriptor(\.endedAt, order: .reverse)]
        )
        sessionDescriptor.fetchLimit = 500
        let sessions = try modelContext.fetch(sessionDescriptor)
        var result: [UUID: Date] = [:]
        for session in sessions {
            let d = session.endedAt ?? session.startedAt
            for we in session.workoutExercises {
                guard let eid = we.exercise?.id, wanted.contains(eid), result[eid] == nil else { continue }
                result[eid] = d
            }
            if result.count == exerciseIds.count { break }
        }
        return result
    }

    func fetchWorkoutExercises(for session: WorkoutSession) -> [WorkoutExercise] {
        session.workoutExercises.sorted { $0.orderIndex < $1.orderIndex }
    }

    func fetchWorkoutSets(for workoutExercise: WorkoutExercise) -> [WorkoutSet] {
        workoutExercise.sets.sorted { $0.orderIndex < $1.orderIndex }
    }

    func saveSession(from draft: WorkoutSessionDraft, exerciseLookup: [UUID: Exercise], template: WorkoutTemplate?) throws -> WorkoutSession {
        let endedAt = Date()
        let durationSeconds = Int(endedAt.timeIntervalSince(draft.startedAt))
        let session = WorkoutSession(
            startedAt: draft.startedAt,
            endedAt: endedAt,
            durationSeconds: max(0, durationSeconds),
            template: template
        )
        modelContext.insert(session)

        for exerciseDraft in draft.exercises.sorted(by: { $0.orderIndex < $1.orderIndex }) {
            guard let exercise = exerciseLookup[exerciseDraft.exerciseId] else { continue }
            let we = WorkoutExercise(
                orderIndex: exerciseDraft.orderIndex,
                memoTagIdsString: "",
                freeMemo: exerciseDraft.freeMemo.isEmpty ? nil : exerciseDraft.freeMemo,
                supersetGroupId: exerciseDraft.supersetGroupId,
                session: session,
                exercise: exercise
            )
            modelContext.insert(we)
            for setDraft in exerciseDraft.sets.sorted(by: { $0.orderIndex < $1.orderIndex }) {
                let ws = WorkoutSet(
                    weight: setDraft.weight,
                    reps: setDraft.reps,
                    durationSeconds: setDraft.durationSeconds,
                    distanceMeters: setDraft.distanceMeters,
                    inclinePercent: setDraft.inclinePercent,
                    speedKmh: setDraft.speedKmh,
                    orderIndex: setDraft.orderIndex,
                    completedAt: setDraft.isCompleted ? (setDraft.completedAt ?? endedAt) : nil,
                    setType: setDraft.setType == SetTypeTag.normal.rawValue ? nil : setDraft.setType,
                    rpe: setDraft.rpe,
                    isAssisted: setDraft.isAssisted,
                    setNote: setDraft.setNote.flatMap { $0.isEmpty ? nil : $0 },
                    workoutExercise: we
                )
                modelContext.insert(ws)
            }
        }
        try modelContext.save()
        return session
    }

    func resolveDraftForStartingWorkoutToday(base: WorkoutSessionDraft) throws -> WorkoutSessionDraft {
        if let incomplete = try fetchIncompleteSessionStartedToday() {
            guard var draft = WorkoutSessionDraft(resuming: incomplete) else { return base }
            return Self.appendExercises(from: base, to: &draft)
        }
        if let completed = try fetchMostRecentCompletedSessionOnSameCalendarDay(asOf: Date()) {
            try reopenSessionForEditing(sessionId: completed.id)
            guard let reopened = try fetchSession(by: completed.id),
                  var draft = WorkoutSessionDraft(resuming: reopened) else {
                return base
            }
            return Self.appendExercises(from: base, to: &draft)
        }
        return base
    }

    /// `startedAt` が同一ローカル日に含まれる完了済みセッションのうち、最も新しい `startedAt` の1件。
    func fetchMostRecentCompletedSessionOnSameCalendarDay(asOf date: Date) throws -> WorkoutSession? {
        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: date)
        guard let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart) else { return nil }
        let sessions = try fetchSessions(from: dayStart, to: dayEnd)
        return sessions.first
    }

    /// 完了済みセッションを「続きを記録」用に未完了に戻す（同日1セッションとして追記するため）。
    func reopenSessionForEditing(sessionId: UUID) throws {
        guard let session = try fetchSession(by: sessionId) else {
            throw NSError(domain: "WorkoutRepository", code: 2, userInfo: [NSLocalizedDescriptionKey: "セッションが見つかりません"])
        }
        guard session.endedAt != nil else { return }
        session.endedAt = nil
        session.durationSeconds = nil
        try modelContext.save()
    }

    private static func appendExercises(from base: WorkoutSessionDraft, to draft: inout WorkoutSessionDraft) -> WorkoutSessionDraft {
        guard !base.exercises.isEmpty else { return draft }
        var next = draft.exercises.count
        for ex in base.exercises.sorted(by: { $0.orderIndex < $1.orderIndex }) {
            var copy = ex
            copy.id = UUID()
            copy.orderIndex = next
            next += 1
            copy.supersetGroupId = nil
            draft.exercises.append(copy)
        }
        if draft.templateId == nil {
            draft.templateId = base.templateId
            draft.templateName = base.templateName
        }
        return draft
    }

    func completeIncompleteSession(sessionId: UUID, from draft: WorkoutSessionDraft, exerciseLookup: [UUID: Exercise], template: WorkoutTemplate?) throws -> WorkoutSession {
        guard let session = try fetchSession(by: sessionId), session.endedAt == nil else {
            throw NSError(domain: "WorkoutRepository", code: 1, userInfo: [NSLocalizedDescriptionKey: "未完了セッションが見つかりません"])
        }
        let existing = session.workoutExercises
        for we in existing {
            modelContext.delete(we)
        }
        session.workoutExercises = []
        session.template = template

        let endedAt = Date()
        let durationSeconds = Int(endedAt.timeIntervalSince(draft.startedAt))
        session.durationSeconds = max(0, durationSeconds)

        for exerciseDraft in draft.exercises.sorted(by: { $0.orderIndex < $1.orderIndex }) {
            guard let exercise = exerciseLookup[exerciseDraft.exerciseId] else { continue }
            let we = WorkoutExercise(
                orderIndex: exerciseDraft.orderIndex,
                memoTagIdsString: "",
                freeMemo: exerciseDraft.freeMemo.isEmpty ? nil : exerciseDraft.freeMemo,
                supersetGroupId: exerciseDraft.supersetGroupId,
                session: session,
                exercise: exercise
            )
            modelContext.insert(we)
            for setDraft in exerciseDraft.sets.sorted(by: { $0.orderIndex < $1.orderIndex }) {
                let ws = WorkoutSet(
                    weight: setDraft.weight,
                    reps: setDraft.reps,
                    durationSeconds: setDraft.durationSeconds,
                    distanceMeters: setDraft.distanceMeters,
                    inclinePercent: setDraft.inclinePercent,
                    speedKmh: setDraft.speedKmh,
                    orderIndex: setDraft.orderIndex,
                    completedAt: setDraft.isCompleted ? (setDraft.completedAt ?? endedAt) : nil,
                    setType: setDraft.setType == SetTypeTag.normal.rawValue ? nil : setDraft.setType,
                    rpe: setDraft.rpe,
                    isAssisted: setDraft.isAssisted,
                    setNote: setDraft.setNote.flatMap { $0.isEmpty ? nil : $0 },
                    workoutExercise: we
                )
                modelContext.insert(ws)
            }
        }
        session.endedAt = endedAt
        try modelContext.save()
        return session
    }
}
