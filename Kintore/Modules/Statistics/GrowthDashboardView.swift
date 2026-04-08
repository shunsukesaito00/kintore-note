import SwiftUI
import SwiftData

enum GrowthTab: String, CaseIterable {
    case overview
    case exercise
    case records

    var displayName: String {
        switch self {
        case .overview: return String(localized: "growth_tab_overview")
        case .exercise: return String(localized: "growth_tab_exercise")
        case .records:  return String(localized: "growth_tab_records")
        }
    }
}

private struct GrowthSharePayload: Identifiable {
    let id = UUID()
    let viewModel: StatisticsViewModel
    let weightUnit: String
}

struct GrowthDashboardView: View {
    @AppStorage(AppTheme.weightUnitStorageKey) private var weightUnit: String = "kg"
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var viewModel: StatisticsViewModel?
    @State private var selectedTab: GrowthTab = .overview
    @State private var growthSharePayload: GrowthSharePayload?

    var body: some View {
        Group {
            if let vm = viewModel {
                dashboardContent(vm: vm)
            } else {
                ProgressView(String(localized: "home_loading"))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear { createViewModelIfNeeded() }
            }
        }
        .navigationTitle(String(localized: "nav_statistics_title"))
        .navigationBarTitleDisplayMode(.inline)
        .appTabRootChrome()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if let vm = viewModel {
                        growthSharePayload = GrowthSharePayload(viewModel: vm, weightUnit: weightUnit)
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.body.weight(.medium))
                        .foregroundStyle(AppTheme.accent)
                }
                .accessibilityLabel(String(localized: "growth_share_summary"))
                .accessibilityHint(String(localized: "growth_share_summary_a11y_hint"))
            }
        }
        .sheet(item: $growthSharePayload) { payload in
            GrowthSharePreviewSheet(
                viewModel: payload.viewModel,
                weightUnit: payload.weightUnit,
                onDismiss: { growthSharePayload = nil }
            )
        }
        .onAppear {
            AnalyticsEventService.log(.statisticsScreenViewed)
            if viewModel != nil {
                viewModel?.load(modelContext: modelContext)
            }
        }
    }

    private func createViewModelIfNeeded() {
        guard viewModel == nil else { return }
        viewModel = StatisticsViewModel()
        viewModel?.load(modelContext: modelContext)
    }

    @ViewBuilder
    private func dashboardContent(vm: StatisticsViewModel) -> some View {
        VStack(spacing: 0) {
            tabBar
            TabView(selection: $selectedTab) {
                GrowthOverviewTab(viewModel: vm, weightUnit: weightUnit)
                    .tag(GrowthTab.overview)
                GrowthExerciseTab(viewModel: vm, weightUnit: weightUnit)
                    .tag(GrowthTab.exercise)
                GrowthRecordsTab(viewModel: vm, weightUnit: weightUnit)
                    .tag(GrowthTab.records)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(AppTheme.animationTabTransition(reduceMotion: reduceMotion), value: selectedTab)
        }
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(GrowthTab.allCases, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 6) {
                        Text(tab.displayName)
                            .font(AppTheme.bodySemiboldFont)
                            .foregroundStyle(selectedTab == tab ? AppTheme.accent : AppTheme.secondaryText)
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(selectedTab == tab ? AppTheme.accent : Color.clear)
                            .frame(height: 3)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .animation(AppTheme.animationTabTransition(reduceMotion: reduceMotion), value: selectedTab)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
            }
        }
        .padding(.horizontal, AppTheme.spacingLG)
        .padding(.top, AppTheme.spacingSM)
        .padding(.bottom, AppTheme.spacingSM)
        .background(AppTheme.cardBackground)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppTheme.separator.opacity(0.35))
                .frame(height: AppTheme.cardStrokeWidth)
        }
    }
}

#Preview {
    NavigationStack {
        GrowthDashboardView()
    }
    .modelContainer(for: [WorkoutSession.self, WorkoutExercise.self, WorkoutSet.self, Exercise.self, PersonalRecord.self], inMemory: true)
}
