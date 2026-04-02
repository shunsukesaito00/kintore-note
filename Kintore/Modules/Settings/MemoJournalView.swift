// File: Modules/Settings/MemoJournalView.swift
// 自由メモの検索で過去のコンディション記録を振り返る。

import SwiftUI
import SwiftData

struct MemoJournalView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var allEntries: [MemoJournalEntry] = []
    @State private var searchText = ""
    @State private var loadError: String?

    private var filteredEntries: [MemoJournalEntry] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return allEntries }
        return allEntries.filter { entry in
            (entry.freeMemo ?? "").localizedStandardContains(q)
                || entry.exerciseName.localizedStandardContains(q)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            if let loadError {
                Text(loadError)
                    .font(AppTheme.captionTypographyFont)
                    .foregroundStyle(AppTheme.destructive)
                    .padding()
            } else if allEntries.isEmpty {
                emptyState
            } else if filteredEntries.isEmpty {
                noMatchState
            } else {
                List {
                    ForEach(filteredEntries) { entry in
                        NavigationLink {
                            SessionDetailView(sessionId: entry.sessionId)
                        } label: {
                            memoJournalRow(entry: entry)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .appTabRootChrome()
        .navigationTitle(String(localized: "memo_journal_title"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { reload() }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppTheme.secondaryText)
            TextField(String(localized: "memo_journal_search_placeholder"), text: $searchText)
                .textFieldStyle(.plain)
        }
        .padding(AppTheme.spacingSM)
        .background(AppTheme.memoInputCellFill)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.inputCornerRadius))
        .padding(.horizontal, AppTheme.spacingLG)
        .padding(.vertical, AppTheme.spacingMD)
    }

    private func memoJournalRow(entry: MemoJournalEntry) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(AppFormatters.formatDateWithWeekday(entry.sessionDate))
                    .font(AppTheme.captionTypographyFont)
                    .foregroundStyle(AppTheme.secondaryText)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.tertiaryText)
            }
            Text(entry.exerciseName)
                .font(AppTheme.bodySemiboldFont)
                .foregroundStyle(AppTheme.primaryText)
            if let m = entry.freeMemo, !m.isEmpty {
                Text(m)
                    .font(AppTheme.bodySecondaryFont)
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(3)
            }
        }
        .padding(.vertical, 4)
    }

    private var emptyState: some View {
        VStack(spacing: AppTheme.spacingMD) {
            Spacer()
            Image(systemName: "note.text")
                .font(.largeTitle)
                .foregroundStyle(AppTheme.tertiaryText)
            Text(String(localized: "memo_journal_empty"))
                .font(AppTheme.bodySecondaryFont)
                .foregroundStyle(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noMatchState: some View {
        VStack(spacing: AppTheme.spacingMD) {
            Spacer()
            Text(String(localized: "memo_journal_no_match"))
                .font(AppTheme.bodySecondaryFont)
                .foregroundStyle(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func reload() {
        loadError = nil
        do {
            let sessions = try WorkoutRepository(modelContext: modelContext).fetchRecentSessions(limit: 400, before: nil)
            allEntries = MemoJournalService.entries(from: sessions)
        } catch {
            loadError = error.localizedDescription
            allEntries = []
        }
    }
}

#Preview {
    NavigationStack {
        MemoJournalView()
    }
    .modelContainer(for: [WorkoutSession.self, WorkoutExercise.self, MemoTag.self], inMemory: true)
}
