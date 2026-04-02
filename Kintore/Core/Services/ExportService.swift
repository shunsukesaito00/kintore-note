// File: Core/Services/ExportService.swift
// セッションデータの CSV エクスポート
//
// 将来の拡張候補（仕様・課金方針の確定後）: JSON 出力、列の選択、無料プラン向けの範囲限定エクスポートなど。

import Foundation
import SwiftData

enum ExportService {
    struct ExerciseExportRowDTO {
        let date: Date
        let exerciseName: String
        let setIndex: Int
        let weight: Double?
        let reps: Int?
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        f.locale = Locale(identifier: "ja_JP")
        return f
    }()

    private static let dayOnlyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "ja_JP")
        return f
    }()

    /// カレンダー上の開始日・終了日から、`buildSessionsCSV(from:to:)` 用の半開区間 `[start, end)` を作る。無効なら nil。
    static func sessionExportRange(from startDay: Date, to endDay: Date) -> (start: Date, end: Date)? {
        let cal = Calendar.current
        let s = cal.startOfDay(for: startDay)
        guard let e = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: endDay)) else { return nil }
        guard s < e else { return nil }
        return (s, e)
    }

    /// 完了済みセッションを CSV 文字列に変換する。1セット1行。日付範囲指定可。先頭にエクスポート日時を付与。
    static func buildSessionsCSV(modelContext: ModelContext, weightUnit: String = "kg", from start: Date? = nil, to end: Date? = nil) throws -> String {
        let predicate: Predicate<WorkoutSession>
        if let s = start, let e = end {
            predicate = #Predicate<WorkoutSession> { session in
                session.endedAt != nil && session.startedAt >= s && session.startedAt < e
            }
        } else {
            predicate = #Predicate<WorkoutSession> { $0.endedAt != nil }
        }
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        let sessions = try modelContext.fetch(descriptor)
        let exportDateLine = "# エクスポート日時: \(dateFormatter.string(from: Date()))"
        var rows: [String] = [exportDateLine]
        if let s = start, let e = end {
            let cal = Calendar.current
            let lastIncluded = cal.date(byAdding: .day, value: -1, to: e) ?? s
            let periodLine = "# 対象期間: \(dayOnlyFormatter.string(from: s)) 〜 \(dayOnlyFormatter.string(from: lastIncluded))（完了セッションの開始日時がこの範囲）"
            rows.append(periodLine)
        }
        rows.append("日付,種目名,種目タイプ,スーパーセットID,セット,重量(\(weightUnit)),回数,秒,距離(m),補助")
        for session in sessions {
            rows.append(contentsOf: sessionCSVLines(session: session, weightUnit: weightUnit))
        }
        return rows.joined(separator: "\n")
    }

    /// 単一セッションを `buildSessionsCSV` と同じ列で出力。
    static func buildSessionCSV(session: WorkoutSession, weightUnit: String = "kg") -> String {
        let exportDateLine = "# エクスポート日時: \(dateFormatter.string(from: Date()))"
        let idLine = "# セッションID: \(session.id.uuidString)"
        var rows: [String] = [exportDateLine, idLine]
        rows.append("日付,種目名,種目タイプ,スーパーセットID,セット,重量(\(weightUnit)),回数,秒,距離(m),補助")
        rows.append(contentsOf: sessionCSVLines(session: session, weightUnit: weightUnit))
        return rows.joined(separator: "\n")
    }

    private static func sessionCSVLines(session: WorkoutSession, weightUnit: String) -> [String] {
        let dateStr = dateFormatter.string(from: session.startedAt)
        let exercises = session.workoutExercises.sorted { $0.orderIndex < $1.orderIndex }
        var lines: [String] = []
        for we in exercises {
            let name = we.exercise?.name ?? "—"
            let kind = ExerciseKind(stored: we.exercise?.exerciseKind).displayName
            let sup = we.supersetGroupId.map { $0.uuidString } ?? ""
            let sets = we.sets.sorted { $0.orderIndex < $1.orderIndex }
            for (idx, set) in sets.enumerated() {
                let w = set.weight.map { AppFormatters.formatWeightNumber($0) } ?? ""
                let r = set.reps.map { "\($0)" } ?? ""
                let sec = set.durationSeconds.map { "\($0)" } ?? ""
                let dist = set.distanceMeters.map { AppFormatters.formatWeightNumber($0) } ?? ""
                let assisted = (set.isAssisted == true) ? "あり" : ""
                let line = [dateStr, name, kind, sup, "\(idx + 1)", w, r, sec, dist, assisted].map { escapeCSV($0) }.joined(separator: ",")
                lines.append(line)
            }
        }
        return lines
    }

    /// 身体記録を CSV に変換。体重は常に **kg** で出力（アプリ内部と一致）。先頭にエクスポート日時。
    static func buildBodyMeasurementsCSV(modelContext: ModelContext) throws -> String {
        let repo = BodyMeasurementRepository(modelContext: modelContext)
        let items = try repo.fetchAllSortedByDate()
        let chronological = items.sorted { $0.measuredAt < $1.measuredAt }
        let exportDateLine = "# エクスポート日時: \(dateFormatter.string(from: Date()))"
        var rows: [String] = [exportDateLine, "測定日時,体重(kg),体脂肪率(%),メモ"]
        for m in chronological {
            let dateStr = dateFormatter.string(from: m.measuredAt)
            let w = m.weightKg.map { AppFormatters.formatWeightNumber($0) } ?? ""
            let f = m.bodyFatPercent.map { AppFormatters.formatWeightNumber($0) } ?? ""
            let note = m.note ?? ""
            let line = [dateStr, w, f, note].map { escapeCSV($0) }.joined(separator: ",")
            rows.append(line)
        }
        return rows.joined(separator: "\n")
    }

    /// 種目単位の CSV（1セット1行）。`from` / `to` はセッションの `endedAt` でフィルタ（`to` は排他的）。
    static func buildExerciseCSV(
        modelContext: ModelContext,
        exerciseId: UUID,
        weightUnit: String = "kg",
        from start: Date? = nil,
        to end: Date? = nil,
        maxRows: Int = 500
    ) throws -> String {
        let sessionLimit = (start == nil && end == nil) ? 300 : maxRows
        let history = try WorkoutRepository(modelContext: modelContext).fetchHistoryForExercise(
            exerciseId: exerciseId,
            limit: sessionLimit,
            from: start,
            to: end
        )
        let exportDateLine = "# エクスポート日時: \(dateFormatter.string(from: Date()))"
        var rows: [String] = [exportDateLine]
        if let s = start, let e = end {
            rows.append("# 対象期間: \(dayOnlyFormatter.string(from: s)) 〜 \(dayOnlyFormatter.string(from: e))（セッション終了日時がこの範囲）")
        } else if let s = start {
            rows.append("# 対象期間: \(dayOnlyFormatter.string(from: s)) 以降")
        } else if let e = end {
            rows.append("# 対象期間: \(dayOnlyFormatter.string(from: e)) より前")
        }
        rows.append("日付,種目名,セット,重量(\(weightUnit)),回数")
        for (we, session) in history {
            let date = dateFormatter.string(from: session.endedAt ?? session.startedAt)
            let name = we.exercise?.name ?? "—"
            for set in we.sets.sorted(by: { $0.orderIndex < $1.orderIndex }) {
                let w = set.weight.map { AppFormatters.formatWeightNumber($0) } ?? ""
                let r = set.reps.map(String.init) ?? ""
                rows.append([date, name, "\(set.orderIndex + 1)", w, r].map(escapeCSV).joined(separator: ","))
            }
        }
        return rows.joined(separator: "\n")
    }

    private static func escapeCSV(_ s: String) -> String {
        if s.contains(",") || s.contains("\"") || s.contains("\n") {
            return "\"" + s.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return s
    }

    /// CSV を一時ファイルに書き込み、共有用 URL を返す。ファイル名にバックアップ日時を含める。
    static func writeExportToTempFile(csv: String) -> URL? {
        writeCSVToTempFile(csv: csv, fileNamePrefix: "RepLog_export")
    }

    /// 期間指定エクスポート用ファイル名プレフィックス。
    static func writeRangedSessionsExportToTempFile(csv: String) -> URL? {
        writeCSVToTempFile(csv: csv, fileNamePrefix: "RepLog_export_range")
    }

    /// 身体記録 CSV 用の一時ファイル。
    static func writeBodyMeasurementsExportToTempFile(csv: String) -> URL? {
        writeCSVToTempFile(csv: csv, fileNamePrefix: "RepLog_body")
    }

    /// 単一セッション CSV 用。
    static func writeSessionExportToTempFile(csv: String) -> URL? {
        writeCSVToTempFile(csv: csv, fileNamePrefix: "RepLog_session")
    }

    /// 種目 CSV 用。
    static func writeExerciseExportToTempFile(csv: String) -> URL? {
        writeCSVToTempFile(csv: csv, fileNamePrefix: "RepLog_exercise")
    }

    private static func writeCSVToTempFile(csv: String, fileNamePrefix: String) -> URL? {
        let timestamp = dateFormatter.string(from: Date()).replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: ":", with: "-")
        let fileName = "\(fileNamePrefix)_\(timestamp).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }
}
