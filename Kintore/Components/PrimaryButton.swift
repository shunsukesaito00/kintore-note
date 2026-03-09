// File: Components/PrimaryButton.swift

import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isDisabled: Bool = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .disabled(isDisabled)
    }
}

#Preview {
    PrimaryButton(title: "今日のワークアウトを記録", action: {})
        .padding()
}
