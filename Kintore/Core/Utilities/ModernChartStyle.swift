import SwiftUI
import Charts

/// 統計・成長タブの Swift Charts 向け共有スタイル（軸・ライン・エリア）。
enum ModernChartStyle {
    static let lineStrokeWidth: CGFloat = 2.5

    static func lineStroke() -> StrokeStyle {
        StrokeStyle(lineWidth: lineStrokeWidth, lineCap: .round, lineJoin: .round)
    }

    /// ライン下のグラデーション塗り（ヘルスケア系アプリ寄せのソフトフィル）
    static func lineAreaGradient(for accent: Color) -> LinearGradient {
        LinearGradient(
            colors: [accent.opacity(0.26), accent.opacity(0.03)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    fileprivate static var gridLineSubtle: StrokeStyle {
        StrokeStyle(lineWidth: 0.5)
    }
}

extension View {
    /// 日付 X 軸＋数値 Y 軸（細グリッド・caption2）
    func modernChartDateValueAxes(
        dateDesiredCount: Int = 5,
        yAxisDesiredCount: Int = 4
    ) -> some View {
        self
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: dateDesiredCount)) { _ in
                    AxisGridLine(stroke: ModernChartStyle.gridLineSubtle)
                        .foregroundStyle(Color.primary.opacity(0.08))
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        .font(.caption2)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: yAxisDesiredCount)) { _ in
                    AxisGridLine(stroke: ModernChartStyle.gridLineSubtle)
                        .foregroundStyle(Color.primary.opacity(0.06))
                    AxisValueLabel()
                        .font(.caption2)
                        .foregroundStyle(AppTheme.tertiaryText)
                }
            }
    }

    /// 月次バー（`unit: .month`）向け
    func modernChartMonthBarAxes(yAxisDesiredCount: Int = 4) -> some View {
        self
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { _ in
                    AxisGridLine(stroke: ModernChartStyle.gridLineSubtle)
                        .foregroundStyle(Color.primary.opacity(0.08))
                    AxisValueLabel(format: .dateTime.month(.abbreviated), centered: true)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: yAxisDesiredCount)) { _ in
                    AxisGridLine(stroke: ModernChartStyle.gridLineSubtle)
                        .foregroundStyle(Color.primary.opacity(0.06))
                    AxisValueLabel()
                        .font(.caption2)
                        .foregroundStyle(AppTheme.tertiaryText)
                }
            }
    }

    /// 週始まり・日付ラベル（週次バー・週次折れ線・スパークライン）
    func modernChartWeekDateAxes(
        dateDesiredCount: Int = 6,
        yAxisDesiredCount: Int = 4
    ) -> some View {
        self
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: dateDesiredCount)) { _ in
                    AxisGridLine(stroke: ModernChartStyle.gridLineSubtle)
                        .foregroundStyle(Color.primary.opacity(0.08))
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day(), centered: true)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: yAxisDesiredCount)) { _ in
                    AxisGridLine(stroke: ModernChartStyle.gridLineSubtle)
                        .foregroundStyle(Color.primary.opacity(0.06))
                    AxisValueLabel()
                        .font(.caption2)
                        .foregroundStyle(AppTheme.tertiaryText)
                }
            }
    }
}
