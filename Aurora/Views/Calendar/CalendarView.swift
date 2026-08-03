//
//  CalendarView.swift
//  Aurora
//
//  Created by souhail on 12/1/25.
//

import SwiftUI

struct CalendarView: View {
  @Environment(TaskStore.self) var taskStore
  @Environment(UserProfileStore.self) var userProfileStore
  @State private var editingTaskId: UUID? = nil
  @State private var selectedTaskForDetails: Task? = nil
  @FocusState private var focusedTaskId: UUID?
  @State private var searchText = ""
  @State private var isSearching = false
  @State private var selectedDate = Date()
  @State private var dayDetailExpanded = true
  @State private var navigationPath = NavigationPath()
  @Namespace private var namespace
  @Environment(\.horizontalSizeClass) private var sizeClass

  private let calendar = Calendar.current

  // MARK: - Computed Properties

  private var weekdays: [String] {
    taskStore.weekStartsOnMonday
      ? ["M", "T", "W", "T", "F", "S", "S"]
      : ["S", "M", "T", "W", "T", "F", "S"]
  }

  private var currentMonthDates: [Date?] {
    let interval = calendar.dateInterval(of: .month, for: selectedDate)!
    let firstDay = interval.start
    let firstWeekday = calendar.component(.weekday, from: firstDay)

    // Calculate offset based on week start preference
    // weekday: 1 = Sunday, 2 = Monday, ..., 7 = Saturday
    let offset: Int
    if taskStore.weekStartsOnMonday {
      // Monday start: Monday=0, Tuesday=1, ..., Sunday=6
      offset = (firstWeekday + 5) % 7
    } else {
      // Sunday start: Sunday=0, Monday=1, ..., Saturday=6
      offset = firstWeekday - 1
    }

    var dates: [Date?] = Array(repeating: nil, count: offset)

    var current = firstDay
    while current < interval.end {
      dates.append(current)
      current = calendar.date(byAdding: .day, value: 1, to: current)!
    }

    // Pad to complete final week
    while dates.count % 7 != 0 {
      dates.append(nil)
    }

    return dates
  }

  private var monthYearString: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMMM yyyy"
    return formatter.string(from: selectedDate)
  }

  private var tasksForSelectedDay: [Task] {
    let tasks = taskStore.tasks.filter { task in
      guard let date = task.date else { return false }
      return calendar.isDate(date, inSameDayAs: selectedDate) && !task.isCompleted
    }
    if searchText.isEmpty {
      return tasks.sorted { ($0.date ?? Date.distantFuture) < ($1.date ?? Date.distantFuture) }
    } else {
      return tasks.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        .sorted { ($0.date ?? Date.distantFuture) < ($1.date ?? Date.distantFuture) }
    }
  }

  private var upcomingTasksCount: Int {
    let today = calendar.startOfDay(for: Date())
    let weekLater = calendar.date(byAdding: .day, value: 7, to: today)!
    return taskStore.tasks.filter { task in
      guard let date = task.date else { return false }
      return date >= today && date < weekLater && !task.isCompleted
    }.count
  }

  private func tasksCount(for date: Date) -> Int {
    taskStore.tasks.filter { task in
      guard let taskDate = task.date else { return false }
      return calendar.isDate(taskDate, inSameDayAs: date) && !task.isCompleted
    }.count
  }

  private var selectedDayFormatted: String {
    if calendar.isDateInToday(selectedDate) {
      return "Today"
    } else if calendar.isDateInTomorrow(selectedDate) {
      return "Tomorrow"
    } else if calendar.isDateInYesterday(selectedDate) {
      return "Yesterday"
    } else {
      let formatter = DateFormatter()
      formatter.dateFormat = "EEEE, MMM d"
      return formatter.string(from: selectedDate)
    }
  }

  // MARK: - Body

  var body: some View {
    NavigationStack(path: $navigationPath) {
      ScrollView(showsIndicators: false) {
        VStack(spacing: LayoutTokens.Spacing.xl) {
          if !searchText.isEmpty {
            searchResultsView
          } else {
            monthCalendarCard
            upcomingTasksCard
            dayDetailSection
          }
        }
        .padding(.horizontal, LayoutTokens.Padding.screenHorizontal(for: sizeClass))
        .padding(.bottom, LayoutTokens.Padding.scrollBottom)
      }
      .background(Color.clear.auroraBackground())
      .navigationTitle("Calendar")
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
            withAnimation {
              isSearching = true
            }
          }
        }

        ToolbarItem(placement: .topBarTrailing) {
          Button("Today", systemImage: "calendar.badge.clock") {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
              selectedDate = Date()
            }
          }
        }
        ToolbarSpacer(.fixed, placement: .topBarTrailing)

        ToolbarItem(placement: .topBarTrailing) {
          NavigationLink(value: "settings") {
            Image(systemName: "gearshape")
          }
        }
      }
      .navigationDestination(for: String.self) { destination in
        if destination == "settings" {
          SettingsView()
        }
      }
      .sheet(item: $selectedTaskForDetails) { task in
        TaskSheet(task: task)
          .presentationDetents([.large])
          .presentationDragIndicator(.visible)
      }
    }
  }

  // MARK: - Month Calendar Card

  private var monthCalendarCard: some View {
    VStack(spacing: LayoutTokens.Spacing.lg) {
      // Month header with navigation (glass effect)
      HStack {
        Button {
          withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            selectedDate =
              calendar.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
          }
        } label: {
          Image(systemName: "chevron.left")
            .font(.system(size: LayoutTokens.Typography.body, weight: .semibold))
            .foregroundStyle(Theme.primary)
            .frame(width: LayoutTokens.CardHeight.calendarNavButton, height: LayoutTokens.CardHeight.calendarNavButton)
            .glassEffect(.regular)
        }

        Spacer()

        Text(monthYearString)
          .font(.system(size: LayoutTokens.Typography.title3, weight: .bold))
          .foregroundStyle(.primary)
          .padding(.horizontal, LayoutTokens.Spacing.xl)
          .padding(.vertical, 10)
          .glassEffect(.regular)

        Spacer()

        Button {
          withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            selectedDate =
              calendar.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
          }
        } label: {
          Image(systemName: "chevron.right")
            .font(.system(size: LayoutTokens.Typography.body, weight: .semibold))
            .foregroundStyle(Theme.primary)
            .frame(width: LayoutTokens.CardHeight.calendarNavButton, height: LayoutTokens.CardHeight.calendarNavButton)
            .glassEffect(.regular)
        }
      }
      .padding(.horizontal, LayoutTokens.Spacing.sm)

      // Weekday headers
      LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: LayoutTokens.Spacing.sm) {
        ForEach(weekdays, id: \.self) { day in
          Text(day)
            .font(.system(size: LayoutTokens.Typography.caption, weight: .semibold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
        }
      }

      // Calendar grid
      LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: LayoutTokens.Spacing.sm) {
        ForEach(Array(currentMonthDates.enumerated()), id: \.offset) { _, date in
          if let date = date {
            dayCell(for: date)
          } else {
            Color.clear
              .frame(height: LayoutTokens.CardHeight.calendarDay)
          }
        }
      }
    }
    .padding(.horizontal, LayoutTokens.Padding.screenHorizontal(for: sizeClass))
  }

  private func dayCell(for date: Date) -> some View {
    let isToday = calendar.isDateInToday(date)
    let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
    let taskCount = tasksCount(for: date)
    let dayNumber = calendar.component(.day, from: date)

    return Button {
      withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
        selectedDate = date
      }
    } label: {
      VStack(spacing: LayoutTokens.Spacing.xs / 2) {
        Text("\(dayNumber)")
          .font(.system(size: LayoutTokens.Typography.callout, weight: isToday ? .bold : .medium))
          .foregroundStyle(isSelected ? .white : (isToday ? Theme.primary : .primary))

        // Task indicator dots
        if taskCount > 0 {
          Circle()
            .fill(isSelected ? .white.opacity(0.8) : Theme.primary)
            .frame(width: 5, height: 5)
        } else {
          Color.clear
            .frame(width: 5, height: 5)
        }
      }
      .frame(width: LayoutTokens.CardHeight.calendarDay, height: LayoutTokens.CardHeight.calendarDay)
      .background {
        if isSelected {
          Circle()
            .glassEffect(.regular.tint(Theme.primary))
            .matchedGeometryEffect(id: "selectedDay", in: namespace)
        } else if isToday {
          Circle()
            .strokeBorder(Theme.primary, lineWidth: 2)
        }
      }
    }
    .buttonStyle(.plain)
  }

  // MARK: - Upcoming Tasks Card

  private var upcomingTasksCard: some View {
    HStack(spacing: LayoutTokens.Spacing.lg) {
      // Icon
      ZStack {
        Circle()
          .fill(Theme.primary.opacity(0.2))
          .frame(width: LayoutTokens.IconSize.circleBackground, height: LayoutTokens.IconSize.circleBackground)

        Image(systemName: "calendar.badge.clock")
          .font(.system(size: LayoutTokens.IconSize.lg, weight: .medium))
          .foregroundStyle(Theme.primary)
      }

      // Text content
      VStack(alignment: .leading, spacing: LayoutTokens.Spacing.xs) {
        Text("Upcoming Tasks")
          .font(.system(size: LayoutTokens.Typography.subheadline, weight: .medium))
          .foregroundStyle(.secondary)

        HStack(alignment: .firstTextBaseline, spacing: LayoutTokens.Spacing.xs) {
          Text("\(upcomingTasksCount)")
            .font(.system(size: LayoutTokens.Typography.largeNumber, weight: .bold))
            .foregroundStyle(Theme.primary)

          Text(upcomingTasksCount == 1 ? "task" : "tasks")
            .font(.system(size: LayoutTokens.Typography.body, weight: .medium))
            .foregroundStyle(.secondary)
        }
      }

      Spacer()

      Text("Next 7 days")
        .font(.system(size: LayoutTokens.Typography.caption, weight: .medium))
        .foregroundStyle(.tertiary)
    }
    .padding(LayoutTokens.Padding.cardInner(for: sizeClass))
    .frame(maxWidth: .infinity)
    .glassEffect(.clear.tint(Theme.primary.opacity(0.15)))
  }

  // MARK: - Day Detail Section

  private var dayDetailSection: some View {
    VStack(alignment: .leading, spacing: LayoutTokens.Spacing.md) {
      Button {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
          dayDetailExpanded.toggle()
        }
      } label: {
        HStack {
          Text(selectedDayFormatted)
            .font(.system(size: LayoutTokens.Typography.title2, weight: .bold))
            .foregroundStyle(.primary)

          Image(systemName: dayDetailExpanded ? "chevron.down" : "chevron.right")
            .font(.system(size: LayoutTokens.Typography.subheadline, weight: .semibold))
            .foregroundStyle(.secondary)
            .contentTransition(.symbolEffect(.replace))

          Spacer()
        }
        .padding(.horizontal, LayoutTokens.Padding.sectionTitleInset)
      }
      .buttonStyle(.plain)

      if dayDetailExpanded {
        if tasksForSelectedDay.isEmpty {
          emptyDayState
        } else {
          VStack(spacing: LayoutTokens.Spacing.sm) {
            ForEach(tasksForSelectedDay) { task in
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
          .transition(.opacity.combined(with: .move(edge: .top)))
        }
      }
    }
  }

  private var emptyDayState: some View {
    VStack(spacing: LayoutTokens.Spacing.md) {
      Image(systemName: "calendar.badge.checkmark")
        .font(.system(size: LayoutTokens.Typography.emptyStateIcon))
        .foregroundStyle(.secondary.opacity(0.5))

      Text("No tasks scheduled")
        .font(.system(size: LayoutTokens.Typography.callout))
        .foregroundStyle(.secondary)

      Text("Enjoy your free time!")
        .font(.system(size: LayoutTokens.Typography.footnote))
        .foregroundStyle(.tertiary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, LayoutTokens.Spacing.xxl * 2)
  }

  // MARK: - Search Results

  private var searchResultsView: some View {
    VStack(spacing: LayoutTokens.Spacing.sm) {
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
}
