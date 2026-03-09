// File: Components/SetRowView.swift

import SwiftUI

struct SetRowView: View {
    let orderIndex: Int
    @Binding var weight: String
    @Binding var reps: String
    @Binding var isCompleted: Bool
    var onCompleteToggle: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Text("セット\(orderIndex + 1)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .leading)

            TextField("kg", text: $weight)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .frame(width: 70)

            TextField("回", text: $reps)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .frame(width: 60)

            Toggle("", isOn: $isCompleted)
                .labelsHidden()
                .onChange(of: isCompleted) { _, newValue in
                    if newValue { onCompleteToggle?() }
                }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    struct Holder: View {
        @State var w = "40"
        @State var r = "10"
        @State var done = false
        var body: some View {
            SetRowView(orderIndex: 0, weight: $w, reps: $r, isCompleted: $done)
                .padding()
        }
    }
    return Holder()
}
