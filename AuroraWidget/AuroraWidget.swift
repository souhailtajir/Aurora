//
//  AuroraWidget.swift
//  AuroraWidget
//
//  Created on 1/21/26.
//

import WidgetKit
import SwiftUI
import SwiftData

struct Provider: TimelineProvider {
    // Helper to get a container for the widget
    // Ideally this shares the same persistence logic as the main app
    @MainActor
    private func getContainer() -> ModelContainer? {
        let schema = Schema([
            Task.self,
            TaskCategory.self,
            JournalEntry.self
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

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        Task { @MainActor in
            let tasks = fetchTodaysTasks()
            let entry = SimpleEntry(date: Date(), tasks: tasks)
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
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

struct AuroraWidgetEntryView : View {
    var entry: Provider.Entry
    
    // Hardcoded colors for now to match app theme
    let backgroundColor = Color(red: 0.1, green: 0.1, blue: 0.15)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text(entry.date.formatted(.dateTime.weekday(.wide)))
                    .font(.headline)
                    .foregroundStyle(.red) // Accent color
                
                Spacer()
                
                Text("\(entry.tasks.count)")
                    .font(.caption.weight(.bold))
                    .padding(6)
                    .background(Circle().fill(.white.opacity(0.2)))
            }
            .padding(.bottom, 8)
            
            // Tasks List
            if entry.tasks.isEmpty {
                VStack {
                    Spacer()
                    Image(systemName: "checkmark.circle")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("All Clear")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 8) {
                    // Show top 3 tasks
                    ForEach(entry.tasks.prefix(3)) { task in
                        HStack(alignment: .top, spacing: 8) {
                            // Interactive Toggle
                            Button(intent: ToggleTaskIntent(taskId: task.id.uuidString)) {
                                Image(systemName: "circle")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.title)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                    .strikethrough(task.isCompleted)
                                
                                if let date = task.date {
                                    Text(date.formatted(date: .omitted, time: .shortened))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                        }
                    }
                }
            }
            Spacer()
        }
        .containerBackground(backgroundColor, for: .widget)
    }
}

@main
struct AuroraWidget: Widget {
    let kind: String = "AuroraWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            AuroraWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Today's Agenda")
        .description("View and complete your daily tasks.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
