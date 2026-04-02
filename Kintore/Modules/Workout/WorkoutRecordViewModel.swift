// File: Modules/Workout/WorkoutRecordViewModel.swift

import Foundation
import SwiftData

@MainActor
@Observable
final class WorkoutRecordViewModel {
    var draft: WorkoutSessionDraft
    var previousRecords: [UUID: PreviousRecordDTO] = [:]
    var saveError: String?
    var isSaving = false
    /// 直前に PR を更新した種目名。バナー表示用。表示後にクリアする。
    var newPrBannerText: String?
    /// 休憩中の場合の種目名（Watch 同期用）。startRestAfterSetCompleted でセットし、休憩終了でクリア。
    private(set) var currentRestExerciseName: String?

    private let workoutRepository: WorkoutRepositoryProtocol
    private let exerciseRepository: ExerciseRepositoryProtocol
    private let previousRecordService: PreviousRecordService
    private let personalRecordService: PersonalRecordService
    private let settingsRepository: SettingsRepositoryProtocol?
    private let modelContext: ModelContext
    weak var restTimerManager: RestTimerManager?

    init(
        draft: WorkoutSessionDraft,
        workoutRepository: WorkoutRepositoryProtocol,
        exerciseRepository: ExerciseRepositoryProtocol,
        previousRecordService: PreviousRecordService,
        personalRecordService: PersonalRecordService,
        settingsRepository: SettingsRepositoryProtocol? = nil,
        restTimerManager: RestTimerManager? = nil,
        modelContext: ModelContext
    ) {
        self.draft = draft
        self.workoutRepository = workoutRepository
        self.exerciseRepository = exerciseRepository
        self.previousRecordService = previousRecordService
        self.personalRecordService = personalRecordService
        self.settingsRepository = settingsRepository
        self.restTimerManager = restTimerManager
        self.modelContext = modelContext
    }

    func loadPreviousRecords() {
        for ex in draft.exercises {
            if let dto = try? previousRecordService.fetchPreviousRecord(exerciseId: ex.exerciseId) {
                previousRecords[ex.exerciseId] = dto
            }
        }
    }

    // MARK: - セッションサマリー（記録画面上部の4枠）

    var sessionSummaryExerciseCount: Int { draft.exercises.count }

    var sessionSummarySetCount: Int {
        draft.exercises.reduce(0) { $0 + $1.sets.count }
    }

    var sessionSummaryTotalReps: Int {
        draft.exercises.reduce(0) { acc, ex in
            acc + ex.sets.reduce(0) { $0 + ($1.reps ?? 0) }
        }
    }

    /// 総挙上（kg）。重量×回数が有効なセットのみ `VolumeCalculator` で合算。
    var sessionSummaryTotalVolumeKg: Double {
        draft.exercises.reduce(0) { total, ex in
            let kind = ExerciseKind(stored: ex.exerciseKind)
            switch kind {
            case .strength, .weightedBodyweight:
                return total + ex.sets.reduce(0.0) { t, s in
                    t + VolumeCalculator.volume(weight: s.weight, reps: s.reps)
                }
            case .time, .cardio:
                return total
            }
        }
    }

    /// 戻る前に確認すべきかどうか。入力済みなら true。
    func hasMeaningfulInput() -> Bool {
        for ex in draft.exercises {
            if !ex.freeMemo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return true }
            for set in ex.sets {
                if set.weight != nil || set.reps != nil || set.durationSeconds != nil || set.distanceMeters != nil
                    || set.inclinePercent != nil || set.speedKmh != nil || set.isCompleted {
                    return true
                }
            }
        }
        return false
    }

    func exerciseKind(at exerciseIndex: Int) -> ExerciseKind {
        guard exerciseIndex < draft.exercises.count else { return .strength }
        return ExerciseKind(stored: draft.exercises[exerciseIndex].exerciseKind)
    }

    /// トレッドミル有酸素（傾斜・速度・時間）
    func isTreadmillCardio(exerciseIndex: Int) -> Bool {
        guard exerciseIndex < draft.exercises.count else { return false }
        let ex = draft.exercises[exerciseIndex]
        return ExerciseKind(stored: ex.exerciseKind) == .cardio
            && ex.cardioInputStyle == CardioInputStyle.treadmill.rawValue
    }

    func addExercise(_ exercise: Exercise) {
        let new = WorkoutExerciseDraft(
            exerciseId: exercise.id,
            exerciseName: exercise.name,
            exerciseKind: exercise.exerciseKind,
            cardioInputStyle: exercise.cardioInputStyle,
            orderIndex: draft.exercises.count,
            sets: [WorkoutSetDraft(orderIndex: 0)]
        )
        draft.exercises.append(new)
        if let dto = try? previousRecordService.fetchPreviousRecord(exerciseId: exercise.id) {
            previousRecords[exercise.id] = dto
        }
    }

    /// 種目の並び順を変更。from を to の位置に移動し、orderIndex を更新する。移動した種目のスーパーセットは解除する。
    func moveExercise(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex != destinationIndex,
              sourceIndex >= 0, sourceIndex < draft.exercises.count,
              destinationIndex >= 0, destinationIndex < draft.exercises.count else { return }
        clearSupersetGroup(forExerciseIndex: sourceIndex)
        let moved = draft.exercises.remove(at: sourceIndex)
        draft.exercises.insert(moved, at: destinationIndex)
        for i in draft.exercises.indices {
            draft.exercises[i].orderIndex = i
        }
    }

    // MARK: - スーパーセット（隣接2種目のペア）

    private func clearSupersetGroup(forExerciseIndex i: Int) {
        guard i >= 0, i < draft.exercises.count else { return }
        guard let g = draft.exercises[i].supersetGroupId else { return }
        for idx in draft.exercises.indices where draft.exercises[idx].supersetGroupId == g {
            draft.exercises[idx].supersetGroupId = nil
        }
    }

    /// この種目と **直下の種目** をスーパーセットにする（既存のペアは解除してから付け替え）。
    func linkSupersetWithNext(exerciseIndex: Int) {
        guard exerciseIndex + 1 < draft.exercises.count else { return }
        clearSupersetGroup(forExerciseIndex: exerciseIndex)
        clearSupersetGroup(forExerciseIndex: exerciseIndex + 1)
        let g = UUID()
        draft.exercises[exerciseIndex].supersetGroupId = g
        draft.exercises[exerciseIndex + 1].supersetGroupId = g
    }

    func unlinkSuperset(exerciseIndex: Int) {
        clearSupersetGroup(forExerciseIndex: exerciseIndex)
    }

    func canLinkSupersetWithNext(exerciseIndex: Int) -> Bool {
        exerciseIndex + 1 < draft.exercises.count
    }

    func isInSuperset(exerciseIndex: Int) -> Bool {
        guard exerciseIndex < draft.exercises.count else { return false }
        return draft.exercises[exerciseIndex].supersetGroupId != nil
    }

    // MARK: - ウォームアップ一括

    /// この種目の全セットをウォームアップにする（重量×回の種目向け）。
    func markAllSetsWarmup(exerciseIndex: Int) {
        guard exerciseIndex < draft.exercises.count else { return }
        for si in draft.exercises[exerciseIndex].sets.indices {
            draft.exercises[exerciseIndex].sets[si].setType = SetTypeTag.warmup.rawValue
        }
    }

    func canMarkAllWarmup(exerciseIndex: Int) -> Bool {
        exerciseKind(at: exerciseIndex).usesLoadVolume
    }

    func addSet(exerciseIndex: Int) {
        guard exerciseIndex < draft.exercises.count else { return }
        let order = draft.exercises[exerciseIndex].sets.count
        draft.exercises[exerciseIndex].sets.append(WorkoutSetDraft(orderIndex: order))
    }

    /// 指定した種目のセットを削除し、orderIndex を詰める。1 セットだけの場合は削除しない。
    func removeSets(exerciseIndex: Int, at offsets: IndexSet) {
        guard exerciseIndex < draft.exercises.count else { return }
        var sets = draft.exercises[exerciseIndex].sets
        guard sets.count > 1 else { return }
        offsets.sorted(by: >).forEach { sets.remove(at: $0) }
        for i in sets.indices {
            sets[i].orderIndex = i
        }
        draft.exercises[exerciseIndex].sets = sets
    }

    func setWeight(exerciseIndex: Int, setIndex: Int, _ string: String) {
        guard exerciseIndex < draft.exercises.count,
              setIndex < draft.exercises[exerciseIndex].sets.count else { return }
        let trimmed = string.replacingOccurrences(of: ",", with: ".")
        let v = Double(trimmed)
        let unit = UserDefaults.standard.string(forKey: AppTheme.weightUnitStorageKey) ?? "kg"
        if let v, v > 0 {
            if unit == "lb" {
                draft.exercises[exerciseIndex].sets[setIndex].weight = AppFormatters.poundsToKilograms(v)
            } else {
                draft.exercises[exerciseIndex].sets[setIndex].weight = v
            }
        } else {
            draft.exercises[exerciseIndex].sets[setIndex].weight = v
        }
        maybeAutoCompleteAfterEdit(exerciseIndex: exerciseIndex, setIndex: setIndex)
    }

    func setReps(exerciseIndex: Int, setIndex: Int, _ string: String) {
        guard exerciseIndex < draft.exercises.count,
              setIndex < draft.exercises[exerciseIndex].sets.count else { return }
        draft.exercises[exerciseIndex].sets[setIndex].reps = Int(string)
        maybeAutoCompleteAfterEdit(exerciseIndex: exerciseIndex, setIndex: setIndex)
    }

    // MARK: - セット行 列7「完了」（Toggle → isCompleted / completedAt）

    /// そのセットの完了状態。true で `completedAt` を設定し、休憩・PR 判定を行う。false で `completedAt` を消す。
    func setCompleted(exerciseIndex: Int, setIndex: Int, _ completed: Bool) {
        guard exerciseIndex < draft.exercises.count,
              setIndex < draft.exercises[exerciseIndex].sets.count else { return }
        draft.exercises[exerciseIndex].sets[setIndex].isCompleted = completed
        if completed {
            let completedAt = Date()
            draft.exercises[exerciseIndex].sets[setIndex].completedAt = completedAt
            startRestAfterSetCompleted(exerciseIndex: exerciseIndex, setIndex: setIndex)
            let kind = exerciseKind(at: exerciseIndex)
            if kind.participatesInPersonalRecord,
               let w = draft.exercises[exerciseIndex].sets[setIndex].weight,
               let r = draft.exercises[exerciseIndex].sets[setIndex].reps,
               w > 0, r > 0 {
                let exId = draft.exercises[exerciseIndex].exerciseId
                if (try? personalRecordService.updateIfNeeded(exerciseId: exId, weight: w, reps: r, achievedAt: completedAt)) == true {
                    newPrBannerText = "🏆 NEW PR! \(draft.exercises[exerciseIndex].exerciseName)"
                }
            }
        } else {
            draft.exercises[exerciseIndex].sets[setIndex].completedAt = nil
        }
    }

    /// スーパーセットでは「ペアの先頭種目」のセット完了時は休憩を挟まず次種目へ移る。末尾種目でラウンド完了後に休憩。
    private func shouldStartRestTimerAfterCompletingSet(exerciseIndex: Int, setIndex: Int) -> Bool {
        if UserDefaults.standard.object(forKey: AppTheme.autoStartRestOnSetCompleteKey) as? Bool == false {
            return false
        }
        guard exerciseIndex < draft.exercises.count else { return true }
        guard let groupId = draft.exercises[exerciseIndex].supersetGroupId else { return true }
        let partnerIndex: Int? = {
            let n = draft.exercises.count
            if exerciseIndex + 1 < n, draft.exercises[exerciseIndex + 1].supersetGroupId == groupId {
                return exerciseIndex + 1
            }
            if exerciseIndex > 0, draft.exercises[exerciseIndex - 1].supersetGroupId == groupId {
                return exerciseIndex - 1
            }
            return nil
        }()
        guard let partner = partnerIndex else { return true }
        if exerciseIndex < partner {
            if setIndex < draft.exercises[partner].sets.count {
                return false
            }
            return true
        }
        return true
    }

    private func startRestAfterSetCompleted(exerciseIndex: Int, setIndex: Int) {
        guard shouldStartRestTimerAfterCompletingSet(exerciseIndex: exerciseIndex, setIndex: setIndex) else { return }
        applyRestTimerForCompletedSet(exerciseIndex: exerciseIndex, setIndex: setIndex)
    }

    /// 自動休憩オフ時など、手動で休憩を開始。直近完了セット（なければ 0 番）のウォームアップ判定で秒数を決める。
    func startManualRestForExercise(exerciseIndex: Int) {
        guard exerciseIndex < draft.exercises.count else { return }
        let sets = draft.exercises[exerciseIndex].sets
        let setIndex = sets.lastIndex(where: { $0.isCompleted }) ?? 0
        applyRestTimerForCompletedSet(exerciseIndex: exerciseIndex, setIndex: setIndex)
    }

    /// ナビバーの休憩ボタン用: 未完了セットがある最初の種目で休憩を開始（秒数はその種目の直近完了セット基準）。
    func startManualRestFromToolbar() {
        guard !draft.exercises.isEmpty else { return }
        for (i, ex) in draft.exercises.enumerated() {
            let hasIncomplete = ex.sets.contains { !$0.isCompleted }
            if hasIncomplete {
                startManualRestForExercise(exerciseIndex: i)
                return
            }
        }
        startManualRestForExercise(exerciseIndex: draft.exercises.count - 1)
    }

    private func applyRestTimerForCompletedSet(exerciseIndex: Int, setIndex: Int) {
        guard let rest = restTimerManager else { return }
        let isWarmup = exerciseIndex < draft.exercises.count
            && setIndex < draft.exercises[exerciseIndex].sets.count
            && draft.exercises[exerciseIndex].sets[setIndex].setType == SetTypeTag.warmup.rawValue
        let seconds: Int
        if exerciseIndex < draft.exercises.count,
           let ex = try? exerciseRepository.fetchExercise(by: draft.exercises[exerciseIndex].exerciseId) {
            if isWarmup, let w = ex.defaultRestSecondsWarmUp, w > 0 {
                seconds = w
            } else if isWarmup {
                seconds = 60
            } else if let s = ex.defaultRestSeconds, s > 0 {
                seconds = s
            } else if let pref = try? settingsRepository?.fetchUserPreference(), pref.defaultRestSeconds > 0 {
                seconds = pref.defaultRestSeconds
            } else {
                seconds = 90
            }
        } else if let pref = try? settingsRepository?.fetchUserPreference(), pref.defaultRestSeconds > 0 {
            seconds = isWarmup ? 60 : pref.defaultRestSeconds
        } else {
            seconds = isWarmup ? 60 : 90
        }
        RestTimerManager.requestNotificationPermissionIfNeeded()
        let name = (exerciseIndex < draft.exercises.count) ? draft.exercises[exerciseIndex].exerciseName : nil
        currentRestExerciseName = name
        rest.startRest(seconds: seconds)
        #if os(iOS)
        WatchSyncManager.shared.updateRest(remaining: seconds, exerciseName: name, lastPrText: newPrBannerText)
        #endif
    }

    /// 休憩残り秒数が変わったときに View から呼ぶ。Watch に同期し、残り 0 で currentRestExerciseName をクリアする。
    func reportRestToWatch(remaining: Int, exerciseName: String?) {
        #if os(iOS)
        WatchSyncManager.shared.updateRest(remaining: remaining, exerciseName: exerciseName, lastPrText: newPrBannerText)
        #endif
        if remaining <= 0 {
            currentRestExerciseName = nil
        }
    }

    func setFreeMemo(exerciseIndex: Int, _ text: String) {
        guard exerciseIndex < draft.exercises.count else { return }
        draft.exercises[exerciseIndex].freeMemo = text
    }

    func weightString(exerciseIndex: Int, setIndex: Int) -> String {
        guard exerciseIndex < draft.exercises.count,
              setIndex < draft.exercises[exerciseIndex].sets.count else { return "" }
        let w = draft.exercises[exerciseIndex].sets[setIndex].weight
        guard let w = w else { return "" }
        let unit = UserDefaults.standard.string(forKey: AppTheme.weightUnitStorageKey) ?? "kg"
        if unit == "lb" {
            return AppFormatters.formatWeightNumber(AppFormatters.kilogramsToPounds(w))
        }
        return AppFormatters.formatWeightNumber(w)
    }

    func setTypeString(exerciseIndex: Int, setIndex: Int) -> String {
        guard exerciseIndex < draft.exercises.count,
              setIndex < draft.exercises[exerciseIndex].sets.count else { return SetTypeTag.normal.rawValue }
        return draft.exercises[exerciseIndex].sets[setIndex].setType
    }

    func setSetType(exerciseIndex: Int, setIndex: Int, _ type: String) {
        guard exerciseIndex < draft.exercises.count,
              setIndex < draft.exercises[exerciseIndex].sets.count else { return }
        draft.exercises[exerciseIndex].sets[setIndex].setType = type
    }

    func rpeValue(exerciseIndex: Int, setIndex: Int) -> Int? {
        guard exerciseIndex < draft.exercises.count,
              setIndex < draft.exercises[exerciseIndex].sets.count else { return nil }
        return draft.exercises[exerciseIndex].sets[setIndex].rpe
    }

    func setRpe(exerciseIndex: Int, setIndex: Int, _ value: Int?) {
        guard exerciseIndex < draft.exercises.count,
              setIndex < draft.exercises[exerciseIndex].sets.count else { return }
        draft.exercises[exerciseIndex].sets[setIndex].rpe = value
    }

    func isAssisted(exerciseIndex: Int, setIndex: Int) -> Bool {
        guard exerciseIndex < draft.exercises.count,
              setIndex < draft.exercises[exerciseIndex].sets.count else { return false }
        return draft.exercises[exerciseIndex].sets[setIndex].isAssisted
    }

    func setAssisted(exerciseIndex: Int, setIndex: Int, _ value: Bool) {
        guard exerciseIndex < draft.exercises.count,
              setIndex < draft.exercises[exerciseIndex].sets.count else { return }
        draft.exercises[exerciseIndex].sets[setIndex].isAssisted = value
    }

    func repsString(exerciseIndex: Int, setIndex: Int) -> String {
        guard exerciseIndex < draft.exercises.count,
              setIndex < draft.exercises[exerciseIndex].sets.count else { return "" }
        let r = draft.exercises[exerciseIndex].sets[setIndex].reps
        return r.map { "\($0)" } ?? ""
    }

    func durationString(exerciseIndex: Int, setIndex: Int) -> String {
        guard exerciseIndex < draft.exercises.count,
              setIndex < draft.exercises[exerciseIndex].sets.count else { return "" }
        let s = draft.exercises[exerciseIndex].sets[setIndex].durationSeconds
        return s.map { "\($0)" } ?? ""
    }

    func setDuration(exerciseIndex: Int, setIndex: Int, _ string: String) {
        guard exerciseIndex < draft.exercises.count,
              setIndex < draft.exercises[exerciseIndex].sets.count else { return }
        draft.exercises[exerciseIndex].sets[setIndex].durationSeconds = Int(string)
        maybeAutoCompleteAfterEdit(exerciseIndex: exerciseIndex, setIndex: setIndex)
    }

    /// 有酸素: 距離を km 入力（内部は m）
    func distanceKmString(exerciseIndex: Int, setIndex: Int) -> String {
        guard exerciseIndex < draft.exercises.count,
              setIndex < draft.exercises[exerciseIndex].sets.count else { return "" }
        guard let m = draft.exercises[exerciseIndex].sets[setIndex].distanceMeters, m > 0 else { return "" }
        let km = m / 1000
        return AppFormatters.formatWeightNumber(km)
    }

    func setDistanceKm(exerciseIndex: Int, setIndex: Int, _ string: String) {
        guard exerciseIndex < draft.exercises.count,
              setIndex < draft.exercises[exerciseIndex].sets.count else { return }
        let v = Double(string.replacingOccurrences(of: ",", with: "."))
        draft.exercises[exerciseIndex].sets[setIndex].distanceMeters = v.map { $0 * 1000 }
        maybeAutoCompleteAfterEdit(exerciseIndex: exerciseIndex, setIndex: setIndex)
    }

    func inclinePercentString(exerciseIndex: Int, setIndex: Int) -> String {
        guard exerciseIndex < draft.exercises.count,
              setIndex < draft.exercises[exerciseIndex].sets.count else { return "" }
        guard let p = draft.exercises[exerciseIndex].sets[setIndex].inclinePercent else { return "" }
        return AppFormatters.formatWeightNumber(p)
    }

    func setInclinePercent(exerciseIndex: Int, setIndex: Int, _ string: String) {
        guard exerciseIndex < draft.exercises.count,
              setIndex < draft.exercises[exerciseIndex].sets.count else { return }
        let t = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty {
            draft.exercises[exerciseIndex].sets[setIndex].inclinePercent = nil
            return
        }
        guard let v = Double(t.replacingOccurrences(of: ",", with: ".")) else { return }
        draft.exercises[exerciseIndex].sets[setIndex].inclinePercent = v
        maybeAutoCompleteAfterEdit(exerciseIndex: exerciseIndex, setIndex: setIndex)
    }

    func speedKmhString(exerciseIndex: Int, setIndex: Int) -> String {
        guard exerciseIndex < draft.exercises.count,
              setIndex < draft.exercises[exerciseIndex].sets.count else { return "" }
        guard let s = draft.exercises[exerciseIndex].sets[setIndex].speedKmh, s > 0 else { return "" }
        return AppFormatters.formatWeightNumber(s)
    }

    func setSpeedKmh(exerciseIndex: Int, setIndex: Int, _ string: String) {
        guard exerciseIndex < draft.exercises.count,
              setIndex < draft.exercises[exerciseIndex].sets.count else { return }
        let t = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty {
            draft.exercises[exerciseIndex].sets[setIndex].speedKmh = nil
            return
        }
        guard let v = Double(t.replacingOccurrences(of: ",", with: ".")) else { return }
        draft.exercises[exerciseIndex].sets[setIndex].speedKmh = v > 0 ? v : nil
        maybeAutoCompleteAfterEdit(exerciseIndex: exerciseIndex, setIndex: setIndex)
    }

    /// 完了 UI を外したため、入力が揃ったら自動で完了扱い（休憩・PR・保存の `completedAt` と整合）。
    private func maybeAutoCompleteAfterEdit(exerciseIndex: Int, setIndex: Int) {
        guard exerciseIndex < draft.exercises.count,
              setIndex < draft.exercises[exerciseIndex].sets.count else { return }
        let kind = exerciseKind(at: exerciseIndex)
        let s = draft.exercises[exerciseIndex].sets[setIndex]
        let exDraft = draft.exercises[exerciseIndex]

        let shouldComplete: Bool
        switch kind {
        case .strength, .weightedBodyweight:
            let w = s.weight ?? 0
            let r = s.reps ?? 0
            shouldComplete = w > 0 && r > 0
        case .time:
            shouldComplete = (s.durationSeconds ?? 0) > 0
        case .cardio:
            if exDraft.cardioInputStyle == CardioInputStyle.treadmill.rawValue {
                let spd = s.speedKmh ?? 0
                let dur = s.durationSeconds ?? 0
                shouldComplete = spd > 0 && dur > 0
            } else {
                shouldComplete = (s.distanceMeters ?? 0) > 0 || (s.durationSeconds ?? 0) > 0
            }
        }

        if shouldComplete {
            if !s.isCompleted {
                setCompleted(exerciseIndex: exerciseIndex, setIndex: setIndex, true)
            }
        } else if s.isCompleted {
            setCompleted(exerciseIndex: exerciseIndex, setIndex: setIndex, false)
        }
    }

    func isSetCompleted(exerciseIndex: Int, setIndex: Int) -> Bool {
        guard exerciseIndex < draft.exercises.count,
              setIndex < draft.exercises[exerciseIndex].sets.count else { return false }
        return draft.exercises[exerciseIndex].sets[setIndex].isCompleted
    }

    /// 休憩タイマー開始前の既定秒（設定のデフォルト休憩）
    func defaultRestPresetSeconds(exerciseIndex: Int) -> Int {
        _ = exerciseIndex
        if let pref = try? settingsRepository?.fetchUserPreference(), pref.defaultRestSeconds > 0 {
            return pref.defaultRestSeconds
        }
        return 150
    }

    func previousRecordSummary(exerciseId: UUID, weightUnit: String = "kg") -> String? {
        guard let dto = previousRecords[exerciseId] else { return nil }
        let dateStr = dto.date.map { AppFormatters.formatDateWithWeekday($0) } ?? ""
        let tail = dto.setCount > 0 ? " × \(dto.setCount)セット" : ""
        let body: String
        switch dto.exerciseKind {
        case .time:
            let sec = dto.sets.first?.durationSeconds.map { "\($0)秒" } ?? "—"
            body = "前回 \(sec)\(tail)"
        case .cardio:
            let d0 = dto.sets.first
            if dto.cardioInputStyle == CardioInputStyle.treadmill.rawValue {
                let inc = d0?.inclinePercent.map { AppFormatters.formatWeightNumber($0) + "%" } ?? "—"
                let sp = d0?.speedKmh.map { AppFormatters.formatWeightNumber($0) } ?? "—"
                let sec = d0?.durationSeconds.map { "\($0)秒" } ?? "—"
                body = "前回 \(inc) / \(sp) km/h / \(sec)\(tail)"
            } else {
                let km = d0?.distanceMeters.map { AppFormatters.formatWeightNumber($0 / 1000) } ?? "—"
                let sec = d0?.durationSeconds.map { "\($0)秒" } ?? "—"
                body = "前回 \(km)km / \(sec)\(tail)"
            }
        case .strength, .weightedBodyweight:
            let w = dto.weight.map { AppFormatters.formatWeightNumber($0) } ?? "—"
            let r = dto.reps.map { "\($0)" } ?? "—"
            body = "前回 \(w)\(weightUnit) × \(r)\(tail)"
        }
        if dateStr.isEmpty { return body }
        return "\(body) 最終 \(dateStr)"
    }

    /// 種目ヘッダー用。前回の各セットを列挙。表示なしの場合は nil。
    func previousRecordSetsDisplayText(exerciseId: UUID, weightUnit: String = "kg") -> String? {
        guard let dto = previousRecords[exerciseId], !dto.sets.isEmpty else { return nil }
        let parts: [String] = dto.sets.compactMap { set in
            Self.formatPreviousSetLine(
                kind: dto.exerciseKind,
                set: set,
                weightUnit: weightUnit,
                cardioInputStyle: dto.cardioInputStyle
            )
        }
        guard !parts.isEmpty else { return nil }
        let dateStr = dto.date.map { AppFormatters.formatDateWithWeekday($0) } ?? ""
        if dateStr.isEmpty {
            return "前回：" + parts.joined(separator: " ")
        }
        return "前回：" + parts.joined(separator: " ") + " 最終 \(dateStr)"
    }

    /// 前回記録パネル用。日付とセット行リスト。表示なしなら nil。
    func previousRecordPanelData(exerciseId: UUID, weightUnit: String = "kg") -> (date: String, setLines: [String])? {
        guard let dto = previousRecords[exerciseId], !dto.sets.isEmpty else { return nil }
        let dateStr = dto.date.map { AppFormatters.formatDate($0) } ?? ""
        let lines = dto.sets.enumerated().map { index, set -> String in
            if let line = Self.formatPreviousSetLine(
                kind: dto.exerciseKind,
                set: set,
                weightUnit: weightUnit,
                cardioInputStyle: dto.cardioInputStyle
            ) {
                return "\(index + 1)  \(line)"
            }
            return "\(index + 1)  —"
        }
        return (dateStr.isEmpty ? "—" : dateStr, lines)
    }

    private static func formatPreviousSetLine(
        kind: ExerciseKind,
        set: PreviousSetSnapshot,
        weightUnit: String,
        cardioInputStyle: String? = nil
    ) -> String? {
        switch kind {
        case .strength, .weightedBodyweight:
            guard let w = set.weight, let r = set.reps, w > 0, r > 0 else { return nil }
            return "\(AppFormatters.formatWeightNumber(w))\(weightUnit) × \(r)\(String(localized: "unit_reps"))"
        case .time:
            guard let s = set.durationSeconds, s > 0 else { return nil }
            return "\(s)\(String(localized: "unit_seconds"))"
        case .cardio:
            if cardioInputStyle == CardioInputStyle.treadmill.rawValue {
                let inc = set.inclinePercent.map { AppFormatters.formatWeightNumber($0) + "%" }
                let sp = set.speedKmh.map { AppFormatters.formatWeightNumber($0) + String(localized: "unit_kmh") }
                let sec = set.durationSeconds.map { "\($0)\(String(localized: "unit_seconds"))" }
                let parts = [inc, sp, sec].compactMap { $0 }
                return parts.isEmpty ? nil : parts.joined(separator: " / ")
            }
            let km = set.distanceMeters.map { AppFormatters.formatWeightNumber($0 / 1000) + String(localized: "unit_km") }
            let sec = set.durationSeconds.map { "\($0)\(String(localized: "unit_seconds"))" }
            switch (km, sec) {
            case let (k?, s?): return "\(k) / \(s)"
            case let (k?, nil): return k
            case let (nil, s?): return s
            default: return nil
            }
        }
    }

    // MARK: - セット行 列6「前回と同じ」（行単位の補助・その setIndex の行だけ）

    /// この行だけ前回値をコピーできるか。
    func canApplyPreviousForRow(exerciseIndex: Int, setIndex: Int) -> Bool {
        guard exerciseIndex < draft.exercises.count else { return false }
        let exId = draft.exercises[exerciseIndex].exerciseId
        guard let dto = previousRecords[exId], !dto.sets.isEmpty else { return false }
        let idx = min(setIndex, dto.sets.count - 1)
        let t = dto.sets[idx]
        switch dto.exerciseKind {
        case .strength, .weightedBodyweight:
            return t.weight != nil && t.reps != nil && (t.weight ?? 0) > 0 && (t.reps ?? 0) > 0
        case .time:
            return t.durationSeconds != nil && (t.durationSeconds ?? 0) > 0
        case .cardio:
            if dto.cardioInputStyle == CardioInputStyle.treadmill.rawValue {
                return t.inclinePercent != nil || (t.speedKmh ?? 0) > 0 || (t.durationSeconds ?? 0) > 0
            }
            return (t.distanceMeters != nil && (t.distanceMeters ?? 0) > 0) || (t.durationSeconds != nil && (t.durationSeconds ?? 0) > 0)
        }
    }

    /// **この行（setIndex）だけ**に、前回記録の同順セットをコピーする。
    func applyPreviousToRow(exerciseIndex: Int, setIndex: Int) {
        guard exerciseIndex < draft.exercises.count,
              setIndex < draft.exercises[exerciseIndex].sets.count else { return }
        let exDraft = draft.exercises[exerciseIndex]
        guard let dto = previousRecords[exDraft.exerciseId], !dto.sets.isEmpty else { return }
        let idx = min(setIndex, dto.sets.count - 1)
        let t = dto.sets[idx]
        switch dto.exerciseKind {
        case .strength, .weightedBodyweight:
            draft.exercises[exerciseIndex].sets[setIndex].weight = t.weight
            draft.exercises[exerciseIndex].sets[setIndex].reps = t.reps
        case .time:
            draft.exercises[exerciseIndex].sets[setIndex].durationSeconds = t.durationSeconds
        case .cardio:
            if dto.cardioInputStyle == CardioInputStyle.treadmill.rawValue {
                draft.exercises[exerciseIndex].sets[setIndex].inclinePercent = t.inclinePercent
                draft.exercises[exerciseIndex].sets[setIndex].speedKmh = t.speedKmh
                draft.exercises[exerciseIndex].sets[setIndex].durationSeconds = t.durationSeconds
                draft.exercises[exerciseIndex].sets[setIndex].distanceMeters = nil
            } else {
                draft.exercises[exerciseIndex].sets[setIndex].distanceMeters = t.distanceMeters
                draft.exercises[exerciseIndex].sets[setIndex].durationSeconds = t.durationSeconds
                draft.exercises[exerciseIndex].sets[setIndex].inclinePercent = nil
                draft.exercises[exerciseIndex].sets[setIndex].speedKmh = nil
            }
        }
    }

    /// 同一種目内の **1つ上のセット**を現在行にコピー（今セッション）。
    func copyFromRowAbove(exerciseIndex: Int, setIndex: Int) {
        guard exerciseIndex < draft.exercises.count,
              setIndex > 0,
              setIndex < draft.exercises[exerciseIndex].sets.count else { return }
        let sets = draft.exercises[exerciseIndex].sets
        let above = sets[setIndex - 1]
        let kind = exerciseKind(at: exerciseIndex)
        switch kind {
        case .strength, .weightedBodyweight:
            draft.exercises[exerciseIndex].sets[setIndex].weight = above.weight
            draft.exercises[exerciseIndex].sets[setIndex].reps = above.reps
            draft.exercises[exerciseIndex].sets[setIndex].setNote = above.setNote
        case .time:
            draft.exercises[exerciseIndex].sets[setIndex].durationSeconds = above.durationSeconds
            draft.exercises[exerciseIndex].sets[setIndex].setNote = above.setNote
        case .cardio:
            if isTreadmillCardio(exerciseIndex: exerciseIndex) {
                draft.exercises[exerciseIndex].sets[setIndex].inclinePercent = above.inclinePercent
                draft.exercises[exerciseIndex].sets[setIndex].speedKmh = above.speedKmh
                draft.exercises[exerciseIndex].sets[setIndex].durationSeconds = above.durationSeconds
                draft.exercises[exerciseIndex].sets[setIndex].distanceMeters = nil
            } else {
                draft.exercises[exerciseIndex].sets[setIndex].distanceMeters = above.distanceMeters
                draft.exercises[exerciseIndex].sets[setIndex].durationSeconds = above.durationSeconds
            }
            draft.exercises[exerciseIndex].sets[setIndex].setNote = above.setNote
        }
    }

    func canCopyFromRowAbove(exerciseIndex: Int, setIndex: Int) -> Bool {
        exerciseIndex < draft.exercises.count && setIndex > 0 && setIndex < draft.exercises[exerciseIndex].sets.count
    }

    func setSetNote(exerciseIndex: Int, setIndex: Int, value: String) {
        guard exerciseIndex < draft.exercises.count,
              setIndex < draft.exercises[exerciseIndex].sets.count else { return }
        let v = value.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.exercises[exerciseIndex].sets[setIndex].setNote = v.isEmpty ? nil : v
    }

    /// 前回セッションのセット列で **この種目のセットをすべて置き換え**（セット数も前回に合わせる）。
    func applyPreviousSessionToExercise(exerciseIndex: Int) {
        guard exerciseIndex < draft.exercises.count else { return }
        let exId = draft.exercises[exerciseIndex].exerciseId
        guard let dto = previousRecords[exId], !dto.sets.isEmpty else { return }
        var newSets: [WorkoutSetDraft] = []
        for (i, t) in dto.sets.enumerated() {
            switch dto.exerciseKind {
            case .strength, .weightedBodyweight:
                let w = t.weight
                let r = t.reps
                newSets.append(WorkoutSetDraft(
                    id: UUID(),
                    weight: (w != nil && w! > 0) ? w : nil,
                    reps: (r != nil && r! > 0) ? r : nil,
                    orderIndex: i,
                    isCompleted: false,
                    completedAt: nil,
                    setType: SetTypeTag.normal.rawValue,
                    rpe: nil,
                    isAssisted: false
                ))
            case .time:
                newSets.append(WorkoutSetDraft(
                    id: UUID(),
                    durationSeconds: (t.durationSeconds != nil && (t.durationSeconds ?? 0) > 0) ? t.durationSeconds : nil,
                    orderIndex: i,
                    isCompleted: false,
                    completedAt: nil,
                    setType: SetTypeTag.normal.rawValue,
                    rpe: nil,
                    isAssisted: false
                ))
            case .cardio:
                if draft.exercises[exerciseIndex].cardioInputStyle == CardioInputStyle.treadmill.rawValue {
                    newSets.append(WorkoutSetDraft(
                        id: UUID(),
                        durationSeconds: (t.durationSeconds != nil && (t.durationSeconds ?? 0) > 0) ? t.durationSeconds : nil,
                        inclinePercent: t.inclinePercent,
                        speedKmh: (t.speedKmh != nil && (t.speedKmh ?? 0) > 0) ? t.speedKmh : nil,
                        orderIndex: i,
                        isCompleted: false,
                        completedAt: nil,
                        setType: SetTypeTag.normal.rawValue,
                        rpe: nil,
                        isAssisted: false
                    ))
                } else {
                    newSets.append(WorkoutSetDraft(
                        id: UUID(),
                        durationSeconds: (t.durationSeconds != nil && (t.durationSeconds ?? 0) > 0) ? t.durationSeconds : nil,
                        distanceMeters: (t.distanceMeters != nil && (t.distanceMeters ?? 0) > 0) ? t.distanceMeters : nil,
                        orderIndex: i,
                        isCompleted: false,
                        completedAt: nil,
                        setType: SetTypeTag.normal.rawValue,
                        rpe: nil,
                        isAssisted: false
                    ))
                }
            }
        }
        draft.exercises[exerciseIndex].sets = newSets
    }

    func canApplyPreviousSessionToExercise(exerciseIndex: Int) -> Bool {
        guard exerciseIndex < draft.exercises.count else { return false }
        let exId = draft.exercises[exerciseIndex].exerciseId
        guard let dto = previousRecords[exId], !dto.sets.isEmpty else { return false }
        switch dto.exerciseKind {
        case .strength, .weightedBodyweight:
            return dto.sets.contains { t in
                (t.weight != nil && (t.weight ?? 0) > 0) && (t.reps != nil && (t.reps ?? 0) > 0)
            }
        case .time:
            return dto.sets.contains { ($0.durationSeconds ?? 0) > 0 }
        case .cardio:
            if draft.exercises[exerciseIndex].cardioInputStyle == CardioInputStyle.treadmill.rawValue {
                return dto.sets.contains {
                    $0.inclinePercent != nil || ($0.speedKmh ?? 0) > 0 || ($0.durationSeconds ?? 0) > 0
                }
            }
            return dto.sets.contains {
                ($0.distanceMeters ?? 0) > 0 || ($0.durationSeconds ?? 0) > 0
            }
        }
    }

    /// Watch の「セット完了」から呼ぶ。先頭の未完了セットを完了にする（重量・回数はそのまま）。
    func completeFirstIncompleteSet() {
        for exIndex in 0..<draft.exercises.count {
            let sets = draft.exercises[exIndex].sets
            for setIndex in 0..<sets.count where !sets[setIndex].isCompleted {
                setCompleted(exerciseIndex: exIndex, setIndex: setIndex, true)
                return
            }
        }
    }

    /// Apple Watch からの入力。重量×回の種目で、先頭の未完了セットに重量（kg）・回数を入れて完了する。
    func applyWatchWeightRepsComplete(weightKg: Double, reps: Int) {
        guard weightKg > 0, reps > 0 else { return }
        for exIndex in 0..<draft.exercises.count {
            guard exerciseKind(at: exIndex).usesLoadVolume else { continue }
            let sets = draft.exercises[exIndex].sets
            for setIndex in 0..<sets.count where !sets[setIndex].isCompleted {
                draft.exercises[exIndex].sets[setIndex].weight = weightKg
                draft.exercises[exIndex].sets[setIndex].reps = reps
                setCompleted(exerciseIndex: exIndex, setIndex: setIndex, true)
                return
            }
        }
    }

    func saveSession() {
        isSaving = true
        saveError = nil
        do {
            var lookup: [UUID: Exercise] = [:]
            for exDraft in draft.exercises {
                if let ex = try exerciseRepository.fetchExercise(by: exDraft.exerciseId) {
                    lookup[exDraft.exerciseId] = ex
                }
            }
            var template: WorkoutTemplate?
            if let tid = draft.templateId {
                template = try TemplateRepository(modelContext: modelContext).fetchTemplate(by: tid)
            }
            let saved: WorkoutSession
            if let resumeId = draft.resumingPersistentSessionId {
                saved = try workoutRepository.completeIncompleteSession(sessionId: resumeId, from: draft, exerciseLookup: lookup, template: template)
            } else {
                saved = try workoutRepository.saveSession(from: draft, exerciseLookup: lookup, template: template)
            }
            if let template = template {
                try? TemplateRepository(modelContext: modelContext).markTemplateUsed(template, at: Date())
            }
            for exDraft in draft.exercises {
                guard ExerciseKind(stored: exDraft.exerciseKind).participatesInPersonalRecord else { continue }
                for setDraft in exDraft.sets where setDraft.isCompleted {
                    guard let w = setDraft.weight, let r = setDraft.reps, w > 0, r > 0 else { continue }
                    _ = try? personalRecordService.updateIfNeeded(exerciseId: exDraft.exerciseId, weight: w, reps: r, achievedAt: setDraft.completedAt ?? Date())
                }
            }
            isSaving = false
            let savedId = saved.id
            AnalyticsEventService.log(.sessionCompleted(sessionId: savedId))
            let startedAt = draft.startedAt
            let endedAt = saved.endedAt ?? Date()
            Task { @MainActor in
                WidgetDataStore.updateFrom(modelContext: modelContext)
                if HealthKitSettings.saveWorkoutsEnabled && HealthKitWorkoutService.isHealthDataAvailable {
                    await HealthKitWorkoutService.shared.saveWorkoutIfEnabled(start: startedAt, end: endedAt)
                }
                onSaveSuccess?(savedId)
                tryRequestReviewAfterTenthSession()
                RetentionNotificationService.scheduleReengagementIfNeeded()
            }
        } catch {
            saveError = error.localizedDescription
            isSaving = false
        }
    }

    private static let requestedReviewAt10Key = "kintore.requestedReviewAt10"

    private func tryRequestReviewAfterTenthSession() {
        guard !UserDefaults.standard.bool(forKey: Self.requestedReviewAt10Key) else { return }
        let count = (try? workoutRepository.countCompletedSessions()) ?? 0
        guard count == 10 else { return }
        UserDefaults.standard.set(true, forKey: Self.requestedReviewAt10Key)
        onRequestReview?()
    }

    var onSaveSuccess: ((UUID) -> Void)?
    var onRequestReview: (() -> Void)?
}
