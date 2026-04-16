import SwiftUI

private struct HomeDayLogShareImagePayload: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct HomeMemoBlueHeader: View {
    @Bindable var viewModel: HomeViewModel
    var onGoalTap: (() -> Void)?

    private var pad: CGFloat { AppTheme.screenHorizontalPadding }

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                HomeMemoCalendarBlock(viewModel: viewModel)

                HomeGoalRingSidebar(
                    weekCount: viewModel.weekSessionCount,
                    monthCount: viewModel.sessionsInDisplayedMonthCount,
                    weeklyGoal: viewModel.weeklyWorkoutGoalSessions,
                    lastSessionText: viewModel.lastCompletedSessionDateText,
                    onGoalTap: onGoalTap
                )
            }
        }
        .padding(AppTheme.cardContentPadding)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppTheme.cardBorder, lineWidth: AppTheme.cardStrokeWidth)
        )
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        .padding(.horizontal, pad)
    }
}

// MARK: - Calendar

private struct HomeMemoCalendarBlock: View {
    @Bindable var viewModel: HomeViewModel
    private let cal = Calendar.current

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Button { shiftMonth(-1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AppTheme.accent)
                        .frame(width: 32, height: 32)
                        .background(AppTheme.accentSoft)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                Spacer()
                Text(monthYearString(viewModel.calendarMonth))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.primaryText)
                Spacer()
                Button { shiftMonth(1) } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AppTheme.accent)
                        .frame(width: 32, height: 32)
                        .background(AppTheme.accentSoft)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            let flat = daysInMonthGrid()
            let rowCount = flat.isEmpty ? 0 : (flat.count + 6) / 7

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 4) {
                ForEach(weekdaySymbols(), id: \.self) { s in
                    Text(s)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(AppTheme.tertiaryText)
                        .frame(height: 20)
                }
                ForEach(0..<(rowCount * 7), id: \.self) { idx in
                    if idx < flat.count, flat[idx] > 0 {
                        dayCell(day: flat[idx])
                    } else {
                        Color.clear.frame(height: 34)
                    }
                }
            }
        }
    }

    private func dayCell(day: Int) -> some View {
        let isTraining = viewModel.trainingDaysInCalendarMonth.contains(day)
        let dayStart = dayStartFor(month: viewModel.calendarMonth, day: day)
        let isSelected = cal.isDate(dayStart, inSameDayAs: viewModel.selectedDate)
        let isToday = cal.isDateInToday(dayStart)

        return Button {
            viewModel.selectDate(dayStart)
        } label: {
            ZStack {
                if isSelected {
                    Circle()
                        .fill(AppTheme.accent)
                        .frame(width: 32, height: 32)
                } else if isToday {
                    Circle()
                        .fill(AppTheme.accentSoft)
                        .frame(width: 32, height: 32)
                }

                Text("\(day)")
                    .font(.system(size: 13, weight: isSelected || isToday ? .bold : .medium, design: .rounded))
                    .foregroundStyle(isSelected ? .white : AppTheme.primaryText)

                if isTraining && !isSelected {
                    Circle()
                        .fill(AppTheme.accent)
                        .frame(width: 5, height: 5)
                        .offset(y: 13)
                }
            }
            .frame(height: 34)
        }
        .buttonStyle(.plain)
    }

    private func shiftMonth(_ delta: Int) {
        guard let d = cal.date(byAdding: .month, value: delta, to: viewModel.calendarMonth) else { return }
        viewModel.setCalendarMonth(d)
    }

    private func monthYearString(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "yyyy年M月"
        return f.string(from: date)
    }

    private func weekdaySymbols() -> [String] {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        return f.shortWeekdaySymbols
    }

    private func daysInMonthGrid() -> [Int] {
        guard let range = cal.range(of: .day, in: .month, for: viewModel.calendarMonth),
              let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: viewModel.calendarMonth)) else { return [] }
        let leading = (cal.component(.weekday, from: monthStart) - cal.firstWeekday + 7) % 7
        var days = [Int](repeating: 0, count: leading)
        for d in range { days.append(d) }
        return days
    }

    private func dayStartFor(month: Date, day: Int) -> Date {
        var c = cal.dateComponents([.year, .month], from: month)
        c.day = day
        return cal.date(from: c) ?? month
    }
}

// MARK: - Goal ring sidebar (right of calendar)

private struct HomeGoalRingSidebar: View {
    let weekCount: Int
    let monthCount: Int
    let weeklyGoal: Int
    let lastSessionText: String?
    var onGoalTap: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            if weeklyGoal > 0 {
                Spacer(minLength: 0)
                ringItem(label: "今週", count: weekCount, goal: weeklyGoal)
                Spacer(minLength: 8)
                ringItem(label: "今月", count: monthCount, goal: weeklyGoal * 4)
                Spacer(minLength: 8)
                Button { onGoalTap?() } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.accent)
                        .frame(width: 28, height: 28)
                        .background(AppTheme.accentSoft)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("目標変更")
                Spacer(minLength: 0)
            } else {
                Spacer(minLength: 0)
                plainItem(value: "\(weekCount)", label: "今週")
                Spacer(minLength: 12)
                plainItem(value: "\(monthCount)", label: "今月")
                Spacer(minLength: 0)
            }
        }
        .frame(width: 80)
    }

    private func ringItem(label: String, count: Int, goal: Int) -> some View {
        let ratio = goal > 0 ? min(1.0, Double(count) / Double(goal)) : 0
        let met = count >= goal
        let size: CGFloat = 54
        let line: CGFloat = 5

        return VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(Color(uiColor: .systemGray5), lineWidth: line)
                Circle()
                    .trim(from: 0, to: ratio)
                    .stroke(
                        met ? AppTheme.accent : AppTheme.accent.opacity(0.75),
                        style: StrokeStyle(lineWidth: line, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: -1) {
                    Text("\(count)")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(met ? AppTheme.accent : AppTheme.primaryText)
                    Text("/\(goal)")
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.tertiaryText)
                }
            }
            .frame(width: size, height: size)

            Text(label)
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.primaryText)
        }
    }

    private func plainItem(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.primaryText)
            Text(label)
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.secondaryText)
        }
    }
}

struct HomeWeeklySummaryCard: View {
    @Bindable var viewModel: HomeViewModel
    let weightUnit: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMD) {
            SectionHeaderView(title: String(localized: "home_weekly_highlight"))

            HStack(spacing: 0) {
                weeklyStat(
                    icon: "flame.fill",
                    value: "\(viewModel.weekSessionCount)",
                    label: String(localized: "unit_times"),
                    delta: viewModel.weekSessionCount - viewModel.previousWeekSessionCount
                )
                Divider().frame(height: 48)
                weeklyStat(
                    icon: "scalemass.fill",
                    value: AppFormatters.formatWeightNumber(viewModel.weekTotalVolume),
                    label: weightUnit,
                    delta: nil,
                    volumeDelta: viewModel.weekTotalVolume - viewModel.previousWeekTotalVolume
                )
                Divider().frame(height: 48)
                VStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(viewModel.streakWeeks > 0 ? AppTheme.accent : AppTheme.tertiaryText)
                    Text("\(viewModel.streakWeeks)")
                        .font(AppTheme.numericEmphasisFont)
                        .foregroundStyle(AppTheme.primaryText)
                    Text(String(localized: "home_weekly_streak_label"))
                        .font(AppTheme.captionTypographyFont)
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, AppTheme.spacingSM)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                    .stroke(AppTheme.cardBorder, lineWidth: AppTheme.cardStrokeWidth)
            )
            .shadow(
                color: .black.opacity(AppTheme.cardShadowOpacity * 0.5),
                radius: AppTheme.cardShadowRadius * 0.55,
                x: 0,
                y: AppTheme.cardShadowY * 0.55
            )

        }
    }

    private func weeklyStat(icon: String, value: String, label: String, delta: Int? = nil, volumeDelta: Double? = nil) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(AppTheme.accent)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(AppTheme.numericEmphasisFont)
                    .foregroundStyle(AppTheme.primaryText)
                Text(label)
                    .font(AppTheme.captionTypographyFont)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            if let delta, delta != 0 {
                deltaLabel(value: delta > 0 ? "+\(delta)" : "\(delta)", isPositive: delta > 0)
            } else if let volumeDelta, abs(volumeDelta) > 0.1 {
                let formatted = AppFormatters.formatWeightNumber(abs(volumeDelta))
                deltaLabel(value: volumeDelta > 0 ? "+\(formatted)" : "-\(formatted)", isPositive: volumeDelta > 0)
            } else {
                Text(String(localized: "home_weekly_no_change"))
                    .font(.caption2)
                    .foregroundStyle(AppTheme.tertiaryText)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func deltaLabel(value: String, isPositive: Bool) -> some View {
        HStack(spacing: 2) {
            Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                .font(.caption2.weight(.bold))
            Text(value)
                .font(.caption2.weight(.medium))
        }
        .foregroundStyle(isPositive ? AppTheme.accent : AppTheme.destructive)
    }
}

struct HomeMemoDayLogSection: View {
    let sessions: [WorkoutSession]
    let weightUnit: String
    var sectionTitle: String = String(localized: "home_day_log_title")
    @State private var shareImage: HomeDayLogShareImagePayload?
    @State private var showPreview = false
    @State private var previewImage: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
            HStack {
                SectionHeaderView(title: sectionTitle)
                Spacer(minLength: 0)
                if !sessions.isEmpty {
                    Button {
                        HapticHelper.light()
                        previewImage = renderShareCard()
                        showPreview = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 12, weight: .semibold))
                            Text("共有")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(AppTheme.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppTheme.accentSoft)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            if sessions.isEmpty {
                Text(String(localized: "home_day_log_empty"))
                    .font(AppTheme.bodySecondaryFont)
                    .foregroundStyle(AppTheme.secondaryText)
                    .padding(.vertical, AppTheme.spacingMD)
            } else {
                VStack(spacing: AppTheme.spacingSM) {
                    ForEach(sessions, id: \.id) { session in
                        NavigationLink(value: session.id) {
                            compactSessionCard(session)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .sheet(isPresented: $showPreview) {
            dayLogSharePreviewSheet
        }
        .sheet(item: $shareImage) { payload in
            ShareSheet(activityItems: [payload.image], onDismiss: { shareImage = nil })
        }
    }

    @ViewBuilder
    private var dayLogSharePreviewSheet: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                VStack(spacing: 20) {
                    if let img = previewImage {
                        ScrollView {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 4)
                                .padding(.horizontal, 20)
                        }
                    }
                    Button {
                        if let img = previewImage {
                            shareImage = HomeDayLogShareImagePayload(image: img)
                        }
                        showPreview = false
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.body.weight(.semibold))
                            Text("シェアする")
                                .font(.body.weight(.bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            LinearGradient(
                                colors: [AppTheme.accent, AppTheme.accent.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 16)
            }
            .navigationTitle("ワークアウトログ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common_close")) { showPreview = false }
                }
            }
        }
        .presentationDetents([.large])
    }

    @MainActor
    private func renderShareCard() -> UIImage? {
        let card = DayLogShareCardView(sessions: sessions, weightUnit: weightUnit)
        let renderer = ImageRenderer(content: card)
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }

    private func compactSessionCard(_ session: WorkoutSession) -> some View {
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
                    logChip(icon: "list.number", text: "\(totalSets)")
                    logChip(icon: "scalemass", text: "\(AppFormatters.formatWeightNumber(totalVolume))\(weightUnit)")
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
                    logExerciseBlock(we)
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

    private func logChip(icon: String, text: String) -> some View {
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

    private func logExerciseBlock(_ we: WorkoutExercise) -> some View {
        let sets = we.sets.sorted { $0.orderIndex < $1.orderIndex }
        let exKind = ExerciseKind(stored: we.exercise?.exerciseKind)
        let vol = sets.reduce(0.0) { $0 + VolumeCalculator.volume(weight: $1.weight, reps: $1.reps) }

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

            logSetGrid(sets: sets, kind: exKind)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    private func setHasData(_ s: WorkoutSet) -> Bool {
        (s.weight ?? 0) > 0 || (s.reps ?? 0) > 0
            || (s.durationSeconds ?? 0) > 0 || (s.distanceMeters ?? 0) > 0
    }

    private func logSetGrid(sets: [WorkoutSet], kind: ExerciseKind) -> some View {
        let valid = sets.filter { setHasData($0) }
        let cols = [
            GridItem(.flexible(), spacing: 4),
            GridItem(.flexible(), spacing: 4)
        ]
        return LazyVGrid(columns: cols, alignment: .leading, spacing: 4) {
            ForEach(Array(valid.enumerated()), id: \.element.id) { idx, s in
                logSetCell(idx: idx + 1, set: s, kind: kind)
            }
        }
    }

    private func logSetCell(idx: Int, set: WorkoutSet, kind: ExerciseKind) -> some View {
        let hasData = (set.weight ?? 0) > 0 || (set.reps ?? 0) > 0
            || (set.durationSeconds ?? 0) > 0 || (set.distanceMeters ?? 0) > 0

        return HStack(spacing: 6) {
            Text("\(idx)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(hasData ? AppTheme.accent : Color(uiColor: .systemGray4))
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
            .foregroundStyle(hasData ? AppTheme.primaryText : AppTheme.tertiaryText)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 3)
        .padding(.horizontal, 6)
        .background(hasData ? AppTheme.accentSoft.opacity(0.3) : Color(uiColor: .systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

// MARK: - Simple home (monthly goal & user menus)

struct HomeMonthlyGoalCard: View {
    let monthGoal: Int
    let monthCount: Int
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
            HStack {
                Text(String(localized: "home_monthly_goal_title"))
                    .font(AppTheme.bodyTypographyFont.weight(.semibold))
                Spacer()
                Button(action: onEdit) {
                    Text(String(localized: "home_monthly_goal_edit"))
                        .font(AppTheme.captionTypographyFont.weight(.semibold))
                }
                .buttonStyle(.plain)
            }
            if monthGoal > 0 {
                ProgressView(value: Double(min(monthCount, monthGoal)), total: Double(max(monthGoal, 1))) {
                    Text(String(format: String(localized: "home_monthly_goal_progress_format"), monthCount, monthGoal))
                        .font(AppTheme.captionTypographyFont)
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .tint(AppTheme.accent)
            } else {
                Text(String(localized: "home_monthly_goal_not_set"))
                    .font(AppTheme.captionTypographyFont)
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
        .padding(AppTheme.spacingMD)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                .stroke(AppTheme.cardBorder, lineWidth: AppTheme.cardStrokeWidth)
        )
    }
}

struct HomeUserMenuListSection: View {
    @Bindable var viewModel: HomeViewModel
    @AppStorage(AppTheme.weightUnitStorageKey) private var weightUnit: String = "kg"
    var onAddExercise: () -> Void
    var onTapMaxRecord: (Exercise) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMD) {
            HStack(alignment: .firstTextBaseline) {
                Text(String(localized: "home_user_menu_section_title"))
                    .font(AppTheme.bodyTypographyFont.weight(.semibold))
                Spacer(minLength: 8)
                Button {
                    onAddExercise()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppTheme.accent)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "home_user_menu_add_a11y"))
            }

            if viewModel.userMenuExercises.isEmpty {
                Button {
                    onAddExercise()
                } label: {
                    Text(String(localized: "home_user_menu_empty"))
                        .font(AppTheme.captionTypographyFont)
                        .foregroundStyle(AppTheme.accent)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.userMenuExercises.enumerated()), id: \.element.id) { index, ex in
                        if index > 0 {
                            Divider().opacity(0.35)
                        }
                        homeMenuRow(exercise: ex)
                    }
                }
            }
        }
        .padding(AppTheme.spacingMD)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                .stroke(AppTheme.cardBorder, lineWidth: AppTheme.cardStrokeWidth)
        )
    }

    @ViewBuilder
    private func homeMenuRow(exercise ex: Exercise) -> some View {
        let hasMax = viewModel.hasValidWeightDraft(for: ex.id)
        HStack(alignment: .center, spacing: AppTheme.spacingSM) {
            Toggle(isOn: Binding(
                get: { viewModel.selectedTodayExerciseIds.contains(ex.id) },
                set: { viewModel.setTodayExerciseSelected(ex.id, selected: $0) }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(ex.name)
                        .font(AppTheme.bodyTypographyFont)
                        .foregroundStyle(AppTheme.primaryText)
                    Text(ex.bodyPartTag)
                        .font(AppTheme.captionTypographyFont)
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .tint(AppTheme.accent)
            .accessibilityHint(String(localized: "home_user_menu_toggle_a11y_hint"))

            if hasMax {
                Text(maxDraftLabel(exerciseId: ex.id))
                    .font(AppTheme.captionTypographyFont.weight(.medium))
                    .foregroundStyle(AppTheme.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Button {
                onTapMaxRecord(ex)
            } label: {
                Text(String(localized: "home_max_record_button"))
                    .font(AppTheme.captionTypographyFont.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(!viewModel.selectedTodayExerciseIds.contains(ex.id))
            .accessibilityLabel(String(localized: "home_max_record_button"))
        }
        .padding(.vertical, AppTheme.spacingXS)
    }

    private func maxDraftLabel(exerciseId: UUID) -> String {
        let raw = (viewModel.weightDraftByExerciseId[exerciseId] ?? "")
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let v = Double(raw) else { return "—" }
        return "\(AppFormatters.formatWeightNumber(v))\(weightUnit)"
    }
}

// MARK: - Visual Share Card (rendered to image)

private struct DayLogShareCardView: View {
    let sessions: [WorkoutSession]
    let weightUnit: String

    private let cardWidth: CGFloat = 380

    private var dateLabel: String {
        sessions.first.map { AppFormatters.formatDateWithWeekday($0.startedAt) } ?? "—"
    }
    private var allExercises: [(WorkoutExercise, ExerciseKind)] {
        sessions.flatMap { s in
            s.workoutExercises.sorted { $0.orderIndex < $1.orderIndex }.map { we in
                (we, ExerciseKind(stored: we.exercise?.exerciseKind))
            }
        }
    }
    private var totalVolume: Double {
        allExercises.reduce(0) { t, pair in
            t + pair.0.sets.reduce(0.0) { $0 + VolumeCalculator.volume(weight: $1.weight, reps: $1.reps) }
        }
    }
    private var totalSets: Int {
        allExercises.reduce(0) { $0 + $1.0.sets.count }
    }
    private var durationText: String {
        let total = sessions.compactMap(\.durationSeconds).reduce(0, +)
        return total > 0 ? AppFormatters.formatDuration(seconds: total) : "—"
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            exerciseList
            footer
        }
        .frame(width: cardWidth)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var header: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 14, weight: .bold))
                Text("WORKOUT LOG")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .kerning(1.5)
                Spacer()
                Text(String(localized: "app_display_name"))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .opacity(0.7)
            }
            .foregroundStyle(.white)

            Text(dateLabel)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 16) {
                shareStatPill(icon: "clock", value: durationText)
                shareStatPill(icon: "list.number", value: "\(totalSets)セット")
                shareStatPill(icon: "scalemass", value: "\(AppFormatters.formatWeightNumber(totalVolume))\(weightUnit)")
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color(red: 0.22, green: 0.50, blue: 0.82), Color(red: 0.35, green: 0.65, blue: 0.95)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private func shareStatPill(icon: String, value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.white.opacity(0.2))
        .clipShape(Capsule())
    }

    private var exerciseList: some View {
        VStack(spacing: 0) {
            ForEach(Array(allExercises.enumerated()), id: \.offset) { idx, pair in
                let (we, kind) = pair
                shareExerciseRow(we: we, kind: kind)
                if idx < allExercises.count - 1 {
                    Rectangle()
                        .fill(Color(uiColor: .separator).opacity(0.3))
                        .frame(height: 0.5)
                        .padding(.horizontal, 20)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private func shareSetHasData(_ s: WorkoutSet) -> Bool {
        (s.weight ?? 0) > 0 || (s.reps ?? 0) > 0
            || (s.durationSeconds ?? 0) > 0 || (s.distanceMeters ?? 0) > 0
    }

    private func shareExerciseRow(we: WorkoutExercise, kind: ExerciseKind) -> some View {
        let sets = we.sets.sorted { $0.orderIndex < $1.orderIndex }.filter { shareSetHasData($0) }
        let vol = sets.reduce(0.0) { $0 + VolumeCalculator.volume(weight: $1.weight, reps: $1.reps) }
        let cols = [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)]

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(we.exercise?.name ?? "—")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color(uiColor: .label))
                Spacer()
                if kind.usesLoadVolume, vol > 0 {
                    Text("\(AppFormatters.formatWeightNumber(vol))\(weightUnit)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(red: 0.29, green: 0.56, blue: 0.85))
                }
            }

            LazyVGrid(columns: cols, spacing: 5) {
                ForEach(Array(sets.enumerated()), id: \.offset) { idx, s in
                    shareSetCell(idx: idx + 1, set: s, kind: kind)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    private func shareSetCell(idx: Int, set: WorkoutSet, kind: ExerciseKind) -> some View {
        let accent = Color(red: 0.29, green: 0.56, blue: 0.85)
        let hasData = (set.weight ?? 0) > 0 || (set.reps ?? 0) > 0

        return HStack(spacing: 6) {
            Text("\(idx)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(hasData ? accent : Color(uiColor: .systemGray4))
                .clipShape(Circle())

            Group {
                switch kind {
                case .strength, .weightedBodyweight:
                    let w = set.weight.map { AppFormatters.formatWeightNumericOnly($0) } ?? "—"
                    let r = set.reps.map { "\($0)" } ?? "—"
                    HStack(spacing: 0) {
                        Text(w)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(uiColor: .label))
                        Text(weightUnit)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(Color(uiColor: .secondaryLabel))
                        Text(" × ")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color(uiColor: .tertiaryLabel))
                        Text(r)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(uiColor: .label))
                        Text("回")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(Color(uiColor: .secondaryLabel))
                    }
                case .time:
                    Text("\(set.durationSeconds.map { "\($0)" } ?? "—")秒")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(uiColor: .label))
                case .cardio:
                    let parts = [
                        set.distanceMeters.map { AppFormatters.formatWeightNumber($0 / 1000) + "km" },
                        set.durationSeconds.map { "\($0)秒" }
                    ].compactMap { $0 }
                    Text(parts.joined(separator: " / "))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(uiColor: .label))
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(hasData ? accent.opacity(0.08) : Color(uiColor: .systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var footer: some View {
        HStack {
            Spacer()
            Text(String(localized: "app_hashtag"))
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(uiColor: .tertiaryLabel))
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
        .padding(.top, 4)
    }
}
