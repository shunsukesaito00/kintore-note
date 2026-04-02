// File: Modules/Settings/PlateCalculatorView.swift
// バー＋プレートの合計が目標になるよう片側の組み合わせを表示（貪欲・左右対称前提）。

import SwiftUI

enum PlateCalculatorLogic {
    struct Result {
        var perSide: [(kg: Double, count: Int)]
        var totalKg: Double
    }

    /// 左右対称。各プレートは何枚でも可。
    static func solve(targetTotalKg: Double, barKg: Double, platesKg: [Double]) -> Result? {
        let perSide = (targetTotalKg - barKg) / 2
        guard perSide >= -0.0001 else { return nil }
        let sorted = Array(Set(platesKg.filter { $0 > 0 })).sorted(by: >)
        guard !sorted.isEmpty else { return nil }
        var remaining = perSide
        var out: [(Double, Int)] = []
        for p in sorted {
            let n = Int(floor(remaining / p + 0.000_000_1))
            if n > 0 {
                out.append((p, n))
                remaining -= Double(n) * p
            }
        }
        guard abs(remaining) < 0.01 else { return nil }
        let sideSum = out.reduce(0.0) { $0 + $1.0 * Double($1.1) }
        return Result(perSide: out.map { (kg: $0.0, count: $0.1) }, totalKg: barKg + 2 * sideSum)
    }
}

struct PlateCalculatorView: View {
    @AppStorage("kintore.plate_bar_kg") private var barKgString: String = "20"
    @AppStorage("kintore.plate_inventory_kg") private var inventoryString: String = "25,20,15,10,5,2.5,1.25,0.5"
    @State private var targetString = ""

    var body: some View {
        Form {
            Section {
                TextField(String(localized: "plate_calc_target"), text: $targetString)
                    .keyboardType(.decimalPad)
                TextField(String(localized: "plate_calc_bar"), text: $barKgString)
                    .keyboardType(.decimalPad)
                TextField(String(localized: "plate_calc_inventory"), text: $inventoryString, axis: .vertical)
                    .lineLimit(2...4)
            } footer: {
                Text(String(localized: "plate_calc_footer"))
            }

            if let result = computedResult() {
                Section(String(localized: "plate_calc_per_side")) {
                    ForEach(Array(result.perSide.enumerated()), id: \.offset) { _, item in
                        HStack {
                            Text("\(formatKg(item.kg)) \(String(localized: "weight_unit_symbol_kg"))")
                            Spacer()
                            Text("× \(item.count)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    Text(String(format: String(localized: "plate_calc_effective_total_format"), formatKg(result.totalKg)))
                        .font(AppTheme.bodySemiboldFont)
                }
            } else if !targetString.trimmingCharacters(in: .whitespaces).isEmpty {
                Section {
                    Text(String(localized: "plate_calc_no_match"))
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .tint(AppTheme.accent)
        .appTabRootChrome()
        .navigationTitle(String(localized: "plate_calc_title"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func computedResult() -> PlateCalculatorLogic.Result? {
        let t = Double(targetString.replacingOccurrences(of: ",", with: "."))
        let b = Double(barKgString.replacingOccurrences(of: ",", with: "."))
        guard let target = t, let bar = b, target > 0, bar >= 0 else { return nil }
        let plates = inventoryString
            .split(separator: ",")
            .compactMap { Double($0.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")) }
        return PlateCalculatorLogic.solve(targetTotalKg: target, barKg: bar, platesKg: plates)
    }

    private func formatKg(_ v: Double) -> String {
        AppFormatters.formatWeightNumber(v)
    }
}

#Preview {
    NavigationStack {
        PlateCalculatorView()
    }
}
