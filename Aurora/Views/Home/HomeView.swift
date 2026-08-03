//
//  HomeView.swift
//  Aurora
//

import SwiftUI

struct HomeView: View {
  @Environment(TaskStore.self) var taskStore
  @Environment(UserProfileStore.self) var userProfileStore
  @State private var editingTaskId: UUID? = nil
  @State private var selectedTaskForDetails: Task? = nil
  @FocusState private var focusedTaskId: UUID?
  @State private var searchText = ""
  @State private var agendaExpanded = true
  @State private var isSearching = false
  @Namespace private var namespace
  @State private var showingNewTask = false
  @State private var showingPinnedCards = false
  @State private var navigationPath = NavigationPath()
  @Environment(\.horizontalSizeClass) private var sizeClass

  private var todaysTasks: [Task] {
    let tasks = taskStore.tasks.filter { task in
      guard let date = task.date else { return false }
      return Calendar.current.isDateInToday(date) && !task.isCompleted
    }
    if searchText.isEmpty {
      return tasks.sorted { ($0.date ?? Date.distantFuture) < ($1.date ?? Date.distantFuture) }
    } else {
      return tasks.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        .sorted { ($0.date ?? Date.distantFuture) < ($1.date ?? Date.distantFuture) }
    }
  }

  private var completedTasksCount: Int {
    taskStore.tasks.filter { task in
      guard let date = task.date else { return false }
      return Calendar.current.isDateInToday(date) && task.isCompleted
    }.count
  }

  private var totalTodayTasks: Int {
    taskStore.tasks.filter { task in
      guard let date = task.date else { return false }
      return Calendar.current.isDateInToday(date)
    }.count
  }

  private func getCount(for listType: SmartListType) -> Int {
    switch listType {
    case .today:
      return taskStore.tasks.filter { task in
        guard let date = task.date else { return false }
        return Calendar.current.isDateInToday(date) && !task.isCompleted
      }.count
    case .scheduled:
      return taskStore.tasks.filter { $0.date != nil && !$0.isCompleted }.count
    case .all:
      return taskStore.tasks.filter { !$0.isCompleted }.count
    case .flagged:
      return taskStore.tasks.filter { $0.isFlagged && !$0.isCompleted }.count
    case .completed:
      return taskStore.tasks.filter { $0.isCompleted }.count
    }
  }

  private func getCount(for category: TaskCategory) -> Int {
    taskStore.tasks.filter { $0.category?.id == category.id && !$0.isCompleted }.count
  }

  var body: some View {
    NavigationStack(path: $navigationPath) {
      ScrollView(showsIndicators: false) {
        VStack(spacing: LayoutTokens.Spacing.xl) {
          if !searchText.isEmpty {
            searchResultsView
          } else {
            celestialSection
            dailyProgressCard
            pinnedCardsSection
            todaysAgendaSection
          }
        }
        .padding(.bottom, LayoutTokens.Padding.scrollBottom)
      }
      .background(Color.clear.auroraBackground())
      .navigationTitle("Home")
      .toolbarTitleDisplayMode(.inlineLarge)
      .safeAreaPadding(.top, LayoutTokens.Spacing.sm)
      .safeAreaInset(edge: .bottom) {
        if isSearching {
          BottomSearchBar(text: $searchText, isSearching: $isSearching)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
      }
      .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isSearching)
      .toolbar {
        ToolbarItemGroup(placement: .topBarTrailing) {
          Button("Search", systemImage: "magnifyingglass") {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
              isSearching = true
            }
          }
        }

        ToolbarItem(placement: .topBarTrailing) {
          Button("Pinned Cards", systemImage: "pin") {
            showingPinnedCards = true
          }
        }

        ToolbarSpacer(.fixed, placement: .topBarTrailing)

        ToolbarItem(placement: .topBarTrailing) {
          NavigationLink(value: "settings") {
            Image(systemName: "gearshape")
          }
        }
      }
      .onChange(of: taskStore.addTaskTrigger) { _, newValue in
        if newValue == .home {
          addNewTask()
          taskStore.addTaskTrigger = .none
        }
      }
      .navigationDestination(for: String.self) { destination in
        if destination == "settings" {
          SettingsView()
        }
      }
      .sheet(isPresented: $showingNewTask) {
        TaskSheet()
          .presentationDetents([.large])
          .presentationDragIndicator(.visible)
      }
      .sheet(isPresented: $showingPinnedCards) {
        PinnedCardsSheet()
          .presentationDetents([.medium, .large])
          .presentationDragIndicator(.visible)
      }
      .sheet(item: $selectedTaskForDetails) { task in
        TaskSheet(task: task)
          .presentationDetents([.large])
          .presentationDragIndicator(.visible)
      }
      .navigationDestination(for: CategoryTasksView.CategoryFilter.self) { filter in
        CategoryTasksView(filterType: filter)
          .toolbar(.hidden, for: .tabBar)
      }
    }
  }

  // MARK: - Celestial Section

  private var celestialSection: some View {
    VStack(spacing: LayoutTokens.Spacing.lg) {
      switch userProfileStore.profile.celestialDisplayMode {
      case .zodiacPlanet:
        PlanetSceneView(planet: userProfileStore.profile.rulingPlanet)
          .frame(height: LayoutTokens.CardHeight.celestial)
      case .moonPhase:
        MoonPhaseVisualizationView(moonInfo: MoonPhase.getInfo())
          .frame(height: LayoutTokens.CardHeight.celestial)
      }

      VStack(spacing: LayoutTokens.Spacing.xs) {
        Text(currentGreeting)
          .font(.system(size: LayoutTokens.Typography.largeTitle, weight: .bold, design: .rounded))
          .foregroundStyle(
            LinearGradient(
              colors: [Theme.primary, Theme.secondary],
              startPoint: .leading,
              endPoint: .trailing
            )
          )

        Text(formattedDate)
          .font(.system(size: LayoutTokens.Typography.callout, weight: .medium))
          .foregroundStyle(.secondary)
      }
    }
    .padding(.vertical, LayoutTokens.Spacing.sm)
  }

  // MARK: - Daily Progress Card

  private var dailyProgressCard: some View {
    let percentage = totalTodayTasks > 0 ? (completedTasksCount * 100) / totalTodayTasks : 0

    return VStack(alignment: .leading, spacing: LayoutTokens.Spacing.md) {
      HStack {
        Text("Daily Progress")
          .font(.system(size: LayoutTokens.Typography.callout, weight: .semibold))
          .foregroundStyle(.secondary)

        Spacer()

        Text("\(completedTasksCount)/\(max(totalTodayTasks, 1))")
          .font(.system(size: LayoutTokens.Typography.callout, weight: .bold, design: .rounded))
          .foregroundStyle(Theme.primary)
      }

      GeometryReader { geo in
        ZStack(alignment: .leading) {
          Capsule()
            .fill(.tertiary.opacity(0.3))
            .frame(height: 8)

          Capsule()
            .fill(
              LinearGradient(
                colors: [Theme.primary, Theme.secondary],
                startPoint: .leading,
                endPoint: .trailing
              )
            )
            .frame(
              width: geo.size.width * CGFloat(completedTasksCount) / CGFloat(max(totalTodayTasks, 1)),
              height: 8
            )
            .animation(.spring(response: 0.5, dampingFraction: 0.75), value: completedTasksCount)
        }
      }
      .frame(height: LayoutTokens.CardHeight.progressBar)

      Text("\(percentage)% of today's tasks completed")
        .font(.system(size: LayoutTokens.Typography.footnote, weight: .medium))
        .foregroundStyle(.secondary)
    }
    .padding(LayoutTokens.Padding.cardInner(for: sizeClass))
    .background {
      RoundedRectangle(cornerRadius: LayoutTokens.Radius.lg, style: .continuous)
            .glassEffect(.clear)
    }
    .padding(.horizontal, LayoutTokens.Padding.screenHorizontal(for: sizeClass))
  }

  // MARK: - Pinned Cards Section

  private var pinnedCardsSection: some View {
    var pinnedItems: [PinnedCardItem] = []

    for listType in taskStore.pinnedHomeSmartLists {
      pinnedItems.append(.smartList(listType))
    }

    for categoryId in taskStore.pinnedHomeCategoryIds {
      if let category = taskStore.categories.first(where: { $0.id == categoryId }) {
        pinnedItems.append(.category(category))
      }
    }

    let cardsToShow = Array(pinnedItems.prefix(2))

    return Group {
      if !cardsToShow.isEmpty {
        HStack(spacing: LayoutTokens.Spacing.md) {
          ForEach(cardsToShow) { item in
            switch item {
            case .smartList(let listType):
              SmartListCard(listType: listType, count: getCount(for: listType)) {
                navigationPath.append(CategoryTasksView.CategoryFilter.smartList(listType))
              }
            case .category(let category):
              CategorySmartCard(category: category, count: getCount(for: category)) {
                navigationPath.append(CategoryTasksView.CategoryFilter.category(category))
              }
            }
          }
        }
        .padding(.horizontal, LayoutTokens.Padding.screenHorizontal(for: sizeClass))
      }
    }
  }

  // MARK: - Today's Agenda Section

  private var todaysAgendaSection: some View {
    VStack(alignment: .leading, spacing: LayoutTokens.Spacing.md) {
      Button {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
          agendaExpanded.toggle()
        }
      } label: {
        HStack {
          Text("Today's Agenda")
            .font(.system(size: LayoutTokens.Typography.title2, weight: .bold))
            .foregroundStyle(.primary)

          Image(systemName: agendaExpanded ? "chevron.down" : "chevron.right")
            .font(.system(size: LayoutTokens.Typography.subheadline, weight: .semibold))
            .foregroundStyle(.secondary)

          Spacer()
        }
        .padding(.horizontal, LayoutTokens.Padding.sectionTitleInset)
      }
      .buttonStyle(.plain)
      .padding(.horizontal, LayoutTokens.Padding.screenHorizontal(for: sizeClass))

      if agendaExpanded {
        if todaysTasks.isEmpty {
          VStack(spacing: LayoutTokens.Spacing.sm) {
            Image(systemName: "checkmark.circle.fill")
              .font(.system(size: LayoutTokens.Typography.emptyStateIcon))
              .foregroundStyle(Theme.primary.opacity(0.7))

            Text("All clear for today!")
              .font(.system(size: LayoutTokens.Typography.callout, weight: .medium))
              .foregroundStyle(.secondary)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, LayoutTokens.Spacing.xxl * 2)
        } else {
          VStack(spacing: LayoutTokens.Spacing.sm) {
            ForEach(todaysTasks) { task in
              EditableTaskRow(
                task: task,
                editingTaskId: $editingTaskId,
                focusedTaskId: $focusedTaskId,
                onInfoTap: {
                  selectedTaskForDetails = task
                }
              )
            }
          }
          .padding(.horizontal, LayoutTokens.Padding.screenHorizontal(for: sizeClass))
          .transition(.opacity.combined(with: .move(edge: .top)))
        }
      }
    }
  }

  // MARK: - Search Results

  private var searchResultsView: some View {
    VStack(spacing: LayoutTokens.Spacing.sm) {
      if searchResults.isEmpty {
        VStack(spacing: LayoutTokens.Spacing.md) {
          Image(systemName: "magnifyingglass")
            .font(.system(size: LayoutTokens.Typography.emptyStateIcon))
            .foregroundStyle(.secondary)
          Text("No matching tasks found")
            .font(.system(size: LayoutTokens.Typography.callout, weight: .medium))
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, LayoutTokens.Spacing.xxl * 3)
      } else {
        ForEach(searchResults) { task in
          EditableTaskRow(
            task: task,
            editingTaskId: $editingTaskId,
            focusedTaskId: $focusedTaskId,
            onInfoTap: {
              selectedTaskForDetails = task
            }
          )
        }
      }
    }
    .padding(.horizontal, LayoutTokens.Padding.screenHorizontal(for: sizeClass))
  }

  private var searchResults: [Task] {
    guard !searchText.isEmpty else { return [] }
    return taskStore.tasks.filter { task in
      task.title.localizedCaseInsensitiveContains(searchText) && !task.isCompleted
    }
  }

  private func addNewTask() {
    let newTask = Task(title: "", date: Date(), priority: .medium, category: .personal)
    taskStore.addTask(newTask)

    withAnimation {
      agendaExpanded = true
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      editingTaskId = newTask.id
      focusedTaskId = newTask.id
    }
  }

  private var currentGreeting: String {
    let hour = Calendar.current.component(.hour, from: Date())
    if hour < 12 { return "Good Morning" }
    if hour < 17 { return "Good Afternoon" }
    return "Good Evening"
  }

  private var formattedDate: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE, MMMM d"
    return formatter.string(from: Date())
  }
}
