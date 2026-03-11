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
      // 1. App-consistent Aurora Background with Floating Orbs
      WidgetAuroraBackground()

      // 2. Status Bar Vignette (The "Notch/Status Bar" look from the app)
      VStack(spacing: 0) {
        LinearGradient(
          colors: [.black.opacity(colorScheme == .dark ? 0.3 : 0.1), .clear],
          startPoint: .top,
          endPoint: .bottom
        )
        .frame(height: family == .systemSmall ? 40 : 60)
        Spacer()
      }

      // 3. Main Content
      VStack(alignment: .leading, spacing: 0) {
        headerSection

        if family == .systemLarge {
          premiumProgressBar
            .padding(.bottom, 16)
        }

        if entry.tasks.isEmpty {
          heroEmptyState
        } else {
          tasksList
        }

        Spacer(minLength: 0)
      }
    }
  }

  // MARK: - Premium Background

  private struct WidgetAuroraBackground: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
      ZStack {
        // Base gradient
        if colorScheme == .dark {
          Color(hex: "0C0A14") // Deep Obsidian
        } else {
          Color(hex: "F8F7FB") // Soft Snow
        }

        // Floating "Aurora Orbs" for depth
        Circle()
          .fill(Theme.primary.opacity(0.15))
          .blur(radius: 40)
          .offset(x: -80, y: -60)

        Circle()
          .fill(Theme.secondary.opacity(0.12))
          .blur(radius: 50)
          .offset(x: 100, y: 80)

        // Celestial Accent (The app's brand identifier)
        VStack {
          HStack {
            Spacer()
            Image(systemName: colorScheme == .dark ? "moon.stars.fill" : "sun.max.fill")
              .font(.system(size: 40, weight: .thin))
              .foregroundStyle(Theme.primary.opacity(0.1))
              .offset(x: 10, y: -10)
          }
          Spacer()
        }
      }
    }
  }

  // MARK: - Header Section

  private var headerSection: some View {
    HStack(alignment: .center) {
      VStack(alignment: .leading, spacing: 1) {
        // Linear gradient on the weekday text for a "State of the Art" look
        Text(entry.date.formatted(.dateTime.weekday(.wide)))
          .font(.system(size: 20, weight: .black, design: .rounded))
          .foregroundStyle(
            LinearGradient(
              colors: [Theme.primary, Theme.secondary],
              startPoint: .leading,
              endPoint: .trailing
            )
          )

        if family != .systemSmall {
          Text(entry.date.formatted(.dateTime.month(.wide).day()))
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundStyle(.secondary.opacity(0.7))
        }
      }

      Spacer()

      // High-gloss task pill
      HStack(spacing: 4) {
        Text("\(entry.tasks.count)")
          .font(.system(size: 14, weight: .black, design: .rounded))
      }
      .foregroundStyle(.white)
      .padding(.horizontal, 12)
      .padding(.vertical, 6)
      .background {
        Capsule()
          .fill(Theme.primary)
          .shadow(color: Theme.primary.opacity(0.4), radius: 8, x: 0, y: 4)
      }
    }
    .padding(.horizontal, 20)
    .padding(.top, 20)
    .padding(.bottom, family == .systemSmall ? 10 : 16)
  }

  // MARK: - Premium Progress Bar

  private var premiumProgressBar: some View {
    let total = max(entry.totalToday, 1)
    let progress = CGFloat(entry.completedToday) / CGFloat(total)
    let percentage = entry.totalToday > 0 ? (entry.completedToday * 100) / entry.totalToday : 0

    return VStack(alignment: .leading, spacing: 10) {
      HStack {
        Label("Daily Goal", systemImage: "sparkles")
          .font(.system(size: 12, weight: .bold, design: .rounded))
          .foregroundStyle(.secondary)
        Spacer()
        Text("\(percentage)%")
          .font(.system(size: 12, weight: .black, design: .rounded))
          .foregroundStyle(Theme.primary)
      }

      ZStack(alignment: .leading) {
        Capsule()
          .fill(.white.opacity(colorScheme == .dark ? 0.05 : 0.3))
          .frame(height: 10)
          .glassEffect(.clear)

        Capsule()
          .fill(
            LinearGradient(
              colors: [Theme.primary, Theme.secondary],
              startPoint: .leading,
              endPoint: .trailing
            )
          )
          .frame(width: max(0, 200 * progress), height: 10) // Approx width
          .shadow(color: Theme.primary.opacity(0.5), radius: 5, x: 0, y: 0)
      }
      .frame(height: 10)
    }
    .padding(.horizontal, 20)
  }

  // MARK: - Hero Empty State

  private var heroEmptyState: some View {
    VStack(spacing: 20) {
      Spacer()
      
      ZStack {
        // Nested symbols for a "Medal" effect
        Circle()
          .fill(Theme.primary.opacity(0.1))
          .frame(width: 80, height: 80)
        
        Circle()
          .strokeBorder(
            LinearGradient(colors: [Theme.primary, Theme.secondary], startPoint: .top, endPoint: .bottom),
            lineWidth: 2
          )
          .frame(width: 80, height: 80)

        Image(systemName: "star.fill")
          .font(.system(size: 40))
          .foregroundStyle(
            LinearGradient(colors: [Theme.primary, Theme.secondary], startPoint: .top, endPoint: .bottom)
          )
        
        Image(systemName: "checkmark")
          .font(.system(size: 20, weight: .black))
          .foregroundStyle(.white)
          .offset(y: 2)
      }
      .shadow(color: Theme.primary.opacity(0.3), radius: 15)

      VStack(spacing: 6) {
        Text("Mission Accomplished")
          .font(.system(size: 17, weight: .black, design: .rounded))
          .foregroundStyle(.primary)

        Text("All clear for takeoff.")
          .font(.system(size: 13, weight: .bold, design: .rounded))
          .foregroundStyle(.secondary)
      }
      
      Spacer()
    }
    .frame(maxWidth: .infinity)
  }

  // MARK: - Tasks List

  private var tasksList: some View {
    VStack(spacing: family == .systemSmall ? 8 : 12) {
      ForEach(entry.tasks.prefix(maxTasks)) { task in
        taskRow(task)
      }

      // Overflow indicator
      if entry.tasks.count > maxTasks {
        HStack(spacing: 4) {
          Rectangle()
            .fill(.secondary.opacity(0.3))
            .frame(height: 1)
          Text("+\(entry.tasks.count - maxTasks) more")
            .font(.system(size: 11, weight: .black, design: .rounded))
            .foregroundStyle(.secondary.opacity(0.8))
          Rectangle()
            .fill(.secondary.opacity(0.3))
            .frame(height: 1)
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
      }
    }
    .padding(.horizontal, 20)
  }

  // MARK: - Individual Task Row

  private func taskRow(_ task: AppTask) -> some View {
    let categoryColor = taskCategoryColor(task)

    return HStack(alignment: .center, spacing: 14) {
      // Tactile Toggle
      Button(intent: ToggleTaskIntent(taskId: task.id.uuidString)) {
        ZStack {
          Circle()
            .strokeBorder(
              task.isCompleted ? categoryColor : .primary.opacity(0.15),
              lineWidth: 2
            )
            .background(
              Circle()
                .fill(task.isCompleted ? categoryColor : .white.opacity(colorScheme == .dark ? 0.05 : 0.8))
            )
            .frame(width: 24, height: 24)
            .shadow(color: task.isCompleted ? categoryColor.opacity(0.4) : .clear, radius: 4)
          
          if task.isCompleted {
            Image(systemName: "checkmark")
              .font(.system(size: 11, weight: .black))
              .foregroundStyle(.white)
          }
        }
      }
      .buttonStyle(.plain)

      // Task Info
      VStack(alignment: .leading, spacing: 3) {
        HStack(spacing: 8) {
          // Priority "Pill" with Glow
          if task.priority == .high {
            Capsule()
              .fill(.red)
              .frame(width: 4, height: 16)
              .shadow(color: .red.opacity(0.5), radius: 3)
          } else if task.priority == .medium {
            Capsule()
              .fill(.orange)
              .frame(width: 4, height: 16)
              .shadow(color: .orange.opacity(0.5), radius: 3)
          }

          Text(task.title)
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(task.isCompleted ? .secondary : .primary)
            .lineLimit(1)
            .strikethrough(task.isCompleted)
        }

        if family != .systemSmall, let date = task.date, hasTimeComponent(date) {
          HStack(spacing: 4) {
            Image(systemName: "clock.fill")
              .font(.system(size: 10))
            Text(date.formatted(date: .omitted, time: .shortened))
              .font(.system(size: 12, weight: .black, design: .rounded))
          }
          .foregroundStyle(.secondary.opacity(0.8))
        }
      }

      Spacer(minLength: 0)

      // Glassy Flag
      if task.isFlagged {
        Image(systemName: "flag.fill")
          .font(.system(size: 12))
          .foregroundStyle(.orange)
          .padding(6)
          .background {
            Circle()
              .fill(.orange.opacity(0.1))
              .glassEffect(.clear)
          }
          .shadow(color: .orange.opacity(0.2), radius: 4)
      }
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 12)
    .background {
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .fill(.white.opacity(colorScheme == .dark ? 0.03 : 0.4))
        .glassEffect(.clear)
    }
    .overlay {
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .strokeBorder(.white.opacity(colorScheme == .dark ? 0.05 : 0.2), lineWidth: 1)
    }
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
