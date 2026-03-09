// File: Core/Repositories/MemoTagRepository.swift

import Foundation
import SwiftData

protocol MemoTagRepositoryProtocol {
    func fetchAll() throws -> [MemoTag]
}

final class MemoTagRepository: MemoTagRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll() throws -> [MemoTag] {
        var descriptor = FetchDescriptor<MemoTag>(sortBy: [SortDescriptor(\.sortOrder)])
        descriptor.fetchLimit = 0
        return try modelContext.fetch(descriptor)
    }
}
