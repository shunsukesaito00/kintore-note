// File: Core/Utilities/VolumeCalculator.swift
// 1 セットあたりの volume（総挙上 = weight × reps）の唯一の計算元。PR・集計・表示はすべてここを参照する。

import Foundation

enum VolumeCalculator {

    /// 1 セットの volume = weight × reps。無効（nil または 0 以下）の場合は 0。
    /// - Parameter weight: 重量（kg）。nil または 0 以下は無効。
    /// - Parameter reps: 回数。nil または 0 以下は無効。
    /// - Returns: 有効な場合は weight * reps、それ以外は 0。
    static func volume(weight: Double?, reps: Int?) -> Double {
        guard let w = weight, let r = reps, w > 0, r > 0 else { return 0 }
        return w * Double(r)
    }

    /// Epley formula: estimated 1RM = weight * (1 + reps / 30).
    /// Returns nil if inputs are invalid or reps == 1 (already actual 1RM).
    static func estimated1RM(weight: Double?, reps: Int?) -> Double? {
        guard let w = weight, let r = reps, w > 0, r > 1 else {
            if let w = weight, w > 0, let r = reps, r == 1 { return w }
            return nil
        }
        return w * (1.0 + Double(r) / 30.0)
    }
}
