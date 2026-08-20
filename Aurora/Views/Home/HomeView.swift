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
      Group {
        if !searchText.isEmpty {
          List {
            searchResultsView
          }
          .listStyle(.plain)
          .platformListRowSpacing(0)
          .scrollContentBackground(.hidden)
          .scrollIndicators(.hidden)
        } else {
          #if os(macOS)
          // Side-by-side layout on macOS
          HStack(alignment: .top, spacing: LayoutTokens.Spacing.xl) {
            // Left column (Planet, Progress, Pinned Cards)
            ScrollView(showsIndicators: false) {
              VStack(spacing: LayoutTokens.Spacing.xl) {
                celestialSection
                dailyProgressCard
                  .padding(.horizontal, LayoutTokens.Padding.screenHorizontal(for: sizeClass))
                pinnedCardsSection
              }
              .padding(.top, LayoutTokens.Spacing.sm)
              .padding(.bottom, LayoutTokens.Padding.scrollBottom)
            }
            .frame(minWidth: 320, maxWidth: 420)
            
            // Right column (Agenda)
            List {
              todaysAgendaSection
            }
            .listStyle(.plain)
            .platformListRowSpacing(0)
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
          }
          #else
          List {
            celestialSection
              .listRowInsets(EdgeInsets())
              .listRowBackground(Color.clear)
              .listRowSeparator(.hidden)

            dailyProgressCard
              .listRowInsets(EdgeInsets(top: LayoutTokens.Spacing.md, leading: LayoutTokens.Padding.screenHorizontal(for: sizeClass), bottom: LayoutTokens.Spacing.lg, trailing: LayoutTokens.Padding.screenHorizontal(for: sizeClass)))
              .listRowBackground(Color.clear)
              .listRowSeparator(.hidden)

            pinnedCardsSection
              .listRowInsets(EdgeInsets())
              .listRowBackground(Color.clear)
              .listRowSeparator(.hidden)

            todaysAgendaSection
            
            Color.clear
              .frame(height: LayoutTokens.Padding.scrollBottom)
              .listRowInsets(EdgeInsets())
              .listRowBackground(Color.clear)
              .listRowSeparator(.hidden)
          }
          .listStyle(.plain)
          .platformListRowSpacing(0)
          .scrollContentBackground(.hidden)
          .scrollIndicators(.hidden)
          #endif
        }
      }
      .background(Color.clear.auroraBackground())
      .navigationTitle("Home")
      .toolbarTitleDisplayMode(.inlineLarge)
      .safeAreaPadding(.top, LayoutTokens.Spacing.sm)
      .searchable(text: $searchText, prompt: "Search tasks...")
      .toolbar {
        ToolbarItem(placement: .platformTopBarTrailing) {
          Button("Add Task", systemImage: "plus") {
            addNewTask()
          }
        }

        ToolbarItem(placement: .platformTopBarTrailing) {
          Button("Pinned Cards", systemImage: "pin") {
            showingPinnedCards = true
          }
        }

        #if os(iOS)
        ToolbarSpacer(.fixed, placement: .topBarTrailing)

        ToolbarItem(placement: .platformTopBarTrailing) {
          NavigationLink(value: "settings") {
            Image(systemName: "gearshape")
          }
        }
        #endif
      }
      .onChange(of: taskStore.addTaskTrigger) { _, newValue in
        if newValue == .home {
          addNewTask()
          taskStore.addTaskTrigger = .none
        }
      }
      #if os(iOS)
      .navigationDestination(for: String.self) { destination in
        if destination == "settings" {
          SettingsView()
        }
      }
      #endif
      .sheet(isPresented: $showingNewTask) {
        TaskSheet()
          .presentationDetents([.large])
          .presentationDragIndicator(.visible)
          #if os(macOS)
          .frame(minWidth: 480, idealWidth: 520, minHeight: 600)
          #endif
      }
      .sheet(isPresented: $showingPinnedCards) {
        PinnedCardsSheet()
          .presentationDetents([.medium, .large])
          .presentationDragIndicator(.visible)
          #if os(macOS)
          .frame(minWidth: 400, idealWidth: 440, minHeight: 400)
          #endif
      }
      .sheet(item: $selectedTaskForDetails) { task in
        TaskSheet(task: task)
          .presentationDetents([.large])
          .presentationDragIndicator(.visible)
          #if os(macOS)
          .frame(minWidth: 480, idealWidth: 520, minHeight: 600)
          #endif
      }
      .navigationDestination(for: CategoryTasksView.CategoryFilter.self) { filter in
        CategoryTasksView(filterType: filter)
          #if os(iOS)
          .toolbar(.hidden, for: .tabBar)
          #endif
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
          .foregroundStyle(.primary)

        Spacer()

        Text("\(completedTasksCount)/\(max(totalTodayTasks, 1))")
          .font(.system(size: LayoutTokens.Typography.callout, weight: .bold, design: .rounded))
          .foregroundStyle(Theme.primary)
      }

      GeometryReader { geo in
        ZStack(alignment: .leading) {
          Capsule()
            .fill(Color.white.opacity(0.12))
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
              width: max(0, min(geo.size.width, geo.size.width * CGFloat(completedTasksCount) / CGFloat(max(totalTodayTasks, 1)))),
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
    .glassEffect(.regular.tint(Theme.primary.opacity(0.12)), in: .rect(cornerRadius: LayoutTokens.Radius.lg))
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
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: LayoutTokens.Spacing.md) {
            ForEach(cardsToShow) { item in
              switch item {
              case .smartList(let listType):
                SmartListCard(listType: listType, count: getCount(for: listType)) {
                  navigationPath.append(CategoryTasksView.CategoryFilter.smartList(listType))
                }
                .frame(width: 160)
              case .category(let category):
                CategorySmartCard(category: category, count: getCount(for: category)) {
                  navigationPath.append(CategoryTasksView.CategoryFilter.category(category))
                }
                .frame(width: 160)
              }
            }
          }
          .padding(.horizontal, LayoutTokens.Padding.screenHorizontal(for: sizeClass))
        }
      }
    }
  }

  // MARK: - Today's Agenda Section

  @ViewBuilder
  private var todaysAgendaSection: some View {
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
          .contentTransition(.symbolEffect(.replace))

        Spacer()
      }
      .padding(.horizontal, LayoutTokens.Padding.sectionTitleInset)
    }
    .buttonStyle(.plain)
    .listRowInsets(EdgeInsets(top: LayoutTokens.Spacing.lg, leading: LayoutTokens.Padding.screenHorizontal(for: sizeClass), bottom: LayoutTokens.Spacing.sm, trailing: LayoutTokens.Padding.screenHorizontal(for: sizeClass)))
    .listRowBackground(Color.clear)
    .listRowSeparator(.hidden)

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
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
      } else {
        ForEach(todaysTasks) { task in
          EditableTaskRow(
            task: task,
            editingTaskId: $editingTaskId,
            focusedTaskId: $focusedTaskId,
            onInfoTap: {
              selectedTaskForDetails = task
            }
          )
          .listRowInsets(LayoutTokens.listRowInsets(vertical: LayoutTokens.Spacing.xs, for: sizeClass))
          .listRowBackground(Color.clear)
          .listRowSeparator(.hidden)
        }
      }
    }
  }

  // MARK: - Search Results

  @ViewBuilder
  private var searchResultsView: some View {
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
      .listRowInsets(EdgeInsets())
      .listRowBackground(Color.clear)
      .listRowSeparator(.hidden)
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
        .listRowInsets(LayoutTokens.listRowInsets(vertical: LayoutTokens.Spacing.xs, for: sizeClass))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
      }
    }
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
