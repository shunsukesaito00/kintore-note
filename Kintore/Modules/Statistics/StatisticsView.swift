import SwiftUI
import SwiftData

struct StatisticsView: View {
    var body: some View {
        GrowthDashboardView()
    }
}

#Preview {
    NavigationStack {
        StatisticsView()
    }
    .modelContainer(for: [WorkoutSession.self, WorkoutExercise.self, WorkoutSet.self, Exercise.self, PersonalRecord.self], inMemory: true)
}
