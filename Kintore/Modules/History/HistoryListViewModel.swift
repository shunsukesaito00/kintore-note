// File: Modules/History/HistoryListViewModel.swift

import Foundation
import SwiftData

@Observable
final class HistoryListViewModel {
    var sessions: [WorkoutSession] = []
    /// `WorkoutStatsService.currentStreakWeeks` と同じ（週1回以上で連続週）
    var streakWeeks: Int = 0
    var isLoading = false
    var isLoadingMore = false
    var hasMore = true
    var errorMessage: String?

    private let pageSize = 100
    private let workoutRepository: WorkoutRepositoryProtocol
    private let statsService: WorkoutStatsService

    init(workoutRepository: WorkoutRepositoryProtocol, statsService: WorkoutStatsService) {
        self.workoutRepository = workoutRepository
        self.statsService = statsService
    }

    func load() {
        isLoading = true
        errorMessage = nil
        hasMore = true
        do {
            let fetched = try workoutRepository.fetchRecentSessions(limit: pageSize, before: nil)
            sessions = fetched.filter { $0.endedAt != nil }
            hasMore = fetched.count >= pageSize
            streakWeeks = (try? statsService.currentStreakWeeks()) ?? 0
        } catch {
            errorMessage = error.localizedDescription
            streakWeeks = 0
        }
        isLoading = false
    }

    func loadMore() {
        guard hasMore, !isLoadingMore, let last = sessions.last else { return }
        isLoadingMore = true
        do {
            let next = try workoutRepository.fetchRecentSessions(limit: pageSize, before: last.startedAt)
            sessions.append(contentsOf: next.filter { $0.endedAt != nil })
            hasMore = next.count >= pageSize
        } catch {
            hasMore = false
        }
        isLoadingMore = false
    }

    func deleteSessions(at offsets: IndexSet) {
        for index in offsets {
            guard index < sessions.count else { continue }
            try? workoutRepository.deleteSession(sessions[index])
        }
        load()
    }

    func fetchSessions(on date: Date, bodyPart: String?) -> [WorkoutSession] {
        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: date)
        let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
        do {
            let sessions = try workoutRepository.fetchSessions(from: dayStart, to: dayEnd)
            guard let bodyPart, !bodyPart.isEmpty else { return sessions }
            return sessions.filter { session in
                session.workoutExercises.contains { $0.exercise?.bodyPartTag == bodyPart }
            }
        } catch {
            return []
        }
    }
}
