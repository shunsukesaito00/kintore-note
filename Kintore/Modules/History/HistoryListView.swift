import SwiftUI
import SwiftData

private enum HistoryListTimeFormatters {
    static let sessionTime: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.locale = Locale.current
        return f
    }()
}

struct HistoryListView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(AppTheme.weightUnitStorageKey) private var weightUnit: String = "kg"
    @State private var viewModel: HistoryListViewModel?
    @State private var selectedDate: Date = Date()
    @State private var selectedBodyPart: String = ""
    @State private var selectedDaySessions: [WorkoutSession] = []

    private let calendar = Calendar.current

    var body: some View {
        Group {
            if let vm = viewModel {
                historyContent(vm: vm)
            } else {
                ProgressView(String(localized: "home_loading"))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(String(localized: "nav_history_title"))
        .navigationBarTitleDisplayMode(.inline)
        .appTabRootChrome()
        .onAppear { createViewModelAndLoadIfNeeded() }
    }

    @ViewBuilder
    private func historyContent(vm: HistoryListViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.spacingLG) {
                bodyPartFilterRow(vm: vm)
                    .padding(.horizontal)

                streakBanner(vm: vm)
                    .padding(.horizontal)

                CalendarView(
                    onDaySelected: {
                        selectedDate = $0
                        refreshSelectedDay(vm: vm)
                    },
                    selectedBodyPart: selectedBodyPart,
                    selectedDate: selectedDate
                )

                selectedDaySection(vm: vm)
                    .padding(.horizontal)

                historyTimelineSection(vm: vm)
                    .padding(.horizontal)
            }
            .padding(.vertical, AppTheme.spacingMD)
        }
    }

    @ViewBuilder
    private func streakBanner(vm: HistoryListViewModel) -> some View {
        if vm.streakWeeks > 0 {
            HStack(spacing: AppTheme.spacingSM) {
                Image(systemName: "flame.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
                Text(String(format: String(localized: "history_streak_status"), vm.streakWeeks))
                    .font(AppTheme.bodyTypographyFont)
                    .foregroundStyle(AppTheme.primaryText)
                Spacer(minLength: 0)
            }
            .padding(AppTheme.spacingMD)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.accentSoft.opacity(0.45))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                    .stroke(AppTheme.cardBorder, lineWidth: AppTheme.cardStrokeWidth)
            )
            .appSubtleElevatedShadow()
        }
    }

    @ViewBuilder
    private func historyTimelineSection(vm: HistoryListViewModel) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
            SectionHeaderView(title: String(localized: "history_timeline_title"))
            if vm.sessions.isEmpty && !vm.isLoading {
                Text(String(localized: "history_empty_all"))
                    .font(AppTheme.bodySecondaryFont)
                    .foregroundStyle(AppTheme.secondaryText)
                    .padding(.vertical, AppTheme.spacingMD)
            } else {
                ForEach(Array(vm.sessions.enumerated()), id: \.element.id) { index, session in
                    let showDateHeader = index == 0
                        || !calendar.isDate(vm.sessions[index - 1].startedAt, inSameDayAs: session.startedAt)
                    VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                        if showDateHeader {
                            Text(AppFormatters.formatDateWithWeekday(session.startedAt))
                                .font(AppTheme.subheadlineFont.weight(.semibold))
                                .foregroundStyle(AppTheme.secondaryText)
                                .padding(.top, index == 0 ? 0 : AppTheme.spacingSM)
                        }
                        NavigationLink(value: session.id) {
                            compactSessionCard(session)
                        }
                        .buttonStyle(.plain)
                    }
                    .onAppear {
                        if index == vm.sessions.count - 1 {
                            vm.loadMore()
                        }
                    }
                }
                if vm.isLoadingMore {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.spacingMD)
                }
            }
        }
    }

    @ViewBuilder
    private func bodyPartFilterRow(vm: HistoryListViewModel) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.spacingSM) {
                ForEach(calendarBodyParts, id: \.self) { bodyPart in
                    let label = bodyPart.isEmpty ? String(localized: "history_filter_all") : bodyPart
                    let isActive = selectedBodyPart == bodyPart
                    Button {
                        selectedBodyPart = bodyPart
                        refreshSelectedDay(vm: vm)
                    } label: {
                        Text(label)
                            .font(.subheadline.weight(isActive ? .semibold : .regular))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(isActive ? AppTheme.accent : AppTheme.memoInputCellFill)
                            .foregroundStyle(isActive ? .white : AppTheme.primaryText)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private func selectedDaySection(vm: HistoryListViewModel) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
            SectionHeaderView(title: String(localized: "history_selected_day_section"))
            Text(AppFormatters.formatDateWithWeekday(selectedDate))
                .font(AppTheme.bodySemiboldFont)
                .foregroundStyle(AppTheme.primaryText)

            if selectedDaySessions.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: AppTheme.spacingSM) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.title)
                            .foregroundStyle(AppTheme.tertiaryText)
                        Text(String(localized: "history_no_records_day"))
                            .font(AppTheme.bodySecondaryFont)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    .padding(.vertical, AppTheme.spacingXL)
                    Spacer()
                }
            } else {
                ForEach(selectedDaySessions, id: \.id) { session in
                    selectedDaySessionDetailBlock(session: session)
                }
            }
        }
    }

    @ViewBuilder
    private func selectedDaySessionDetailBlock(session: WorkoutSession) -> some View {
        NavigationLink(value: session.id) {
            historySessionCard(session)
        }
        .buttonStyle(.plain)
    }

    private func compactSessionCard(_ session: WorkoutSession) -> some View {
        historySessionCard(session)
    }

    // MARK: - Shared modern card (blue header + 2-col grid)

    private func historySessionCard(_ session: WorkoutSession) -> some View {
        let exercises = session.workoutExercises.sorted { $0.orderIndex < $1.orderIndex }
        let totalVolume = exercises.reduce(0.0) { total, we in
            total + we.sets.reduce(0.0) { $0 + VolumeCalculator.volume(weight: $1.weight, reps: $1.reps) }
        }
        let totalSets = exercises.reduce(0) { $0 + $1.sets.count }
        let dateText = AppFormatters.formatDateWithWeekday(session.startedAt)
        let durationText = session.durationSeconds.map { AppFormatters.formatDuration(seconds: $0) } ?? "—"

        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: AppTheme.spacingSM) {
                Text(dateText)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                Text(durationText)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
                HStack(spacing: 6) {
                    historyChip(icon: "list.number", text: "\(totalSets)")
                    historyChip(icon: "scalemass", text: "\(AppFormatters.formatWeightNumber(totalVolume))\(weightUnit)")
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(AppTheme.accent)

            VStack(spacing: 0) {
                ForEach(Array(exercises.enumerated()), id: \.element.id) { idx, we in
                    historyExerciseBlock(we)
                    if idx < exercises.count - 1 {
                        Divider().padding(.horizontal, 14)
                    }
                }
            }
            .padding(.vertical, 6)
        }
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppTheme.cardBorder, lineWidth: AppTheme.cardStrokeWidth)
        )
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    private func historyChip(icon: String, text: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .bold))
            Text(text)
                .font(.system(size: 11, weight: .bold, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(.white.opacity(0.2))
        .clipShape(Capsule())
    }

    private func historyExerciseBlock(_ we: WorkoutExercise) -> some View {
        let allSets = we.sets.sorted { $0.orderIndex < $1.orderIndex }
        let sets = allSets.filter { historySetHasData($0) }
        let exKind = ExerciseKind(stored: we.exercise?.exerciseKind)
        let vol = sets.reduce(0.0) { $0 + VolumeCalculator.volume(weight: $1.weight, reps: $1.reps) }
        let cols = [GridItem(.flexible(), spacing: 4), GridItem(.flexible(), spacing: 4)]

        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(we.exercise?.name ?? "—")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.primaryText)
                    .lineLimit(1)
                Spacer()
                if exKind.usesLoadVolume, vol > 0 {
                    Text("\(AppFormatters.formatWeightNumber(vol))\(weightUnit)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.accent)
                }
            }
            if !sets.isEmpty {
                LazyVGrid(columns: cols, alignment: .leading, spacing: 4) {
                    ForEach(Array(sets.enumerated()), id: \.element.id) { idx, s in
                        historySetCell(idx: idx + 1, set: s, kind: exKind)
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    private func historySetHasData(_ s: WorkoutSet) -> Bool {
        (s.weight ?? 0) > 0 || (s.reps ?? 0) > 0
            || (s.durationSeconds ?? 0) > 0 || (s.distanceMeters ?? 0) > 0
    }

    private func historySetCell(idx: Int, set: WorkoutSet, kind: ExerciseKind) -> some View {
        HStack(spacing: 6) {
            Text("\(idx)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(AppTheme.accent)
                .clipShape(Circle())

            Group {
                switch kind {
                case .strength, .weightedBodyweight:
                    let w = set.weight.map { AppFormatters.formatWeightNumericOnly($0) } ?? "—"
                    let r = set.reps.map { "\($0)" } ?? "—"
                    Text("\(w)\(weightUnit) × \(r)回")
                case .time:
                    Text("\(set.durationSeconds.map { "\($0)" } ?? "—")\(String(localized: "unit_seconds"))")
                case .cardio:
                    let parts = [
                        set.distanceMeters.map { AppFormatters.formatWeightNumber($0 / 1000) + String(localized: "unit_km") },
                        set.durationSeconds.map { "\($0)\(String(localized: "unit_seconds"))" }
                    ].compactMap { $0 }
                    Text(parts.joined(separator: " / "))
                }
            }
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundStyle(AppTheme.primaryText)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 3)
        .padding(.horizontal, 6)
        .background(AppTheme.accentSoft.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func createViewModelAndLoadIfNeeded() {
        if viewModel == nil {
            let vm = HistoryListViewModel(
                workoutRepository: WorkoutRepository(modelContext: modelContext),
                statsService: WorkoutStatsService(modelContext: modelContext)
            )
            viewModel = vm
            vm.load()
            refreshSelectedDay(vm: vm)
        } else {
            viewModel?.load()
            if let viewModel {
                refreshSelectedDay(vm: viewModel)
            }
        }
    }

    private func refreshSelectedDay(vm: HistoryListViewModel) {
        let sessions = vm.fetchSessions(on: selectedDate, bodyPart: selectedBodyPart)
        selectedDaySessions = sessions.sorted { $0.startedAt < $1.startedAt }
    }
}

#Preview {
    NavigationStack {
        HistoryListView()
    }
    .modelContainer(for: [WorkoutSession.self], inMemory: true)
}
