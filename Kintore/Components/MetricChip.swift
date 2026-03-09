// File: Components/MetricChip.swift

import SwiftUI

struct MetricChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.tertiarySystemFill))
            .clipShape(Capsule())
    }
}

#Preview {
    HStack {
        MetricChip(text: "3/6")
        MetricChip(text: "5種目")
    }
}
