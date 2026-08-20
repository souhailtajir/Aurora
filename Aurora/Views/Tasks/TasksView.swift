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
  @State private var navigationPath = NavigationPath()
  @Namespace private var namespace
  @Environment(\.horizontalSizeClass) private var sizeClass

  var body: some View {
    NavigationStack(path: $navigationPath) {
      List {
        if !searchText.isEmpty {
          searchResultsView
        } else {
          smartListCardsGrid
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .padding(.horizontal, LayoutTokens.Padding.screenHorizontal(for: sizeClass))
            .padding(.bottom, LayoutTokens.Spacing.lg)

          suggestedListSection
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .padding(.horizontal, LayoutTokens.Padding.screenHorizontal(for: sizeClass))

          myListsSection
          
          Color.clear
            .frame(height: LayoutTokens.Padding.scrollBottom)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
      }
      .listStyle(.plain)
      .platformListRowSpacing(0)
      .scrollContentBackground(.hidden)
      .scrollIndicators(.hidden)
      .background(Color.clear.auroraBackground())
      .navigationTitle("Tasks")
      .toolbarTitleDisplayMode(.inlineLarge)
      .safeAreaPadding(.top, LayoutTokens.Spacing.sm)
      .searchable(text: $searchText, prompt: "Search tasks...")
      .toolbar {
        ToolbarItem(placement: .platformTopBarTrailing) {
          Button("Add Task", systemImage: "plus") {
            showingNewTask = true
          }
        }

        ToolbarItem(placement: .platformTopBarTrailing) {
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
        if newValue == .tasks {
          showingNewTask = true
          taskStore.addTaskTrigger = .none
        }
      }
      .sheet(isPresented: $showingSmartLists) {
        SmartListsCustomizationSheet()
          .presentationDetents([.medium, .large])
          .presentationDragIndicator(.visible)
          #if os(macOS)
          .frame(minWidth: 400, idealWidth: 440, minHeight: 400)
          #endif
      }
      .sheet(isPresented: $showingCategories) {
        CategoriesManagementSheet()
          .presentationDetents([.medium, .large])
          .presentationDragIndicator(.visible)
          #if os(macOS)
          .frame(minWidth: 400, idealWidth: 440, minHeight: 400)
          #endif
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
      .navigationDestination(for: CategoryTasksView.CategoryFilter.self) { filter in
        CategoryTasksView(filterType: filter)
          #if os(iOS)
          .toolbar(.hidden, for: .tabBar)
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
    }
  }

  // MARK: - Main Content

  // (Removed mainContentView since elements are directly in List)

  // MARK: - Smart List Cards Grid

  private var smartListCardsGrid: some View {
    let visibleLists = orderedVisibleSmartLists

    #if os(macOS)
    let columns = Array(repeating: GridItem(.flexible(), spacing: LayoutTokens.Spacing.md), count: 3)
    #else
    let columns = Array(repeating: GridItem(.flexible(), spacing: LayoutTokens.Spacing.md), count: 2)
    #endif

    return LazyVGrid(
      columns: columns,
      spacing: LayoutTokens.Spacing.md
    ) {
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

  @ViewBuilder
  private var myListsSection: some View {
    @Bindable var store = taskStore

    Button {
      withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
        store.myListsExpanded.toggle()
      }
    } label: {
      HStack {
        Text("My Lists")
          .font(.system(size: LayoutTokens.Typography.title2, weight: .bold))
          .foregroundStyle(.primary)

        Image(systemName: store.myListsExpanded ? "chevron.down" : "chevron.right")
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

    if store.myListsExpanded {
      ForEach(taskStore.categories) { category in
        myListRow(for: category)
          .listRowInsets(LayoutTokens.listRowInsets(vertical: LayoutTokens.Spacing.xs, for: sizeClass))
          .listRowBackground(Color.clear)
          .listRowSeparator(.hidden)
      }
    }
  }

  private func myListRow(for category: TaskCategory) -> some View {
    Button {
      navigationPath.append(CategoryTasksView.CategoryFilter.category(category))
    } label: {
      HStack(spacing: LayoutTokens.Spacing.md) {
        Image(systemName: category.iconName)
          .font(.system(size: LayoutTokens.IconSize.md, weight: .semibold))
          .foregroundStyle(Color(hex: category.colorHex))

        Text(category.name)
          .font(.system(size: LayoutTokens.Typography.body, weight: .medium))
          .foregroundStyle(.primary)

        Spacer()

        Text("\(getCount(for: category))")
          .font(.system(size: LayoutTokens.Typography.body, weight: .medium))
          .foregroundStyle(.secondary)

        Image(systemName: "chevron.right")
          .font(.system(size: LayoutTokens.Typography.caption, weight: .semibold))
          .foregroundStyle(.tertiary)
      }
      .padding(.horizontal, LayoutTokens.Padding.cardInner(for: sizeClass))
      .padding(.vertical, LayoutTokens.Padding.rowVertical)
      .glassEffect()
    }
    .buttonStyle(.plain)
  }

  // MARK: - Search Results

  @ViewBuilder
  private var searchResultsView: some View {
    if searchResults.isEmpty {
      VStack(spacing: LayoutTokens.Spacing.md) {
        Image(systemName: "magnifyingglass")
          .font(.system(size: LayoutTokens.Typography.emptyStateIcon))
          .foregroundStyle(.secondary)
        Text("No results found")
          .font(.system(size: LayoutTokens.Typography.callout))
          .foregroundStyle(.secondary)
        Text("Try a different search term")
          .font(.system(size: LayoutTokens.Typography.footnote))
          .foregroundStyle(.tertiary)
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
