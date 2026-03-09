// File: Modules/History/HistoryListViewModel.swift

import Foundation
import SwiftData

@Observable
final class HistoryListViewModel {
    var sessions: [WorkoutSession] = []
    var isLoading = false
    var errorMessage: String?

    private let workoutRepository: WorkoutRepositoryProtocol

    init(workoutRepository: WorkoutRepositoryProtocol) {
        self.workoutRepository = workoutRepository
    }

    func load() {
        isLoading = true
        errorMessage = nil
        do {
            sessions = try workoutRepository.fetchRecentSessions(limit: 50)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
