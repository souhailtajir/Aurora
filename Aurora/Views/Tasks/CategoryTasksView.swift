//
//  CategoryTasksView.swift
//  Aurora
//
//  Created by souhail on 12/29/25.
//

import SwiftUI

/// View for displaying tasks filtered by a smart list type or category
struct CategoryTasksView: View {
  @Environment(TaskStore.self) var taskStore
  @Environment(\.dismiss) var dismiss

  let filterType: CategoryFilter
  @State private var editingTaskId: UUID? = nil
  @State private var selectedTaskForDetails: Task? = nil
  @State private var searchText = ""
  @State private var isSearching = false
  @FocusState private var focusedTaskId: UUID?
  @Environment(\.horizontalSizeClass) private var sizeClass

  enum CategoryFilter: Hashable {
    case smartList(SmartListType)
    case category(TaskCategory)

    var title: String {
      switch self {
      case .smartList(let type): return type.rawValue
      case .category(let category): return category.name
      }
    }

    var tintColor: Color {
      switch self {
      case .smartList(let type): return type.tintColor
      case .category(let category): return Color(hex: category.colorHex)
      }
    }

    var icon: String {
      switch self {
      case .smartList(let type): return type.icon
      case .category(let category): return category.iconName
      }
    }
  }

  private var baseTasks: [Task] {
    switch filterType {
    case .smartList(let type):
      switch type {
      case .today:
        return taskStore.tasks.filter { task in
          guard let date = task.date else { return false }
          return Calendar.current.isDateInToday(date) && !task.isCompleted
        }
      case .scheduled:
        return taskStore.tasks.filter { task in
          task.date != nil && !task.isCompleted
        }
      case .all:
        return taskStore.tasks.filter { !$0.isCompleted }
      case .flagged:
        return taskStore.tasks.filter { $0.isFlagged && !$0.isCompleted }
      case .completed:
        return taskStore.tasks.filter { $0.isCompleted }
      }

    case .category(let category):
      return taskStore.tasks.filter { $0.category?.id == category.id && !$0.isCompleted }
    }
  }

  private var filteredTasks: [Task] {
    if searchText.isEmpty {
      return baseTasks
    }
    return baseTasks.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
  }

  var body: some View {
    ZStack(alignment: .bottomTrailing) {
      Color.clear.auroraBackground()

      List {
        ForEach(filteredTasks) { task in
          EditableTaskRow(
            task: task,
            editingTaskId: $editingTaskId,
            focusedTaskId: $focusedTaskId,
            onInfoTap: {
              selectedTaskForDetails = task
            }
          )
          .listRowInsets(LayoutTokens.listRowInsets(for: sizeClass))
          .listRowBackground(Color.clear)
          .listRowSeparator(.hidden)
        }

        if filteredTasks.isEmpty {
          emptyStateView
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }

        // Bottom padding for FAB
        Color.clear.frame(height: 100)
          .listRowBackground(Color.clear)
          .listRowSeparator(.hidden)
      }
      .listStyle(.plain)
      .scrollContentBackground(.hidden)
      .scrollIndicators(.hidden)

      // Color-coordinated floating add button
      addTaskButton
    }
    .safeAreaInset(edge: .bottom) {
      if isSearching {
        BottomSearchBar(
          text: $searchText,
          isSearching: $isSearching,
          placeholder: "Search tasks..."
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
      }
    }
    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isSearching)
    .navigationTitle(Text(filterType.title).foregroundColor(filterType.tintColor))
    .navigationBarTitleDisplayMode(.automatic)
    .toolbarColorScheme(.dark, for: .navigationBar)
    .toolbar(.hidden, for: .tabBar)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button("Search", systemImage: "magnifyingglass") {
          withAnimation {
            isSearching = true
          }
        }
      }
    }
    .tint(filterType.tintColor)
    .onTapGesture {
      // Dismiss keyboard when tapping outside
      editingTaskId = nil
      focusedTaskId = nil
    }
    .sheet(item: $selectedTaskForDetails) { task in
      TaskSheet(task: task)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
  }

  // MARK: - Add Task Button

  private var addTaskButton: some View {
    Button {
      addNewTask()
    } label: {
      ZStack {
        Circle()
          .fill(filterType.tintColor)
          .frame(width: LayoutTokens.CardHeight.fab, height: LayoutTokens.CardHeight.fab)

        Image(systemName: "plus")
          .font(.system(size: LayoutTokens.IconSize.xl, weight: .semibold))
          .foregroundStyle(.white)
      }
      .shadow(color: filterType.tintColor.opacity(0.4), radius: 8, x: 0, y: 4)
    }
    .buttonStyle(.plain)
    .padding(.trailing, LayoutTokens.Padding.screenHorizontal(for: sizeClass))
    .padding(.bottom, LayoutTokens.Spacing.xl)
  }

  private var emptyStateView: some View {
    VStack(spacing: LayoutTokens.Spacing.md) {
      Image(systemName: filterType.icon)
        .font(.system(size: LayoutTokens.Typography.heroStat))
        .foregroundStyle(filterType.tintColor.opacity(0.6))
      Text(searchText.isEmpty ? "No tasks" : "No matching tasks")
        .font(.system(size: LayoutTokens.Typography.body, weight: .medium))
        .foregroundStyle(.primary.opacity(0.6))
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, LayoutTokens.Spacing.xxl * 3)
  }

  private func addNewTask() {
    let category: TaskCategory
    if case .category(let cat) = filterType {
      category = cat
    } else {
      category = .personal
    }

    let newTask = Task(title: "", date: Date(), priority: .medium, category: category)
    taskStore.addTask(newTask)

    // Start editing the new task
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      editingTaskId = newTask.id
      focusedTaskId = newTask.id
    }
  }
}
