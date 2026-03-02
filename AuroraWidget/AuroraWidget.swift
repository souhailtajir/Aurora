//
//  AuroraWidget.swift
//  AuroraWidget
//
//  Created on 1/21/26.
//

import SwiftData
import SwiftUI
import WidgetKit

struct Provider: TimelineProvider {
  // Helper to get a container for the widget
  // Ideally this shares the same persistence logic as the main app
  @MainActor
  private func getContainer() -> ModelContainer? {
    let schema = Schema([
      Task.self,
      TaskCategory.self,
      JournalEntry.self,
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
    return try? ModelContainer(for: schema, configurations: [modelConfiguration])
  }

  @MainActor
  private func fetchTodaysTasks() -> [Task] {
    guard let container = getContainer() else { return [] }
    let context = container.mainContext

    // Simple logic: Fetch all incomplete tasks (optimization needed for "Today" predicate in real app)
    let descriptor = FetchDescriptor<Task>(
      sortBy: [SortDescriptor(\.date)]
    )

    do {
      let allTasks = try context.fetch(descriptor)
      // Filter in memory for simplicity in this snippet,
      // ideally use a complex predicate for "Today"
      return allTasks.filter { task in
        guard let date = task.date else { return false }
        return Calendar.current.isDateInToday(date) && !task.isCompleted
      }.sorted { ($0.date ?? Date.distantFuture) < ($1.date ?? Date.distantFuture) }
    } catch {
      return []
    }
  }

  func placeholder(in context: Context) -> SimpleEntry {
    SimpleEntry(date: Date(), tasks: [])
  }

  func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
    Task { @MainActor in
      let tasks = fetchTodaysTasks()
      let entry = SimpleEntry(date: Date(), tasks: tasks)
      completion(entry)
    }
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
    Task { @MainActor in
      let tasks = fetchTodaysTasks()

      // Refresh timeline every 15 minutes or when data changes
      let entry = SimpleEntry(date: Date(), tasks: tasks)
      let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
      let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
      completion(timeline)
    }
  }
}

struct SimpleEntry: TimelineEntry {
  let date: Date
  let tasks: [Task]
}

struct AuroraWidgetEntryView: View {
  var entry: Provider.Entry
  @Environment(\.widgetFamily) var family
  @Environment(\.colorScheme) var colorScheme

  var body: some View {
    ZStack {
      // Background Theme
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

      VStack(alignment: .leading, spacing: 0) {
        header

        if entry.tasks.isEmpty {
          emptyState
        } else {
          tasksList
        }

        Spacer(minLength: 0)
      }
    }
  }

  private var header: some View {
    HStack {
      Text(entry.date.formatted(.dateTime.weekday(.wide)))
        .font(.headline)
        .foregroundStyle(Color(red: 0.4, green: 0.35, blue: 0.9))  // App's primary theme color

      Spacer()

      Text("\(entry.tasks.count)")
        .font(.caption.weight(.bold))
        .padding(6)
        .background(Circle().fill(.white.opacity(0.2)))
    }
    .padding(.horizontal, 16)
    .padding(.top, 16)
    .padding(.bottom, 12)
  }

  private var emptyState: some View {
    VStack {
      Spacer()
      Image(systemName: "checkmark.circle")
        .font(family == .systemSmall ? .title : .largeTitle)
        .foregroundStyle(Color(red: 0.4, green: 0.35, blue: 0.9))
      Text("All Clear")
        .font(.caption)
        .foregroundStyle(.secondary)
      Spacer()
    }
    .frame(maxWidth: .infinity)
    .padding(.horizontal, 16)
  }

  private var tasksList: some View {
    VStack(spacing: 8) {
      ForEach(entry.tasks.prefix(maxTasks)) { task in
        HStack(alignment: .center, spacing: 12) {
          // Interactive Toggle
          Button(intent: ToggleTaskIntent(taskId: task.id.uuidString)) {
            Circle()
              .fill(task.isCompleted ? Color(red: 0.4, green: 0.35, blue: 0.9) : Color.clear)
              .frame(width: 20, height: 20)
              .overlay(
                Circle()
                  .strokeBorder(Color(red: 0.4, green: 0.35, blue: 0.9), lineWidth: 2)
              )
              .overlay {
                if task.isCompleted {
                  Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                }
              }
          }
          .buttonStyle(.plain)

          VStack(alignment: .leading, spacing: 2) {
            Text(task.title)
              .font(.system(size: 14))
              .foregroundStyle(task.isCompleted ? .secondary : .primary)
              .lineLimit(1)
              .strikethrough(task.isCompleted)

            if let date = task.date {
              Text(date.formatted(date: .omitted, time: .shortened))
                .font(.system(size: 11))
                .foregroundStyle(task.isCompleted ? .secondary.opacity(0.8) : .secondary)
            }
          }
          Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .glassEffect(.regular)
        .clipShape(RoundedRectangle(cornerRadius: 12))
      }
    }
    .padding(.horizontal, 16)
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

@main
struct AuroraWidget: Widget {
  let kind: String = "AuroraWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: Provider()) { entry in
      AuroraWidgetEntryView(entry: entry)
        .containerBackground(.clear, for: .widget)
    }
    .configurationDisplayName("Today's Agenda")
    .description("View and complete your daily tasks.")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
  }
}
