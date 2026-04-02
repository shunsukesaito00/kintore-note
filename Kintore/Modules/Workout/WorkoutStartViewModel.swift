// File: Modules/Workout/WorkoutStartViewModel.swift
// 入力開始画面用: ルーティン最大3件・部位別種目・Draft生成・カスタム種目追加。

import Foundation
import SwiftData

/// 部位の固定表示順（1箇所管理で将来の並び替えに対応）
private let bodyPartOrder = ["胸", "背中", "脚", "肩", "腕", "体幹", "有酸素"]

@Observable
final class WorkoutStartViewModel {
    static let maxRoutinesOnScreen = 3
    static let maxExercisesPerBodyPart = 3

    var templates: [WorkoutTemplate] = []
    var lastUsedTemplate: WorkoutTemplate?
    var exercisesByBodyPart: [String: [Exercise]] = [:]
    /// 種目ID → 最終実施日（完了セッション）
    var lastPerformedDates: [UUID: Date] = [:]
    var isLoading = false
    var errorMessage: String?

    /// 直近利用順で最大3件。表示用。
    var recentTemplates: [WorkoutTemplate] {
        let sorted = templates.sorted { t1, t2 in
            let d1 = t1.lastUsedAt ?? .distantPast
            let d2 = t2.lastUsedAt ?? .distantPast
            return d1 > d2
        }
        return Array(sorted.prefix(Self.maxRoutinesOnScreen))
    }

    var hasMoreRoutines: Bool { templates.count > Self.maxRoutinesOnScreen }

    private let templateRepository: TemplateRepositoryProtocol
    private let workoutRepository: WorkoutRepositoryProtocol
    private let exerciseRepository: ExerciseRepositoryProtocol
    private let lastUsedTemplateFromHome: WorkoutTemplate?

    init(
        templateRepository: TemplateRepositoryProtocol,
        workoutRepository: WorkoutRepositoryProtocol,
        exerciseRepository: ExerciseRepositoryProtocol,
        lastUsedTemplateFromHome: WorkoutTemplate? = nil
    ) {
        self.templateRepository = templateRepository
        self.workoutRepository = workoutRepository
        self.exerciseRepository = exerciseRepository
        self.lastUsedTemplateFromHome = lastUsedTemplateFromHome
        self.lastUsedTemplate = lastUsedTemplateFromHome
    }

    /// 部位の固定順序（View で ForEach に渡す）
    static var orderedBodyParts: [String] { bodyPartOrder }

    func loadTemplates() {
        isLoading = true
        errorMessage = nil
        do {
            templates = try templateRepository.fetchAllTemplates()
            if lastUsedTemplate == nil {
                let recent = try workoutRepository.fetchRecentSessions(limit: 1, before: nil)
                lastUsedTemplate = recent.first?.template
            }
            loadExercisesByBodyPart()
            loadLastPerformedDates()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func loadLastPerformedDates() {
        var dict: [UUID: Date] = [:]
        for ex in exercisesByBodyPart.values.flatMap({ $0 }) {
            if let d = try? workoutRepository.fetchLastPerformedDate(for: ex.id) {
                dict[ex.id] = d
            }
        }
        lastPerformedDates = dict
    }

    /// 「前回から N 日」表示用。未実施なら nil。
    func daysSinceLastPerformedText(for exerciseId: UUID) -> String? {
        guard let last = lastPerformedDates[exerciseId] else { return nil }
        let cal = Calendar.current
        let d0 = cal.startOfDay(for: last)
        let today = cal.startOfDay(for: Date())
        let days = cal.dateComponents([.day], from: d0, to: today).day ?? 0
        if days <= 0 { return "前回: 今日" }
        return "前回から \(days) 日"
    }

    private func loadExercisesByBodyPart() {
        do {
            let all = try exerciseRepository.fetchAllExercises()
            var grouped: [String: [Exercise]] = [:]
            for ex in all {
                let part = ex.bodyPartTag.isEmpty ? "その他" : ex.bodyPartTag
                grouped[part, default: []].append(ex)
            }
            for key in grouped.keys {
                grouped[key]?.sort { ($0.sortOrder, $0.name) < ($1.sortOrder, $1.name) }
            }
            exercisesByBodyPart = grouped
        } catch {
            exercisesByBodyPart = [:]
        }
    }

    /// 指定部位の先頭 limit 件を返す
    func exercisesForBodyPart(_ bodyPart: String, limit: Int? = nil) -> [Exercise] {
        let n = limit ?? Self.maxExercisesPerBodyPart
        let list = exercisesByBodyPart[bodyPart] ?? []
        return Array(list.prefix(n))
    }

    /// 指定部位が4件以上あるか（「すべて表示」を出すか）
    func hasMoreExercises(for bodyPart: String) -> Bool {
        (exercisesByBodyPart[bodyPart]?.count ?? 0) > Self.maxExercisesPerBodyPart
    }

    /// 指定部位の全種目（部位専用一覧用）
    func allExercisesForBodyPart(_ bodyPart: String) -> [Exercise] {
        exercisesByBodyPart[bodyPart] ?? []
    }

    /// 部位帯ヘッダー用：その部位の種目のうち最終実施が最も新しい日時からの相対表現。未実施は nil。
    func bodyPartLastTrainingSummary(for bodyPart: String) -> String? {
        let exercises = exercisesByBodyPart[bodyPart] ?? []
        var latest: Date?
        for ex in exercises {
            if let d = lastPerformedDates[ex.id] {
                if latest == nil || d > latest! { latest = d }
            }
        }
        guard let date = latest else { return nil }
        return AppFormatters.formatRelativeWorkoutPast(from: date)
    }

    func makeDraftForNew() -> WorkoutSessionDraft {
        let base = WorkoutSessionDraft(startedAt: Date())
        do {
            return try workoutRepository.resolveDraftForStartingWorkoutToday(base: base)
        } catch {
            return base
        }
    }

    func makeDraft(from template: WorkoutTemplate) -> WorkoutSessionDraft {
        let items = template.items.sorted { $0.orderIndex < $1.orderIndex }
        let exercises = items.enumerated().compactMap { index, item -> WorkoutExerciseDraft? in
            guard let ex = item.exercise else { return nil }
            return WorkoutExerciseDraft(
                exerciseId: ex.id,
                exerciseName: ex.name,
                exerciseKind: ex.exerciseKind,
                cardioInputStyle: ex.cardioInputStyle,
                orderIndex: index,
                sets: [WorkoutSetDraft(orderIndex: 0)]
            )
        }
        let base = WorkoutSessionDraft(
            startedAt: Date(),
            templateId: template.id,
            templateName: template.name,
            exercises: exercises
        )
        do {
            return try workoutRepository.resolveDraftForStartingWorkoutToday(base: base)
        } catch {
            return base
        }
    }

    /// 1種目だけの Draft（部位から種目タップ時）
    func makeDraftFromExercise(_ exercise: Exercise) -> WorkoutSessionDraft {
        let draft = WorkoutExerciseDraft(
            exerciseId: exercise.id,
            exerciseName: exercise.name,
            exerciseKind: exercise.exerciseKind,
            cardioInputStyle: exercise.cardioInputStyle,
            orderIndex: 0,
            sets: [WorkoutSetDraft(orderIndex: 0)]
        )
        let base = WorkoutSessionDraft(startedAt: Date(), exercises: [draft])
        do {
            return try workoutRepository.resolveDraftForStartingWorkoutToday(base: base)
        } catch {
            return base
        }
    }

    /// カスタム種目を保存し、一覧を再読み込み
    func insertCustomExercise(name: String, bodyPart: String, equipment: String, exerciseKind: ExerciseKind = .strength, defaultRestSeconds: Int? = 90) throws {
        let count = (try? exerciseRepository.fetchAllExercises().count) ?? 0
        var cardio: String?
        if exerciseKind == .cardio {
            cardio = CardioInputStyle.treadmill.rawValue
        }
        let ex = Exercise(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            bodyPartTag: bodyPart,
            equipmentTag: equipment,
            defaultRestSeconds: defaultRestSeconds,
            exerciseKind: exerciseKind.rawValue,
            cardioInputStyle: cardio,
            isPreset: false,
            isFavorite: false,
            sortOrder: count,
            createdAt: Date()
        )
        try exerciseRepository.insertExercise(ex)
        loadExercisesByBodyPart()
        loadLastPerformedDates()
    }
}
