//
//  TasksView.swift
//  Aurora
//
//  Created by souhail on 12/1/25.
//

import SwiftUI

struct TasksView: View {
  @Environment(TaskStore.self) var taskStore
  @State private var editingTaskId: UUID? = nil
  @State private var selectedTaskForDetails: Task? = nil
  @FocusState private var focusedTaskId: UUID?
  @State private var showingSmartLists = false
  @State private var showingCategories = false
  @State private var showingNewTask = false
  @State private var searchText = ""
  @State private var isSearching = false
  @State private var navigationPath = NavigationPath()
  @Namespace private var namespace

  var body: some View {
    NavigationStack(path: $navigationPath) {
      ScrollView {
        VStack(spacing: 16) {
          if !searchText.isEmpty {
            searchResultsView
          } else {
            mainContentView
          }
        }
        .padding(.horizontal, 16)
      }
      .scrollIndicators(.hidden)
      .background(Color.clear.auroraBackground())
      .navigationTitle("Tasks")
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
          Menu {
            Button {
              showingSmartLists = true
            } label: {
              Label("Smart Lists", systemImage: "list.bullet.rectangle")
            }

            Button {
              showingCategories = true
            } label: {
              Label("Manage Categories", systemImage: "folder.badge.gearshape")
            }
          } label: {
            Image(systemName: "ellipsis")
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
        if newValue == .tasks {
          showingNewTask = true
          taskStore.addTaskTrigger = .none
        }
      }
      .sheet(isPresented: $showingSmartLists) {
        SmartListsCustomizationSheet()
          .presentationDetents([.medium, .large])
          .presentationDragIndicator(.visible)
      }
      .sheet(isPresented: $showingCategories) {
        CategoriesManagementSheet()
          .presentationDetents([.medium, .large])
          .presentationDragIndicator(.visible)
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
      .navigationDestination(for: CategoryTasksView.CategoryFilter.self) { filter in
        CategoryTasksView(filterType: filter)
          .toolbar(.hidden, for: .tabBar)
      }
      .sheet(item: $selectedTaskForDetails) { task in
        TaskSheet(task: task)
          .presentationDetents([.large])
          .presentationDragIndicator(.visible)
      }
    }
  }

  // MARK: - Main Content

  private var mainContentView: some View {
    VStack(spacing: 20) {
      smartListCardsGrid
      suggestedListSection
      myListsSection
    }
  }

  // MARK: - Smart List Cards Grid

  private var smartListCardsGrid: some View {
    let visibleLists = orderedVisibleSmartLists

    return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
      ForEach(visibleLists, id: \.self) { listType in
        SmartListCard(
          listType: listType,
          count: getCount(for: listType)
        ) {
          navigationPath.append(CategoryTasksView.CategoryFilter.smartList(listType))
        }
      }

      ForEach(visibleCategoryCards) { category in
        CategorySmartCard(
          category: category,
          count: getCount(for: category)
        ) {
          navigationPath.append(CategoryTasksView.CategoryFilter.category(category))
        }
      }
    }
  }

  private var orderedVisibleSmartLists: [SmartListType] {
    let order =
      taskStore.smartListOrder.isEmpty ? Array(SmartListType.allCases) : taskStore.smartListOrder
    return order.filter { taskStore.visibleSmartLists.contains($0) }
  }

  private var visibleCategoryCards: [TaskCategory] {
    taskStore.categories.filter { taskStore.visibleCategories.contains($0.id) }
  }

  // MARK: - Suggested List Section

  private var availableSuggestions: [(name: String, icon: String, color: String)] {
    let allSuggestions: [(name: String, icon: String, color: String)] = [
      ("Groceries", "cart.fill", "#4CAF50"),
      ("Travel", "airplane", "#2196F3"),
      ("Fitness", "figure.run", "#FF5722"),
      ("Reading", "book.fill", "#9C27B0"),
      ("Home", "house.fill", "#795548"),
      ("Movies", "film.fill", "#E91E63"),
    ]

    let existingNames = Set(taskStore.categories.map { $0.name.lowercased() })
    return allSuggestions.filter { !existingNames.contains($0.name.lowercased()) }
  }

  @ViewBuilder
  private var suggestedListSection: some View {
    if let suggestion = availableSuggestions.first {
      SuggestedListRow(
        icon: suggestion.icon,
        iconColor: Color(hex: suggestion.color),
        title: "Suggested List: \(suggestion.name)",
        subtitle: "Automatically categorizes items"
      ) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
          let newCategory = TaskCategory(
            name: suggestion.name,
            colorHex: suggestion.color,
            iconName: suggestion.icon
          )
          taskStore.addCategory(newCategory)
        }
      }
      .transition(
        .asymmetric(
          insertion: .opacity.combined(with: .move(edge: .top)),
          removal: .opacity.combined(with: .scale(scale: 0.9))
        ))
    }
  }

  // MARK: - My Lists Section

  private var myListsSection: some View {
    @Bindable var store = taskStore

    return VStack(alignment: .leading, spacing: 12) {
      Button {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
          store.myListsExpanded.toggle()
        }
      } label: {
        HStack {
          Text("My Lists")
            .font(.system(size: 22, weight: .bold))
            .foregroundStyle(.primary)

          Image(systemName: store.myListsExpanded ? "chevron.down" : "chevron.right")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.secondary)
            .contentTransition(.symbolEffect(.replace))

          Spacer()
        }
        .padding(.horizontal, 4)
      }
      .buttonStyle(.plain)

      if store.myListsExpanded {
        VStack(spacing: 8) {
          ForEach(taskStore.categories) { category in
            myListRow(for: category)
          }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
      }
    }
  }

  private func myListRow(for category: TaskCategory) -> some View {
    Button {
      navigationPath.append(CategoryTasksView.CategoryFilter.category(category))
    } label: {
      HStack(spacing: 12) {
        Image(systemName: category.iconName)
          .font(.system(size: 18, weight: .semibold))
          .foregroundStyle(Color(hex: category.colorHex))

        Text(category.name)
          .font(.system(size: 16, weight: .medium))
          .foregroundStyle(.primary)

        Spacer()

        Text("\(getCount(for: category))")
          .font(.system(size: 16, weight: .medium))
          .foregroundStyle(.secondary)

        Image(systemName: "chevron.right")
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(.tertiary)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 14)
      .glassEffect(.clear)
    }
    .buttonStyle(.plain)
  }

  // MARK: - Search Results

  private var searchResultsView: some View {
    VStack(spacing: 8) {
      if searchResults.isEmpty {
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
  }

  private var searchResults: [Task] {
    guard !searchText.isEmpty else { return [] }
    return taskStore.tasks.filter { task in
      task.title.localizedCaseInsensitiveContains(searchText) && !task.isCompleted
    }
  }

  // MARK: - Helpers

  private func getCount(for filter: TaskFilter) -> Int {
    switch filter {
    case .all: return taskStore.tasks.filter { !$0.isCompleted }.count
    case .today:
      return taskStore.tasks.filter { task in
        guard let date = task.date else { return false }
        return Calendar.current.isDateInToday(date) && !task.isCompleted
      }.count
    case .upcoming:
      return taskStore.tasks.filter { ($0.date ?? Date.distantPast) > Date() && !$0.isCompleted }
        .count
    case .flagged:
      return taskStore.tasks.filter { $0.isFlagged && !$0.isCompleted }.count
    }
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
}
