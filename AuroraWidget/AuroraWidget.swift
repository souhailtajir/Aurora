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

  var body: some View {
    ZStack {
      Theme.auroraBackground

      VStack(alignment: .leading, spacing: 0) {
        header

        if family == .systemLarge {
          progressBar
            .padding(.bottom, 12)
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

  // MARK: - Header

  private var header: some View {
    HStack(alignment: .center) {
      VStack(alignment: .leading, spacing: 2) {
        Text(entry.date.formatted(.dateTime.weekday(.wide)))
          .font(.system(size: 18, weight: .bold, design: .rounded))
          .foregroundStyle(Theme.primary)

        if family != .systemSmall {
          Text(entry.date.formatted(.dateTime.month(.abbreviated).day()))
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(.secondary)
        }
      }

      Spacer()

      Text("\(entry.tasks.count)")
        .font(.system(size: 13, weight: .bold, design: .rounded))
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
          Capsule()
            .fill(Theme.primary)
            .shadow(color: Theme.primary.opacity(0.3), radius: 4, x: 0, y: 2)
        )
    }
    .padding(.horizontal, 16)
    .padding(.top, 16)
    .padding(.bottom, family == .systemSmall ? 8 : 12)
  }

  // MARK: - Progress Bar (Large only)

  private var progressBar: some View {
    let total = max(entry.totalToday, 1)
    let progress = CGFloat(entry.completedToday) / CGFloat(total)
    let percentage = entry.totalToday > 0 ? (entry.completedToday * 100) / entry.totalToday : 0

    return VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text("Daily Progress")
          .font(.system(size: 12, weight: .bold, design: .rounded))
          .foregroundStyle(.secondary)
        Spacer()
        Text("\(entry.completedToday)/\(entry.totalToday)")
          .font(.system(size: 12, weight: .heavy, design: .rounded))
          .foregroundStyle(Theme.secondary)
      }

      GeometryReader { geo in
        ZStack(alignment: .leading) {
          Capsule()
            .fill(.gray.opacity(0.15))
            .frame(height: 8)
          Capsule()
            .fill(
              LinearGradient(
                colors: [Theme.primary, Theme.secondary],
                startPoint: .leading,
                endPoint: .trailing
              )
            )
            .frame(width: geo.size.width * progress, height: 8)
            .shadow(color: Theme.primary.opacity(0.3), radius: 3, x: 0, y: 1)
        }
      }
      .frame(height: 8)

      Text("\(percentage)% done")
        .font(.system(size: 10, weight: .medium, design: .rounded))
        .foregroundStyle(.tertiary)
    }
    .padding(.horizontal, 16)
  }

  // MARK: - Empty State

  private var emptyState: some View {
    VStack(spacing: 12) {
      Spacer()
      Image(systemName: "checkmark.seal.fill")
        .font(.system(size: family == .systemSmall ? 32 : 44))
        .foregroundStyle(
          LinearGradient(
            colors: [Theme.primary, Theme.secondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .symbolRenderingMode(.hierarchical)
      
      VStack(spacing: 4) {
        // Updated wording for a more premium vibe
        Text("Mission Accomplished")
          .font(.system(size: 15, weight: .bold, design: .rounded))
          .foregroundStyle(.primary.opacity(0.8))
        
        if family != .systemSmall {
          Text("You've cleared your agenda for today")
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
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
          .font(.system(size: 11, weight: .bold, design: .rounded))
          .foregroundStyle(.secondary.opacity(0.8))
          .frame(maxWidth: .infinity, alignment: .center)
          .padding(.top, 4)
      }
    }
    .padding(.horizontal, 16)
  }

  // MARK: - Individual Task Row

  private func taskRow(_ task: AppTask) -> some View {
    let categoryColor = taskCategoryColor(task)

    return HStack(alignment: .center, spacing: family == .systemSmall ? 10 : 12) {
      // Toggle button
      Button(intent: ToggleTaskIntent(taskId: task.id.uuidString)) {
        ZStack {
          Circle()
            .strokeBorder(categoryColor, lineWidth: 2)
            .background(Circle().fill(task.isCompleted ? categoryColor : .clear))
            .frame(width: family == .systemSmall ? 20 : 24, height: family == .systemSmall ? 20 : 24)
          
          if task.isCompleted {
            Image(systemName: "checkmark")
              .font(.system(size: family == .systemSmall ? 9 : 11, weight: .bold))
              .foregroundStyle(.white)
          }
        }
      }
      .buttonStyle(.plain)

      // Task info
      VStack(alignment: .leading, spacing: 2) {
        HStack(spacing: 6) {
          // Priority dot
          if task.priority == .high {
            Circle()
              .fill(.red)
              .frame(width: 8, height: 8)
              .shadow(color: .red.opacity(0.3), radius: 2)
          } else if task.priority == .medium {
            Circle()
              .fill(.orange)
              .frame(width: 8, height: 8)
              .shadow(color: .orange.opacity(0.3), radius: 2)
          }

          Text(task.title)
            .font(.system(size: family == .systemSmall ? 14 : 15, weight: .medium, design: .rounded))
            .foregroundStyle(task.isCompleted ? .secondary : .primary)
            .lineLimit(1)
            .strikethrough(task.isCompleted)
        }

        if family != .systemSmall, let date = task.date, hasTimeComponent(date) {
          HStack(spacing: 4) {
            Image(systemName: "clock")
              .font(.system(size: 10))
            Text(date.formatted(date: .omitted, time: .shortened))
              .font(.system(size: 12, weight: .medium, design: .rounded))
          }
          .foregroundStyle(.secondary)
        }
      }

      Spacer(minLength: 0)

      // Flag indicator
      if task.isFlagged {
        Image(systemName: "flag.fill")
          .font(.system(size: family == .systemSmall ? 11 : 13))
          .foregroundStyle(.orange)
          .shadow(color: .orange.opacity(0.2), radius: 2)
      }
    }
    .padding(.horizontal, 12)
    .padding(.vertical, family == .systemSmall ? 8 : 10)
    .glassEffect(.regular)
    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
  }

  // MARK: - Helpers

  private func taskCategoryColor(_ task: AppTask) -> Color {
    guard let hex = task.category?.colorHex else {
      return Theme.primary
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
