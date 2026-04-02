// File: Core/Repositories/BodyMeasurementRepository.swift

import Foundation
import SwiftData

protocol BodyMeasurementRepositoryProtocol {
    func fetchAllSortedByDate() throws -> [BodyMeasurement]
    func insert(_ measurement: BodyMeasurement) throws
    func delete(_ measurement: BodyMeasurement) throws
}

final class BodyMeasurementRepository: BodyMeasurementRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAllSortedByDate() throws -> [BodyMeasurement] {
        let descriptor = FetchDescriptor<BodyMeasurement>(
            sortBy: [SortDescriptor(\.measuredAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func insert(_ measurement: BodyMeasurement) throws {
        modelContext.insert(measurement)
        try modelContext.save()
    }

    func delete(_ measurement: BodyMeasurement) throws {
        modelContext.delete(measurement)
        try modelContext.save()
    }
}
