// File: Modules/Settings/BodyMetricsView.swift
// 身体記録の一覧・追加・削除・推移グラフ。

import SwiftUI
import SwiftData
import Charts

private struct IdentifiableBodyExportURL: Identifiable {
    let id = UUID()
    let url: URL
}

private struct BodyMetricChartPoint: Identifiable {
    let id: UUID
    let date: Date
    let value: Double
}

struct BodyMetricsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(AppTheme.weightUnitStorageKey) private var weightUnit: String = "kg"
    @State private var items: [BodyMeasurement] = []
    @State private var loadError: String?
    @State private var showAddSheet = false
    @State private var exportFileURL: URL?

    var body: some View {
        Group {
            if let loadError {
                Text(loadError)
                    .foregroundStyle(AppTheme.destructive)
            } else if items.isEmpty {
                EmptyStateView(
                    message: String(localized: "body_metrics_empty"),
                    icon: "figure.stand",
                    actionTitle: String(localized: "body_metrics_add"),
                    action: { showAddSheet = true }
                )
            } else {
                List {
                    if !weightChartPoints.isEmpty {
                        Section {
                            bodyMetricChart(
                                title: String(localized: "body_metrics_weight_trend"),
                                valueLabel: String(localized: "body_metrics_weight"),
                                unit: displayUnit,
                                points: weightChartPoints,
                                color: AppTheme.accent
                            )
                        }
                    }
                    if !bodyFatChartPoints.isEmpty {
                        Section {
                            bodyMetricChart(
                                title: String(localized: "body_metrics_bodyfat_trend"),
                                valueLabel: String(localized: "body_metrics_bodyfat_rate"),
                                unit: "%",
                                points: bodyFatChartPoints,
                                color: AppTheme.accentSecondary
                            )
                        }
                    }
                    Section {
                        ForEach(items, id: \.id) { row in
                            VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
                                Text(AppFormatters.formatDateWithWeekday(row.measuredAt))
                                    .font(AppTheme.bodySecondaryFont)
                                    .foregroundStyle(AppTheme.secondaryText)
                                HStack(spacing: AppTheme.spacingMD) {
                                    if let w = row.weightKg {
                                        Text("\(AppFormatters.formatWeightNumber(convertWeightIfNeeded(w)))\(displayUnit) ")
                                            .font(AppTheme.bodySemiboldFont)
                                            + Text(String(localized: "body_metrics_weight"))
                                            .font(AppTheme.captionTypographyFont)
                                            .foregroundStyle(AppTheme.secondaryText)
                                    }
                                    if let f = row.bodyFatPercent {
                                        Text("\(AppFormatters.formatWeightNumber(f))% ")
                                            .font(AppTheme.bodySemiboldFont)
                                            + Text(String(localized: "body_metrics_bodyfat"))
                                            .font(AppTheme.captionTypographyFont)
                                            .foregroundStyle(AppTheme.secondaryText)
                                    }
                                }
                                if let n = row.note, !n.isEmpty {
                                    Text(n)
                                        .font(AppTheme.captionTypographyFont)
                                        .foregroundStyle(AppTheme.secondaryText)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete(perform: deleteAt)
                    } header: {
                        Text(String(localized: "body_metrics_history"))
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .tint(AppTheme.accent)
        .appTabRootChrome()
        .navigationTitle(String(localized: "body_metrics_title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if !items.isEmpty {
                    Button {
                        exportBodyCSV()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.body.weight(.medium))
                            .foregroundStyle(AppTheme.accent)
                    }
                    .accessibilityLabel(String(localized: "body_metrics_a11y_csv_export"))
                }
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.body.weight(.medium))
                        .foregroundStyle(AppTheme.accent)
                }
                .accessibilityLabel(String(localized: "body_metrics_a11y_add"))
            }
        }
        .sheet(item: Binding(
            get: { exportFileURL.map { IdentifiableBodyExportURL(url: $0) } },
            set: { exportFileURL = $0?.url }
        )) { identifiable in
            ShareSheet(activityItems: [identifiable.url], onDismiss: { exportFileURL = nil })
        }
        .sheet(isPresented: $showAddSheet) {
            BodyMeasurementEditSheet(weightUnit: weightUnit) {
                showAddSheet = false
                reload()
            }
            .environment(\.modelContext, modelContext)
            .standardSheetChrome()
        }
        .onAppear {
            reload()
        }
    }

    private func exportBodyCSV() {
        guard let csv = try? ExportService.buildBodyMeasurementsCSV(modelContext: modelContext),
              let url = ExportService.writeBodyMeasurementsExportToTempFile(csv: csv) else { return }
        AnalyticsEventService.log(.csvExported(kind: "body_measurements"))
        exportFileURL = url
    }

    private var displayUnit: String { weightUnit }

    /// グラフ用: 日付昇順（古い→新しい）
    private var weightChartPoints: [BodyMetricChartPoint] {
        items.compactMap { m -> BodyMetricChartPoint? in
            guard let w = m.weightKg else { return nil }
            return BodyMetricChartPoint(
                id: m.id,
                date: m.measuredAt,
                value: convertWeightIfNeeded(w)
            )
        }
        .sorted { $0.date < $1.date }
    }

    private var bodyFatChartPoints: [BodyMetricChartPoint] {
        items.compactMap { m -> BodyMetricChartPoint? in
            guard let f = m.bodyFatPercent else { return nil }
            return BodyMetricChartPoint(id: m.id, date: m.measuredAt, value: f)
        }
        .sorted { $0.date < $1.date }
    }

    /// 保存は常に kg。表示が lb のときは変換して表示。
    private func convertWeightIfNeeded(_ kg: Double) -> Double {
        guard weightUnit == "lb" else { return kg }
        return kg * 2.204_622_6218
    }

    @ViewBuilder
    private func bodyMetricChart(
        title: String,
        valueLabel: String,
        unit: String,
        points: [BodyMetricChartPoint],
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
            Text(title)
                .font(AppTheme.cardTitleFont)
            Group {
                if points.count == 1, let p = points.first {
                    Chart {
                        PointMark(
                            x: .value(String(localized: "body_metrics_chart_date"), p.date),
                            y: .value(valueLabel, p.value)
                        )
                        .foregroundStyle(color)
                        .symbolSize(48)
                    }
                } else {
                    Chart {
                        ForEach(points) { pt in
                            AreaMark(
                                x: .value(String(localized: "body_metrics_chart_date"), pt.date),
                                y: .value(valueLabel, pt.value)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(ModernChartStyle.lineAreaGradient(for: color))
                        }
                        ForEach(points) { pt in
                            LineMark(
                                x: .value(String(localized: "body_metrics_chart_date"), pt.date),
                                y: .value(valueLabel, pt.value)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(color)
                            .lineStyle(ModernChartStyle.lineStroke())
                            PointMark(
                                x: .value(String(localized: "body_metrics_chart_date"), pt.date),
                                y: .value(valueLabel, pt.value)
                            )
                            .foregroundStyle(color)
                            .symbolSize(22)
                        }
                    }
                }
            }
            .frame(height: 160)
            .chartYAxisLabel(unit, position: .trailing)
            .modernChartDateValueAxes(dateDesiredCount: 4)
            Text(String(localized: "body_metrics_chart_x_axis_note"))
                .font(AppTheme.captionTypographyFont)
                .foregroundStyle(AppTheme.secondaryText)
        }
        .padding(.vertical, 4)
    }

    private func reload() {
        loadError = nil
        do {
            items = try BodyMeasurementRepository(modelContext: modelContext).fetchAllSortedByDate()
        } catch {
            loadError = error.localizedDescription
            items = []
        }
    }

    private func deleteAt(offsets: IndexSet) {
        let repo = BodyMeasurementRepository(modelContext: modelContext)
        for i in offsets {
            guard i < items.count else { continue }
            try? repo.delete(items[i])
        }
        reload()
    }
}

// MARK: - Edit Sheet

private struct BodyMeasurementEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let weightUnit: String
    let onSaved: () -> Void

    @State private var measuredAt = Date()
    @State private var weightText = ""
    @State private var bodyFatText = ""
    @State private var note = ""
    @State private var saveError: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(String(localized: "body_metrics_date"), selection: $measuredAt, displayedComponents: [.date, .hourAndMinute])
                }
                Section {
                    TextField(
                        weightUnit == "lb"
                            ? String(localized: "body_metrics_weight_lb")
                            : String(localized: "body_metrics_weight_kg"),
                        text: $weightText
                    )
                    .keyboardType(.decimalPad)
                    TextField(String(localized: "body_metrics_bodyfat_optional"), text: $bodyFatText)
                        .keyboardType(.decimalPad)
                } header: {
                    Text(String(localized: "body_metrics_section_values"))
                }
                Section {
                    TextField(String(localized: "body_metrics_memo_optional"), text: $note, axis: .vertical)
                        .lineLimit(2...4)
                }
                if let saveError {
                    Section {
                        Text(saveError)
                            .foregroundStyle(AppTheme.destructive)
                            .font(AppTheme.captionTypographyFont)
                    }
                }
            }
            .navigationTitle(String(localized: "body_metrics_add_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "body_metrics_cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "body_metrics_save")) { save() }
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.accent)
                        .disabled(!canSave)
                }
            }
        }
    }

    private var canSave: Bool {
        let w = parsedWeightKg()
        let f = parsedBodyFat()
        return w != nil || f != nil
    }

    private func parsedWeightKg() -> Double? {
        let t = weightText.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty, let v = Double(t), v > 0 else { return nil }
        if weightUnit == "lb" {
            return v / 2.204_622_6218
        }
        return v
    }

    private func parsedBodyFat() -> Double? {
        let t = bodyFatText.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty, let v = Double(t), v > 0, v < 80 else { return nil }
        return v
    }

    private func save() {
        saveError = nil
        let w = parsedWeightKg()
        let f = parsedBodyFat()
        guard w != nil || f != nil else {
            saveError = String(localized: "body_metrics_validation_required")
            return
        }
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let m = BodyMeasurement(
            measuredAt: measuredAt,
            weightKg: w,
            bodyFatPercent: f,
            note: trimmedNote.isEmpty ? nil : trimmedNote
        )
        do {
            try BodyMeasurementRepository(modelContext: modelContext).insert(m)
            onSaved()
            dismiss()
        } catch {
            saveError = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        BodyMetricsView()
    }
    .modelContainer(for: BodyMeasurement.self, inMemory: true)
}
