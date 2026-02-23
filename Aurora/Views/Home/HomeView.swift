//
//  HomeView.swift
//  Aurora
//
//  Created by souhail on 12/1/25.
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

  private var flaggedCount: Int { taskStore.tasks.filter { $0.isFlagged && !$0.isCompleted }.count }
  private var workCount: Int {
    taskStore.tasks.filter { $0.category?.name == "Work" && !$0.isCompleted }.count
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

  private var pinnedCardsSection: some View {
    // Build ordered list of pinned items (respecting user's ordering)
    var pinnedItems: [PinnedCardItem] = []

    // Add smart lists in their stored order
    for listType in taskStore.pinnedHomeSmartLists {
      pinnedItems.append(.smartList(listType))
    }

    // Add categories in their stored order
    for categoryId in taskStore.pinnedHomeCategoryIds {
      if let category = taskStore.categories.first(where: { $0.id == categoryId }) {
        pinnedItems.append(.category(category))
      }
    }

    // Limit to 2 cards max
    let cardsToShow = Array(pinnedItems.prefix(2))

    return Group {
      if !cardsToShow.isEmpty {
        HStack(spacing: 12) {
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
        .padding(.horizontal, 16)
        .padding(.top, 4)
      }
    }
  }

  var body: some View {
    NavigationStack(path: $navigationPath) {
      ScrollView(showsIndicators: false) {
        VStack(spacing: 20) {
          if !searchText.isEmpty {
            searchResultsView
          } else {
            celestialSection
            dailyProgressCard.padding(.top, 4)

            pinnedCardsSection

            todaysAgendaSection
          }
        }
        .padding(.bottom, 100)
      }
      .background(Color.clear.auroraBackground())
      .navigationTitle("Home")
      .toolbarTitleDisplayMode(.inlineLarge)
      .safeAreaPadding(.top, 8)
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
            withAnimation {
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

  // MARK: - Search Results

  private var searchResultsView: some View {
    VStack(spacing: 8) {
      if searchResults.isEmpty {
        // Empty state when no results found
        VStack(spacing: 12) {
          Image(systemName: "magnifyingglass")
            .font(.system(size: 36))
            .foregroundStyle(.secondary)
          Text("No results found")
            .font(.system(size: 15))
            .foregroundStyle(.secondary)
          Text("Try a different search term")
            .font(.system(size: 13))
            .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
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
    .padding(.horizontal, 16)
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

  // MARK: - Celestial Section (Planet or Moon based on settings)

  private var celestialSection: some View {
    VStack(spacing: 16) {
      // Planet/Moon display based on user preference
      switch userProfileStore.profile.celestialDisplayMode {
      case .zodiacPlanet:
        PlanetSceneView(planet: userProfileStore.profile.rulingPlanet)
          .frame(height: 200)
      case .moonPhase:
        MoonPhaseVisualizationView(moonInfo: MoonPhase.getInfo())
          .frame(height: 200)
      }

      // Greeting and date
      VStack(spacing: 6) {
        Text(currentGreeting)
          .font(.system(size: 28, weight: .bold))
          .foregroundStyle(Theme.primary)

        Text(formattedDate)
          .font(.system(size: 15))
          .foregroundStyle(Theme.secondary)
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 16)
  }

  private var dailyProgressCard: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(alignment: .top) {
        Text("Daily Progress")
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(Theme.secondary)
          .padding(.horizontal, 4)
        Spacer()
        Text("\(completedTasksCount)/\(max(totalTodayTasks, 1))")
          .font(.system(size: 16, weight: .bold))
          .foregroundStyle(Theme.secondary)
          .padding(.horizontal, 4)
      }

      GeometryReader { geometry in
        ZStack(alignment: .leading) {
          RoundedRectangle(cornerRadius: 8)
            .fill(.gray.opacity(0.2))
            .frame(height: 8)
          RoundedRectangle(cornerRadius: 8)
            .fill(Theme.secondary)
            .frame(
              width: geometry.size.width * CGFloat(completedTasksCount)
                / CGFloat(max(totalTodayTasks, 1)), height: 8
            )
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: completedTasksCount)
        }
      }
      .frame(height: 8)
      .padding(.horizontal, 4)

      let percentage = totalTodayTasks > 0 ? (completedTasksCount * 100) / totalTodayTasks : 0
      Text("\(percentage)% of your daily tasks done")
        .font(.system(size: 13))
        .foregroundStyle(.gray)
        .padding(.horizontal, 4)
    }
    .padding(16)
    .glassEffect(.regular)
    .padding(.horizontal, 16)
  }

  private var currentGreeting: String {
    let hour = Calendar.current.component(.hour, from: Date())
    if hour < 12 {
      return "Good Morning"
    } else if hour < 17 {
      return "Good Afternoon"
    } else {
      return "Good Evening"
    }
  }

  private var formattedDate: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE, MMMM d"
    return formatter.string(from: Date())
  }

  private var todaysAgendaSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Button {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
          agendaExpanded.toggle()
        }
      } label: {
        HStack {
          Text("Today's Agenda")
            .font(.system(size: 22, weight: .bold))
            .foregroundStyle(.primary)

          Image(systemName: agendaExpanded ? "chevron.down" : "chevron.right")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.secondary)
            .contentTransition(.symbolEffect(.replace))

          Spacer()
        }
        .padding(.horizontal, 4)
      }
      .buttonStyle(.plain)
      .padding(.horizontal, 16)

      if agendaExpanded {
        if todaysTasks.isEmpty {
          VStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
              .font(.system(size: 36))
              .foregroundStyle(.secondary)
            Text("No tasks for today")
              .font(.system(size: 15))
              .foregroundStyle(.secondary)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 32)
        } else {
          VStack(spacing: 8) {
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
          .padding(.horizontal, 16)
          .transition(.opacity.combined(with: .move(edge: .top)))
        }
      }
    }
  }

}
