//
//  AuroraWidget.swift
//  AuroraWidget
//
//  Rewritten from scratch.
//

import AppIntents
import SwiftData
import SwiftUI
import WidgetKit

// MARK: - Shared ModelContainer

enum ModelContainerHelper {
  @MainActor
  static func shared() -> ModelContainer? {
    let schema = Schema([
      AppTask.self,
      TaskCategory.self,
      JournalEntry.self,
    ])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
    return try? ModelContainer(for: schema, configurations: [config])
  }
}

// MARK: - Timeline Provider

struct Provider: TimelineProvider {
  @MainActor
  private func fetchTodaysTasks() -> [AppTask] {
    guard let container = ModelContainerHelper.shared() else { return [] }
    let context = container.mainContext
    let descriptor = FetchDescriptor<AppTask>(sortBy: [SortDescriptor(\.date)])

    guard let allTasks = try? context.fetch(descriptor) else { return [] }

    return
      allTasks
      .filter { task in
        guard let date = task.date else { return false }
        return Calendar.current.isDateInToday(date) && !task.isCompleted
      }
      .sorted { ($0.date ?? .distantFuture) < ($1.date ?? .distantFuture) }
  }

  func placeholder(in context: Context) -> TaskEntry {
    TaskEntry(date: Date(), tasks: [], totalToday: 0, completedToday: 0)
  }

  func getSnapshot(in context: Context, completion: @escaping (TaskEntry) -> Void) {
    _Concurrency.Task { @MainActor in
      let tasks = fetchTodaysTasks()
      let stats = todayStats()
      completion(
        TaskEntry(
          date: Date(), tasks: tasks, totalToday: stats.total, completedToday: stats.completed))
    }
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<TaskEntry>) -> Void) {
    _Concurrency.Task { @MainActor in
      let tasks = fetchTodaysTasks()
      let stats = todayStats()
      let entry = TaskEntry(
        date: Date(), tasks: tasks, totalToday: stats.total, completedToday: stats.completed)
      let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
      completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
  }

  @MainActor
  private func todayStats() -> (total: Int, completed: Int) {
    guard let container = ModelContainerHelper.shared() else { return (0, 0) }
    let context = container.mainContext
    let descriptor = FetchDescriptor<AppTask>(sortBy: [SortDescriptor(\.date)])
    guard let allTasks = try? context.fetch(descriptor) else { return (0, 0) }

    let todayTasks = allTasks.filter { task in
      guard let date = task.date else { return false }
      return Calendar.current.isDateInToday(date)
    }
    let completed = todayTasks.filter(\.isCompleted).count
    return (todayTasks.count, completed)
  }
}

// MARK: - Timeline Entry

struct TaskEntry: TimelineEntry {
  let date: Date
  let tasks: [AppTask]
  let totalToday: Int
  let completedToday: Int
}

// MARK: - Widget Entry View

struct AuroraWidgetEntryView: View {
  var entry: Provider.Entry
  @Environment(\.widgetFamily) var family
  @Environment(\.colorScheme) var colorScheme

  // MARK: Theme Colors (mirroring Theme.swift)

  private var themePrimary: Color { Color(red: 0.4, green: 0.35, blue: 0.9) }
  private var themeSecondary: Color { Color(red: 0.5, green: 0.4, blue: 0.95) }

  var body: some View {
    ZStack {
      background

      VStack(alignment: .leading, spacing: 0) {
        header

        if family == .systemLarge {
          progressBar
            .padding(.bottom, 10)
        }

        if entry.tasks.isEmpty {
          emptyState
        } else {
          tasksList
        }

        Spacer(minLength: 0)
      }
    }
  }

  // MARK: - Background

  private var background: some View {
    ZStack {
      if colorScheme == .dark {
        Color.black
        LinearGradient(
          colors: [
            Color(red: 91 / 255, green: 80 / 255, blue: 160 / 255).opacity(0.4),
            Color(red: 45 / 255, green: 27 / 255, blue: 105 / 255).opacity(0.2),
            .clear,
          ],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      } else {
        Color(red: 0.96, green: 0.95, blue: 0.98)
        LinearGradient(
          colors: [
            Color(red: 232 / 255, green: 212 / 255, blue: 255 / 255).opacity(0.5),
            Color(red: 212 / 255, green: 196 / 255, blue: 255 / 255).opacity(0.3),
            .clear,
          ],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      }
    }
  }

  // MARK: - Header

  private var header: some View {
    HStack(alignment: .center) {
      VStack(alignment: .leading, spacing: 2) {
        Text(entry.date.formatted(.dateTime.weekday(.wide)))
          .font(.headline.weight(.bold))
          .foregroundStyle(themePrimary)

        if family != .systemSmall {
          Text(entry.date.formatted(.dateTime.month(.abbreviated).day()))
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
      }

      Spacer()

      Text("\(entry.tasks.count)")
        .font(.caption.weight(.bold))
        .foregroundStyle(themePrimary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
          Capsule().fill(themePrimary.opacity(0.15))
        )
    }
    .padding(.horizontal, 16)
    .padding(.top, 14)
    .padding(.bottom, family == .systemSmall ? 8 : 10)
  }

  // MARK: - Progress Bar (Large only)

  private var progressBar: some View {
    let total = max(entry.totalToday, 1)
    let progress = CGFloat(entry.completedToday) / CGFloat(total)
    let percentage = entry.totalToday > 0 ? (entry.completedToday * 100) / entry.totalToday : 0

    return VStack(alignment: .leading, spacing: 6) {
      HStack {
        Text("Daily Progress")
          .font(.caption.weight(.medium))
          .foregroundStyle(.secondary)
        Spacer()
        Text("\(entry.completedToday)/\(entry.totalToday)")
          .font(.caption.weight(.bold))
          .foregroundStyle(themeSecondary)
      }

      GeometryReader { geo in
        ZStack(alignment: .leading) {
          Capsule()
            .fill(.gray.opacity(0.2))
            .frame(height: 6)
          Capsule()
            .fill(
              LinearGradient(
                colors: [themePrimary, themeSecondary],
                startPoint: .leading,
                endPoint: .trailing
              )
            )
            .frame(width: geo.size.width * progress, height: 6)
        }
      }
      .frame(height: 6)

      Text("\(percentage)% done")
        .font(.caption2)
        .foregroundStyle(.tertiary)
    }
    .padding(.horizontal, 16)
  }

  // MARK: - Empty State

  private var emptyState: some View {
    VStack(spacing: 8) {
      Spacer()
      Image(systemName: "checkmark.seal.fill")
        .font(family == .systemSmall ? .title2 : .largeTitle)
        .foregroundStyle(themePrimary)
        .symbolRenderingMode(.hierarchical)
      Text("All Clear!")
        .font(.subheadline.weight(.medium))
        .foregroundStyle(.secondary)
      if family != .systemSmall {
        Text("No tasks remaining for today")
          .font(.caption2)
          .foregroundStyle(.tertiary)
      }
      Spacer()
    }
    .frame(maxWidth: .infinity)
  }

  // MARK: - Tasks List

  private var tasksList: some View {
    VStack(spacing: family == .systemSmall ? 6 : 8) {
      ForEach(entry.tasks.prefix(maxTasks)) { task in
        taskRow(task)
      }

      // Overflow indicator
      if entry.tasks.count > maxTasks {
        Text("+\(entry.tasks.count - maxTasks) more")
          .font(.caption2.weight(.medium))
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity, alignment: .center)
          .padding(.top, 2)
      }
    }
    .padding(.horizontal, 16)
  }

  // MARK: - Individual Task Row

  private func taskRow(_ task: AppTask) -> some View {
    let categoryColor = taskCategoryColor(task)

    return HStack(alignment: .center, spacing: family == .systemSmall ? 8 : 10) {
      // Toggle button
      Button(intent: ToggleTaskIntent(taskId: task.id.uuidString)) {
        Circle()
          .fill(task.isCompleted ? categoryColor : .clear)
          .frame(width: family == .systemSmall ? 18 : 22, height: family == .systemSmall ? 18 : 22)
          .overlay(
            Circle()
              .strokeBorder(categoryColor, lineWidth: 2)
          )
          .overlay {
            if task.isCompleted {
              Image(systemName: "checkmark")
                .font(.system(size: family == .systemSmall ? 8 : 10, weight: .bold))
                .foregroundStyle(.white)
            }
          }
      }
      .buttonStyle(.plain)

      // Task info
      VStack(alignment: .leading, spacing: 2) {
        HStack(spacing: 4) {
          // Priority dot
          if task.priority == .high {
            Circle()
              .fill(.red)
              .frame(width: 6, height: 6)
          } else if task.priority == .medium {
            Circle()
              .fill(.orange)
              .frame(width: 6, height: 6)
          }

          Text(task.title)
            .font(.system(size: family == .systemSmall ? 13 : 14, weight: .regular))
            .foregroundStyle(task.isCompleted ? .secondary : .primary)
            .lineLimit(1)
            .strikethrough(task.isCompleted)
        }

        if family != .systemSmall, let date = task.date, hasTimeComponent(date) {
          HStack(spacing: 3) {
            Image(systemName: "clock")
              .font(.system(size: 9))
            Text(date.formatted(date: .omitted, time: .shortened))
              .font(.system(size: 11))
          }
          .foregroundStyle(.secondary)
        }
      }

      Spacer(minLength: 0)

      // Flag indicator
      if task.isFlagged {
        Image(systemName: "flag.fill")
          .font(.system(size: family == .systemSmall ? 10 : 12))
          .foregroundStyle(.orange)
      }
    }
    .padding(.horizontal, family == .systemSmall ? 8 : 12)
    .padding(.vertical, family == .systemSmall ? 6 : 8)
    .glassEffect(.regular)
    .clipShape(RoundedRectangle(cornerRadius: 10))
  }

  // MARK: - Helpers

  private func taskCategoryColor(_ task: AppTask) -> Color {
    guard let hex = task.category?.colorHex else {
      return themePrimary
    }
    return Color(hex: hex)
  }

  private func hasTimeComponent(_ date: Date) -> Bool {
    let cal = Calendar.current
    return cal.component(.hour, from: date) != 0 || cal.component(.minute, from: date) != 0
  }

  private var maxTasks: Int {
    switch family {
    case .systemSmall: return 2
    case .systemMedium: return 3
    case .systemLarge: return 6
    default: return 3
    }
  }
}

// MARK: - Widget Configuration

struct AuroraWidget: Widget {
  let kind: String = "AuroraWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: Provider()) { entry in
      AuroraWidgetEntryView(entry: entry)
        .containerBackground(.clear, for: .widget)
    }
    .configurationDisplayName("Today's Agenda")
    .description("View and complete your daily tasks at a glance.")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
  }
}
