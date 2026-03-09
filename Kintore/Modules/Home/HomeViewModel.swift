// File: Modules/Home/HomeViewModel.swift

import Foundation
import SwiftData

@Observable
final class HomeViewModel {
    var recentSessions: [WorkoutSession] = []
    var isLoading = false
    var errorMessage: String?

    private let workoutRepository: WorkoutRepositoryProtocol

    init(workoutRepository: WorkoutRepositoryProtocol) {
        self.workoutRepository = workoutRepository
    }

    func loadRecentSessions() {
        isLoading = true
        errorMessage = nil
        do {
            recentSessions = try workoutRepository.fetchRecentSessions(limit: 5)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
