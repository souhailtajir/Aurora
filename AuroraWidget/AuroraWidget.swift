//
//  AuroraWidgets.swift
//  AuroraWidget Extension
//
//  Swift 6.2 · iOS 26+ · WidgetKit + SwiftUI + SwiftData
//
//  Two widget variants for each app tab:
//    • Tab 1 · Today      — TodayAgendaWidget (replaces existing) + TodayPulseWidget
//    • Tab 2 · Tasks      — TasksByPriorityWidget                 + CategoryRingWidget
//    • Tab 3 · Journal    — JournalPreviewWidget                  + JournalStreakWidget
//    • Tab 4 · Stats      — WeeklyStatsWidget                     + StreakBadgeWidget
//
//  Prerequisites already in your project:
//    • AppTask, TaskCategory, JournalEntry  — SwiftData models
//    • Theme.primary / Theme.secondary      — Color tokens
//    • Color(hex:)                          — String → Color init
//    • ToggleTaskIntent(taskId:)            — AppIntent
//    • ModelContainerHelper.shared()        — shared container
//

import AppIntents
import SwiftData
import SwiftUI
import WidgetKit

// MARK: - Shared Aurora Background (matches existing WidgetAuroraBackground)

private struct AuroraBackground: View {
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        ZStack {
            (scheme == .dark ? Color(hex: "0C0A14") : Color(hex: "F8F7FB"))
                .ignoresSafeArea()
            
            // Primary Glow
            MeshGradient(width: 3, height: 3, points: [
                [0, 0], [0.5, 0], [1, 0],
                [0, 0.5], [0.5, 0.5], [1, 0.5],
                [0, 1], [0.5, 1], [1, 1]
            ], colors: [
                Theme.primary.opacity(0.1), Theme.primary.opacity(0.2), Theme.secondary.opacity(0.1),
                Theme.secondary.opacity(0.15), Theme.primary.opacity(0.1), Theme.secondary.opacity(0.2),
                Theme.primary.opacity(0.2), Theme.secondary.opacity(0.1), Theme.primary.opacity(0.1)
            ])
            .ignoresSafeArea()
            .blur(radius: 60)
            
            // Accents
            Circle()
                .fill(Theme.primary.opacity(0.12))
                .blur(radius: 45)
                .offset(x: -60, y: -40)
            Circle()
                .fill(Theme.secondary.opacity(0.1))
                .blur(radius: 55)
                .offset(x: 80, y: 60)
        }
    }
}

// MARK: - Shared Glass Card Modifier

private struct GlassCard: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.white.opacity(scheme == .dark ? 0.05 : 0.5))
                    .glassEffect(.clear)
                    .shadow(color: .black.opacity(scheme == .dark ? 0.15 : 0.05), radius: 10, x: 0, y: 4)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                .white.opacity(scheme == .dark ? 0.12 : 0.4),
                                .white.opacity(scheme == .dark ? 0.04 : 0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
    }
}

private extension View {
    func glassCard() -> some View { modifier(GlassCard()) }
}

// ═══════════════════════════════════════════════════════════════
// MARK: - UNIFIED TIMELINE ENTRY + PROVIDER
// ═══════════════════════════════════════════════════════════════

struct AuroraEntry: TimelineEntry {
    let date: Date
    // Today / Tasks
    let pendingTodayTasks: [AppTask]
    let totalToday: Int
    let completedToday: Int
    let allPendingTasks: [AppTask]
    // Journal
    let latestJournalEntry: JournalEntry?
    let journalStreakDays: Int
    let journalCountThisWeek: Int
    // Stats
    let weeklyRates: [Double]       // 7 values Mon–Sun, 0.0–1.0
    let longestStreak: Int
    let completionRateToday: Double
}

struct AuroraProvider: TimelineProvider {

    func placeholder(in context: Context) -> AuroraEntry { .preview }

    func getSnapshot(in context: Context, completion: @escaping (AuroraEntry) -> Void) {
        _Concurrency.Task { @MainActor in completion(build()) }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AuroraEntry>) -> Void) {
        _Concurrency.Task { @MainActor in
            let next = Calendar.current.date(byAdding: .minute, value: 15, to: .now)!
            completion(Timeline(entries: [build()], policy: .after(next)))
        }
    }

    @MainActor
    private func build() -> AuroraEntry {
        guard let container = ModelContainerHelper.shared() else { return .empty }
        let ctx = container.mainContext
        let cal = Calendar.current

        // ── Tasks ──
        let allTasks   = (try? ctx.fetch(FetchDescriptor<AppTask>(sortBy: [SortDescriptor(\.date)]))) ?? []
        let todayTasks = allTasks.filter { $0.date.map { cal.isDateInToday($0) } ?? false }
        let completed  = todayTasks.filter(\.isCompleted).count
        let pending    = todayTasks.filter { !$0.isCompleted }
        let pendingAll = allTasks.filter { !$0.isCompleted }
            .sorted { ($0.date ?? .distantFuture) < ($1.date ?? .distantFuture) }

        // ── Journal ──
        let journals = (try? ctx.fetch(
            FetchDescriptor<JournalEntry>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        )) ?? []

        var journalStreak = 0
        var checkDay = cal.startOfDay(for: .now)
        for _ in 0..<365 {
            if journals.contains(where: { cal.isDate($0.date, inSameDayAs: checkDay) }) {
                journalStreak += 1
                checkDay = cal.date(byAdding: .day, value: -1, to: checkDay)!
            } else { break }
        }

        let weekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: .now))!
        let journalThisWeek = journals.filter { $0.date >= weekStart }.count

        // ── Weekly rates ──
        var rates = [Double](repeating: 0, count: 7)
        for offset in 0..<7 {
            guard let day = cal.date(byAdding: .day, value: -6 + offset, to: cal.startOfDay(for: .now)) else { continue }
            let dayTasks = allTasks.filter { $0.date.map { cal.isDate($0, inSameDayAs: day) } ?? false }
            rates[offset] = dayTasks.isEmpty ? 0 : Double(dayTasks.filter(\.isCompleted).count) / Double(dayTasks.count)
        }

        // ── Longest streak ──
        var longest = 0; var cur = 0
        var scanDay = cal.startOfDay(for: .now)
        for _ in 0..<90 {
            let dt = allTasks.filter { $0.date.map { cal.isDate($0, inSameDayAs: scanDay) } ?? false }
            if !dt.isEmpty && dt.filter(\.isCompleted).count == dt.count { cur += 1; longest = max(longest, cur) }
            else { cur = 0 }
            scanDay = cal.date(byAdding: .day, value: -1, to: scanDay)!
        }

        return AuroraEntry(
            date: .now,
            pendingTodayTasks: pending,
            totalToday: todayTasks.count,
            completedToday: completed,
            allPendingTasks: pendingAll,
            latestJournalEntry: journals.first,
            journalStreakDays: journalStreak,
            journalCountThisWeek: journalThisWeek,
            weeklyRates: rates,
            longestStreak: longest,
            completionRateToday: todayTasks.isEmpty ? 0 : Double(completed) / Double(todayTasks.count)
        )
    }
}

extension AuroraEntry {
    static let empty = AuroraEntry(
        date: .now, pendingTodayTasks: [], totalToday: 0, completedToday: 0,
        allPendingTasks: [], latestJournalEntry: nil,
        journalStreakDays: 0, journalCountThisWeek: 0,
        weeklyRates: [Double](repeating: 0, count: 7), longestStreak: 0, completionRateToday: 0
    )
    static let preview = AuroraEntry(
        date: .now, pendingTodayTasks: [], totalToday: 6, completedToday: 2,
        allPendingTasks: [], latestJournalEntry: nil,
        journalStreakDays: 5, journalCountThisWeek: 3,
        weeklyRates: [1, 0.75, 0.9, 0.5, 0.33, 0, 0], longestStreak: 12, completionRateToday: 0.33
    )
}

// ═══════════════════════════════════════════════════════════════
// MARK: - TAB 1 · TODAY
// ═══════════════════════════════════════════════════════════════

// MARK: 1-A · Today Agenda — small / medium / large (polished replacement of AuroraWidget)

struct TodayAgendaView: View {
    let entry: AuroraEntry
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme)  private var scheme

    private var progress: Double {
        entry.totalToday > 0 ? Double(entry.completedToday) / Double(entry.totalToday) : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

                // ── Header ──
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.date.formatted(.dateTime.weekday(family == .systemSmall ? .abbreviated : .wide)))
                            .font(.system(size: family == .systemSmall ? 18 : 22, weight: .black, design: .rounded))
                            .foregroundStyle(LinearGradient(
                                colors: [Theme.primary, Theme.secondary],
                                startPoint: .topLeading, endPoint: .bottomTrailing))
                        if family != .systemSmall {
                            Text(entry.date.formatted(.dateTime.month(.wide).day()))
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(.secondary.opacity(0.6))
                        }
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "checklist")
                            .font(.system(size: 12, weight: .bold))
                        Text("\(entry.pendingTodayTasks.count)")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background {
                        Capsule()
                            .fill(LinearGradient(colors: [Theme.primary, Theme.secondary], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .shadow(color: Theme.primary.opacity(0.4), radius: 8, x: 0, y: 4)
                    }
                }
                .padding(.horizontal, family == .systemSmall ? 14 : 18)
                .padding(.top, family == .systemSmall ? 14 : 18)
                .padding(.bottom, family == .systemSmall ? 8 : 12)

                // ── Progress bar (medium / large) ──
                if family != .systemSmall {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Label("Day Progress", systemImage: "sparkles")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(Int(progress * 100))%")
                                .font(.system(size: 11, weight: .black, design: .rounded))
                                .foregroundStyle(Theme.primary)
                        }
                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(.white.opacity(scheme == .dark ? 0.08 : 0.2))
                                    .frame(height: 10)
                                Capsule()
                                    .fill(LinearGradient(
                                        colors: [Theme.primary, Theme.secondary],
                                        startPoint: .leading, endPoint: .trailing))
                                    .frame(width: max(10, g.size.width * progress), height: 10)
                                    .shadow(color: Theme.primary.opacity(0.5), radius: 6)
                                
                                // Glisten effect
                                Capsule()
                                    .fill(LinearGradient(colors: [.white.opacity(0.4), .clear], startPoint: .top, endPoint: .center))
                                    .frame(width: max(10, g.size.width * progress), height: 4)
                                    .padding(.top, 1)
                                    .padding(.horizontal, 2)
                            }
                        }
                        .frame(height: 8)
                    }
                    .padding(.horizontal, family == .systemSmall ? 14 : 18).padding(.bottom, 14)
                }

                // ── Tasks or empty ──
                if entry.pendingTodayTasks.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: family == .systemSmall ? 7 : 10) {
                        ForEach(entry.pendingTodayTasks.prefix(maxVisible)) { task in
                            taskRow(task)
                        }
                        if entry.pendingTodayTasks.count > maxVisible {
                            HStack(spacing: 4) {
                                Rectangle().fill(.secondary.opacity(0.2)).frame(height: 1)
                                Text("+\(entry.pendingTodayTasks.count - maxVisible) more")
                                    .font(.system(size: 11, weight: .black, design: .rounded))
                                    .foregroundStyle(.secondary.opacity(0.7))
                                Rectangle().fill(.secondary.opacity(0.2)).frame(height: 1)
                            }
                            .padding(.horizontal, 20).padding(.top, 2)
                        }
                    }
                    .padding(.horizontal, family == .systemSmall ? 10 : 14)
                    Spacer(minLength: 0)
                }

            }
            .widgetURL(URL(string: "aurora://today"))
        }

    private var maxVisible: Int {
        switch family { case .systemSmall: return 2; case .systemLarge: return 6; default: return 3 }
    }

    private var emptyState: some View {
        VStack(spacing: family == .systemSmall ? 8 : 14) {
            if family == .systemSmall || family == .systemLarge { Spacer(minLength: 0) }
            else if family == .systemMedium && !entry.pendingTodayTasks.isEmpty { Spacer(minLength: 0) }
            else { Spacer() }
            ZStack {
                Circle().fill(Theme.primary.opacity(0.12))
                Circle()
                    .strokeBorder(LinearGradient(colors: [Theme.primary, Theme.secondary],
                                                 startPoint: .top, endPoint: .bottom), lineWidth: 2)
                Image(systemName: "star.fill")
                    .font(.system(size: family == .systemSmall ? 28 : 34))
                    .foregroundStyle(LinearGradient(colors: [Theme.primary, Theme.secondary],
                                                   startPoint: .top, endPoint: .bottom))
                Image(systemName: "checkmark")
                    .font(.system(size: family == .systemSmall ? 12 : 16, weight: .black))
                    .foregroundStyle(.white).offset(y: 2)
            }
            .frame(width: family == .systemSmall ? 56 : 72, height: family == .systemSmall ? 56 : 72)
            .shadow(color: Theme.primary.opacity(0.3), radius: 12)
            
            VStack(spacing: family == .systemSmall ? 2 : 4) {
                Text("Mission Accomplished")
                    .font(.system(size: family == .systemSmall ? 13 : 15, weight: .black, design: .rounded)).foregroundStyle(.primary)
                Text("All clear for takeoff.")
                    .font(.system(size: family == .systemSmall ? 10 : 12, weight: .bold, design: .rounded)).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
    }

    private func taskRow(_ task: AppTask) -> some View {
        let catColor = task.category.map { Color(hex: $0.colorHex) } ?? Theme.primary
        return HStack(spacing: 14) {
            Button(intent: ToggleTaskIntent(taskId: task.id.uuidString)) {
                ZStack {
                    Circle()
                        .strokeBorder(task.isCompleted ? catColor : .primary.opacity(0.2), lineWidth: 2)
                        .background(
                            Circle()
                                .fill(task.isCompleted ? catColor : .white.opacity(scheme == .dark ? 0.08 : 0.6))
                        )
                        .frame(width: 24, height: 24)
                        .shadow(color: task.isCompleted ? catColor.opacity(0.4) : .clear, radius: 5)
                    
                    if task.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    if task.priority == .high {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.red)
                    } else if task.priority == .medium {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.orange)
                    }
                    
                    Text(task.title)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(task.isCompleted ? .secondary : .primary)
                        .strikethrough(task.isCompleted)
                        .lineLimit(1)
                }
                
                if family != .systemSmall,
                   let date = task.date,
                   Calendar.current.component(.hour, from: date) != 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill").font(.system(size: 10))
                        Text(date.formatted(date: .omitted, time: .shortened))
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.secondary.opacity(0.6))
                }
            }
            
            Spacer(minLength: 0)
            
            if task.isFlagged {
                Image(systemName: "flag.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.orange)
                    .padding(6)
                    .background {
                        Circle()
                            .fill(.orange.opacity(0.12))
                    }
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .glassCard()
    }
}

// MARK: 1-B · Today Pulse — small
// Completion ring + next task card

struct TodayPulseView: View {
    let entry: AuroraEntry
    @Environment(\.colorScheme) private var scheme

    private var progress: Double {
        entry.totalToday > 0 ? Double(entry.completedToday) / Double(entry.totalToday) : 0
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(entry.date.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.primary)
                Spacer()
                if entry.longestStreak > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill").font(.system(size: 11)).foregroundStyle(.orange)
                        Text("\(entry.longestStreak)")
                            .font(.system(size: 11, weight: .black, design: .rounded)).foregroundStyle(.orange)
                    }
                }
            }
            .padding(.horizontal, 14).padding(.top, 14)

            Spacer(minLength: 6)

            ZStack {
                Circle()
                    .stroke(.white.opacity(scheme == .dark ? 0.08 : 0.2), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(LinearGradient(colors: [Theme.primary, Theme.secondary],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .shadow(color: Theme.primary.opacity(0.4), radius: 6)
                
                VStack(spacing: 0) {
                    Text("\(entry.completedToday)")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("/ \(entry.totalToday)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary.opacity(0.8))
                }
            }
            .frame(width: 68, height: 68).frame(maxWidth: .infinity)

            Spacer(minLength: 8)

            if let task = entry.pendingTodayTasks.first {
                VStack(alignment: .leading, spacing: 3) {
                    Text("NEXT")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .foregroundStyle(Theme.primary.opacity(0.8))
                    Text(task.title)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary).lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10).padding(.vertical, 8)
                .glassCard()
                .padding(.horizontal, 10)
            } else {
                Text("All clear! 🎉")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(LinearGradient(colors: [Theme.primary, Theme.secondary],
                                                    startPoint: .leading, endPoint: .trailing))
                    .frame(maxWidth: .infinity)
            }
            Spacer(minLength: 12)
        }
        .widgetURL(URL(string: "aurora://today"))
    }
}

// ═══════════════════════════════════════════════════════════════
// MARK: - TAB 2 · TASKS
// ═══════════════════════════════════════════════════════════════

// MARK: 2-A · Tasks By Priority — medium / large

struct TasksByPriorityView: View {
    let entry: AuroraEntry
    @Environment(\.widgetFamily) private var family

    private var highCount:   Int { entry.allPendingTasks.filter { $0.priority == .high }.count }
    private var mediumCount: Int { entry.allPendingTasks.filter { $0.priority == .medium }.count }
    private var lowCount:    Int { entry.allPendingTasks.filter { $0.priority == .low }.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 6) {
                            Image(systemName: "checklist").font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Theme.primary)
                            Text("All Tasks")
                                .font(.system(size: 18, weight: .black, design: .rounded)).foregroundStyle(.primary)
                        }
                        Text("\(entry.allPendingTasks.count) remaining")
                            .font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(spacing: 1) {
                        Text("\(entry.completedToday)")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(LinearGradient(colors: [Theme.primary, Theme.secondary],
                                                            startPoint: .top, endPoint: .bottom))
                        Text("done")
                            .font(.system(size: 9, weight: .bold, design: .rounded)).foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .glassCard()
                }
                .padding(.horizontal, family == .systemSmall ? 14 : 18)
                .padding(.top, family == .systemSmall ? 14 : 18)
                .padding(.bottom, family == .systemSmall ? 8 : 12)

                VStack(spacing: 8) {
                    priorityRow("High Priority",  highCount,   Color(red: 0.96, green: 0.34, blue: 0.40), "exclamationmark.circle.fill")
                    priorityRow("Medium",         mediumCount, .orange,                                   "minus.circle.fill")
                    priorityRow("Low",            lowCount,    Color(red: 0.30, green: 0.78, blue: 0.58), "arrow.down.circle.fill")
                }
                .padding(.horizontal, 14)

                if family == .systemLarge, !entry.allPendingTasks.isEmpty {
                    Divider().background(.white.opacity(0.08))
                        .padding(.horizontal, 18).padding(.vertical, 10)
                    VStack(spacing: 8) {
                        ForEach(entry.allPendingTasks.prefix(4)) { task in
                            compactRow(task)
                        }
                    }
                    .padding(.horizontal, 14)
                }
                Spacer(minLength: 0)
            }
        .widgetURL(URL(string: "aurora://tasks"))
    }

    private func priorityRow(_ label: String, _ count: Int, _ color: Color, _ icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 16)).foregroundStyle(color).frame(width: 20)
            Text(label).font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(.primary)
            Spacer()
            Text("\(count)")
                .font(.system(size: 14, weight: .black, design: .rounded)).foregroundStyle(color)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background { Capsule().fill(color.opacity(0.12)).glassEffect(.clear) }
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .glassCard()
    }

    private func compactRow(_ task: AppTask) -> some View {
        let catColor = task.category.map { Color(hex: $0.colorHex) } ?? Theme.primary
        return HStack(spacing: 10) {
            Circle().fill(catColor).frame(width: 7, height: 7)
            Text(task.title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.primary).lineLimit(1)
            Spacer()
            if let date = task.date {
                Text(date.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .glassCard()
    }
}

// MARK: 2-B · Category Ring — small

struct CategoryRingView: View {
    let entry: AuroraEntry
    @Environment(\.colorScheme) private var scheme

    private var progress: Double {
        entry.totalToday > 0 ? Double(entry.completedToday) / Double(entry.totalToday) : 0
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "square.grid.2x2.fill").font(.system(size: 11))
                    .foregroundStyle(Theme.primary)
                Text("TASKS")
                    .font(.system(size: 9, weight: .black, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 14).padding(.top, 14)

            Spacer(minLength: 8)

            ZStack {
                Circle()
                    .stroke(.white.opacity(scheme == .dark ? 0.08 : 0.2), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(LinearGradient(colors: [Theme.primary, Theme.secondary],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .shadow(color: Theme.primary.opacity(0.4), radius: 8)
                
                VStack(spacing: 0) {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("today")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary.opacity(0.8))
                }
            }
            .frame(width: 74, height: 74).frame(maxWidth: .infinity)

            Spacer(minLength: 10)

            HStack {
                miniStat("\(entry.completedToday)", "done")
                Divider().frame(height: 22).background(.white.opacity(0.1))
                miniStat("\(max(0, entry.totalToday - entry.completedToday))", "left")
            }
            .frame(maxWidth: .infinity)

            Spacer(minLength: 12)
        }
        .widgetURL(URL(string: "aurora://tasks"))
    }

    private func miniStat(_ val: String, _ lbl: String) -> some View {
        VStack(spacing: 2) {
            Text(val)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(LinearGradient(colors: [Theme.primary, Theme.secondary],
                                                startPoint: .leading, endPoint: .trailing))
            Text(lbl)
                .font(.system(size: 9, weight: .bold, design: .rounded)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// ═══════════════════════════════════════════════════════════════
// MARK: - TAB 3 · JOURNAL
// ═══════════════════════════════════════════════════════════════

// MARK: 3-A · Journal Preview — medium / large

struct JournalPreviewView: View {
    let entry: AuroraEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 6) {
                        Image(systemName: "book.closed.fill").font(.system(size: 12))
                            .foregroundStyle(Theme.secondary)
                        Text("Journal")
                            .font(.system(size: 18, weight: .black, design: .rounded)).foregroundStyle(.primary)
                    }
                    Text(entry.date.formatted(.dateTime.month(.abbreviated).day(.defaultDigits)))
                        .font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(.secondary)
                }
                Spacer()
                if entry.journalStreakDays > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill").font(.system(size: 13)).foregroundStyle(.orange)
                        Text("\(entry.journalStreakDays)d")
                            .font(.system(size: 13, weight: .black, design: .rounded)).foregroundStyle(.orange)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background { Capsule().fill(.orange.opacity(0.15)).glassEffect(.clear) }
                }
            }
            .padding(.horizontal, 18).padding(.top, 18).padding(.bottom, 14)

            if let je = entry.latestJournalEntry {
                VStack(alignment: .leading, spacing: 8) {
                    if !je.title.isEmpty {
                        Text(je.title)
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(.primary).lineLimit(1)
                    }
                    if !je.body.isEmpty {
                        Text(je.body)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                            .lineLimit(family == .systemLarge ? 6 : 3)
                            .lineSpacing(3)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill").font(.system(size: 10))
                        Text(je.date.formatted(date: .omitted, time: .shortened))
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.secondary.opacity(0.6))

                }
                .padding(14)
                .glassCard()
                .padding(.horizontal, 14)
            } else {
                HStack(spacing: 12) {
                    Image(systemName: "pencil.and.scribble").font(.system(size: 26))
                        .foregroundStyle(LinearGradient(colors: [Theme.primary, Theme.secondary],
                                                        startPoint: .top, endPoint: .bottom))
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Start today's entry")
                            .font(.system(size: 14, weight: .black, design: .rounded)).foregroundStyle(.primary)
                        Text("Tap to write in your journal")
                            .font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(.secondary)
                    }
                }
                .padding(14).glassCard().padding(.horizontal, 14)
            }

            Spacer(minLength: 0)

            HStack {
                Spacer()
                Text("\(entry.journalCountThisWeek) entries this week")
                    .font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(.secondary.opacity(0.6))
            }
            .padding(.horizontal, 18).padding(.bottom, 12)
        }
        .widgetURL(URL(string: "aurora://journal"))
    }
}

// MARK: 3-B · Journal Streak — small

struct JournalStreakView: View {
    let entry: AuroraEntry
    @Environment(\.colorScheme) private var scheme
    private let initials = ["M","T","W","T","F","S","S"]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "book.closed.fill").font(.system(size: 11))
                    .foregroundStyle(Theme.secondary)
                Spacer()
                if entry.journalStreakDays > 0 {
                    Image(systemName: "flame.fill").font(.system(size: 12)).foregroundStyle(.orange)
                }
            }
            .padding(.horizontal, 14).padding(.top, 14)

            Spacer(minLength: 4)

            Text("\(entry.journalStreakDays)")
                .font(.system(size: 42, weight: .black, design: .rounded))
                .foregroundStyle(LinearGradient(colors: [Theme.primary, Theme.secondary],
                                               startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: Theme.primary.opacity(0.3), radius: 8)
            Text("day streak")
                .font(.system(size: 11, weight: .black, design: .rounded)).foregroundStyle(.secondary.opacity(0.8))

            Spacer(minLength: 8)

            HStack(spacing: 5) {
                ForEach(0..<7, id: \.self) { i in
                    let filled = i < entry.journalCountThisWeek
                    VStack(spacing: 3) {
                        Circle()
                            .fill(filled
                                  ? AnyShapeStyle(LinearGradient(colors: [Theme.primary, Theme.secondary],
                                                                  startPoint: .top, endPoint: .bottom))
                                  : AnyShapeStyle(.white.opacity(scheme == .dark ? 0.08 : 0.25)))
                            .frame(width: 10, height: 10)
                            .shadow(color: filled ? Theme.primary.opacity(0.5) : .clear, radius: 3)
                        Text(initials[i])
                            .font(.system(size: 7, weight: .black, design: .rounded))
                            .foregroundStyle(.secondary.opacity(0.5))
                    }
                }
            }
            .padding(.horizontal, 18).padding(.bottom, 12)
            Spacer(minLength: 12)
        }
        .widgetURL(URL(string: "aurora://journal"))
    }
}

// ═══════════════════════════════════════════════════════════════
// MARK: - TAB 4 · STATS
// ═══════════════════════════════════════════════════════════════

// MARK: 4-A · Weekly Stats — medium / large

struct WeeklyStatsView: View {
    let entry: AuroraEntry
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme)  private var scheme
    private let dayLabels = ["M","T","W","T","F","S","S"]

    private var avgPct: Int {
        let nz = entry.weeklyRates.filter { $0 > 0 }
        guard !nz.isEmpty else { return 0 }
        return Int((nz.reduce(0, +) / Double(nz.count)) * 100)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.bar.fill").font(.system(size: 12))
                            .foregroundStyle(Theme.primary)
                        Text("Progress")
                            .font(.system(size: 18, weight: .black, design: .rounded)).foregroundStyle(.primary)
                    }
                    Text("This Week")
                        .font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text("\(avgPct)%")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(LinearGradient(colors: [Theme.primary, Theme.secondary],
                                                        startPoint: .leading, endPoint: .trailing))
                    Text("avg")
                        .font(.system(size: 10, weight: .bold, design: .rounded)).foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 18).padding(.top, 18).padding(.bottom, 14)

            // Bar chart
            GeometryReader { geo in
                let gap:   CGFloat = 6
                let barW = (geo.size.width - (gap * 6) - 28) / 7
                let maxH = geo.size.height - 20
                HStack(alignment: .bottom, spacing: gap) {
                    ForEach(0..<7, id: \.self) { i in
                        let r = entry.weeklyRates[i]
                        let isToday = i == 6
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(r > 0
                                      ? AnyShapeStyle(LinearGradient(colors: [Theme.primary, Theme.secondary],
                                                                      startPoint: .top, endPoint: .bottom))
                                      : AnyShapeStyle(.white.opacity(scheme == .dark ? 0.06 : 0.2)))
                                .frame(width: barW, height: max(6, maxH * r))
                                .shadow(color: r > 0 ? Theme.primary.opacity(0.4) : .clear, radius: 5)
                                .overlay {
                                    if isToday {
                                        RoundedRectangle(cornerRadius: 5)
                                            .strokeBorder(Theme.primary.opacity(0.7), lineWidth: 1.5)
                                    }
                                }
                            Text(dayLabels[i])
                                .font(.system(size: 9, weight: isToday ? .black : .bold, design: .rounded))
                                .foregroundStyle(isToday ? Theme.primary : .secondary.opacity(0.5))
                        }
                    }
                }
                .padding(.horizontal, 14)
                .frame(maxHeight: .infinity, alignment: .bottom)
            }

            if family == .systemLarge {
                HStack(spacing: 10) {
                    statPill("🔥", "\(entry.longestStreak)d", "Best Streak")
                    statPill("✅", "\(entry.completedToday)", "Done Today")
                    statPill("📋", "\(entry.totalToday)", "Total Today")
                }
                .padding(.horizontal, 14).padding(.top, 12)
            }

            Spacer(minLength: 14)
        }
        .widgetURL(URL(string: "aurora://stats"))
    }

    private func statPill(_ emoji: String, _ val: String, _ lbl: String) -> some View {
        VStack(spacing: 3) {
            Text(emoji).font(.system(size: 16))
            Text(val)
                .font(.system(size: 14, weight: .black, design: .rounded)).foregroundStyle(.primary)
            Text(lbl)
                .font(.system(size: 9, weight: .bold, design: .rounded)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 10)
        .glassCard()
    }
}

// MARK: 4-B · Streak Badge — small

struct StreakBadgeView: View {
    let entry: AuroraEntry

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("STATS")
                    .font(.system(size: 9, weight: .black, design: .rounded)).foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "chart.bar.fill").font(.system(size: 11))
                    .foregroundStyle(Theme.primary)
            }
            .padding(.horizontal, 14).padding(.top, 14)

            Spacer(minLength: 4)

            HStack(spacing: 4) {
                Image(systemName: "flame.fill").font(.system(size: 26)).foregroundStyle(.orange)
                Text("\(entry.longestStreak)")
                    .font(.system(size: 38, weight: .black, design: .rounded)).foregroundStyle(.primary)
            }
            Text("day streak")
                .font(.system(size: 11, weight: .black, design: .rounded)).foregroundStyle(.secondary.opacity(0.8))

            Spacer(minLength: 8)

            Text(String(format: "%.0f%% today", entry.completionRateToday * 100))
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 12).padding(.vertical, 5)
                .background {
                    Capsule()
                        .fill(Theme.primary)
                        .shadow(color: Theme.primary.opacity(0.4), radius: 6, x: 0, y: 3)
                }

            Spacer(minLength: 12)
        }
        .widgetURL(URL(string: "aurora://stats"))
    }
}

// ═══════════════════════════════════════════════════════════════
// MARK: - WIDGET CONFIGURATIONS
// ═══════════════════════════════════════════════════════════════

struct TodayAgendaWidget: Widget {
    let kind = "AuroraTodayAgendaWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AuroraProvider()) { entry in
            TodayAgendaView(entry: entry)
                .containerBackground(for: .widget) { AuroraBackground() }
                .tint(Theme.primary)
        }
        .configurationDisplayName("Today's Agenda")
        .description("View and complete your daily tasks at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

struct TodayPulseWidget: Widget {
    let kind = "AuroraTodayPulseWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AuroraProvider()) { entry in
            TodayPulseView(entry: entry)
                .containerBackground(for: .widget) { AuroraBackground() }
                .tint(Theme.primary)
        }
        .configurationDisplayName("Today's Pulse")
        .description("Completion ring with your next upcoming task.")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

struct TasksByPriorityWidget: Widget {
    let kind = "AuroraTasksByPriorityWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AuroraProvider()) { entry in
            TasksByPriorityView(entry: entry)
                .containerBackground(for: .widget) { AuroraBackground() }
                .tint(Theme.primary)
        }
        .configurationDisplayName("Task Priorities")
        .description("Pending tasks broken down by priority level.")
        .supportedFamilies([.systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

struct CategoryRingWidget: Widget {
    let kind = "AuroraCategoryRingWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AuroraProvider()) { entry in
            CategoryRingView(entry: entry)
                .containerBackground(for: .widget) { AuroraBackground() }
                .tint(Theme.primary)
        }
        .configurationDisplayName("Task Ring")
        .description("Today's completion percentage at a glance.")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

struct JournalPreviewWidget: Widget {
    let kind = "AuroraJournalPreviewWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AuroraProvider()) { entry in
            JournalPreviewView(entry: entry)
                .containerBackground(for: .widget) { AuroraBackground() }
                .tint(Theme.primary)
        }
        .configurationDisplayName("Journal")
        .description("Preview your latest journal entry and writing streak.")
        .supportedFamilies([.systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

struct JournalStreakWidget: Widget {
    let kind = "AuroraJournalStreakWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AuroraProvider()) { entry in
            JournalStreakView(entry: entry)
                .containerBackground(for: .widget) { AuroraBackground() }
                .tint(Theme.primary)
        }
        .configurationDisplayName("Journal Streak")
        .description("Consecutive journaling streak with weekly dots.")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

struct WeeklyStatsWidget: Widget {
    let kind = "AuroraWeeklyStatsWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AuroraProvider()) { entry in
            WeeklyStatsView(entry: entry)
                .containerBackground(for: .widget) { AuroraBackground() }
                .tint(Theme.primary)
        }
        .configurationDisplayName("Weekly Progress")
        .description("7-day completion bar chart with average rate.")
        .supportedFamilies([.systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

struct StreakBadgeWidget: Widget {
    let kind = "AuroraStreakBadgeWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AuroraProvider()) { entry in
            StreakBadgeView(entry: entry)
                .containerBackground(for: .widget) { AuroraBackground() }
                .tint(Theme.primary)
        }
        .configurationDisplayName("Streak")
        .description("Current streak and today's completion rate.")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

// ═══════════════════════════════════════════════════════════════
// MARK: - WIDGET BUNDLE
// Delete your old AuroraWidget.swift @main — this replaces it.
// ═══════════════════════════════════════════════════════════════

@main
struct AuroraWidgetBundle: WidgetBundle {
    var body: some Widget {
        // Tab 1 · Today
        TodayAgendaWidget()       // small / medium / large
        TodayPulseWidget()        // small

        // Tab 2 · Tasks
        TasksByPriorityWidget()   // medium / large
        CategoryRingWidget()      // small

        // Tab 3 · Journal
        JournalPreviewWidget()    // medium / large
        JournalStreakWidget()     // small

        // Tab 4 · Stats
        WeeklyStatsWidget()       // medium / large
        StreakBadgeWidget()       // small
    }
}
