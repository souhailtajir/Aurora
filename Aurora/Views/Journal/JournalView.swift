//
//  JournalView.swift
//  Aurora
//
//  Revamped journal view with insight cards and FaceID lock
//

import LocalAuthentication
import SwiftUI

struct JournalView: View {
  @Environment(TaskStore.self) var taskStore
  @State private var searchText = ""
  @State private var isSearching = false
  @State private var navigationPath = NavigationPath()
  @State private var isLocked = false
  @State private var showNewEntryFullScreen = false
  @State private var newEntryId: UUID?
  @State private var recentsExpanded = true
  @Environment(\.horizontalSizeClass) private var sizeClass

  var body: some View {
    NavigationStack(path: $navigationPath) {
      ZStack {
        if isLocked {
          lockedView
        } else {
          mainScrollView
        }
      }
      .background(Color.clear.auroraBackground())
      .navigationTitle("Journal")
      .toolbarTitleDisplayMode(.inlineLarge)
      .safeAreaPadding(.top, LayoutTokens.Spacing.sm)
      .safeAreaInset(edge: .bottom) {
        if isSearching {
          BottomSearchBar(
            text: $searchText, isSearching: $isSearching, placeholder: "Search journals..."
          )
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
          Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
              isLocked.toggle()
            }
          } label: {
            Label(
              isLocked ? "Unlock Journal" : "Lock Journal",
              systemImage: isLocked ? "lock.open" : "lock.fill")
          }
        }
        ToolbarSpacer(.fixed, placement: .topBarTrailing)

        ToolbarItem(placement: .topBarTrailing) {
          NavigationLink(value: "settings") {
            Image(systemName: "gearshape")
          }
        }
      }

      .onChange(of: taskStore.addJournalTrigger) { _, newValue in
        if newValue {
          createNewEntryFullScreen()
          taskStore.addJournalTrigger = false
        }
      }
      .fullScreenCover(isPresented: $showNewEntryFullScreen) {
        if let entryId = newEntryId {
          NavigationStack {
            EntryEditorView(entryId: entryId)
          }
        }
      }
      .navigationDestination(for: JournalNav.self) { nav in
        switch nav {
        case .allEntries:
          AllEntriesView()
        case .deleted:
          DeletedEntriesView()
        }
      }
      .navigationDestination(for: JournalEntry.self) { entry in
        EntryEditorView(entryId: entry.id)
      }
      .navigationDestination(for: String.self) { destination in
        if destination == "settings" {
          SettingsView()
        }
      }
    }
  }

  // MARK: - Locked View

  private var lockedView: some View {
    VStack(spacing: LayoutTokens.Spacing.xxl) {
      Spacer()

      Image(systemName: "lock.fill")
        .font(.system(size: LayoutTokens.Typography.heroStat))
        .foregroundStyle(.secondary)

      Text("Journal Locked")
        .font(.system(size: LayoutTokens.Typography.title3, weight: .semibold))
        .foregroundStyle(.primary)

      Text("Use Face ID to unlock")
        .font(.system(size: LayoutTokens.Typography.callout))
        .foregroundStyle(.secondary)

      Button {
        AsyncTask { await unlockWithBiometrics() }
      } label: {
        HStack(spacing: LayoutTokens.Spacing.sm) {
          Image(systemName: "faceid")
            .font(.system(size: LayoutTokens.IconSize.md))
          Text("Unlock")
            .font(.system(size: LayoutTokens.Typography.body, weight: .semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, LayoutTokens.Spacing.xxl)
        .padding(.vertical, LayoutTokens.Spacing.md)
        .background(Theme.tint)
        .clipShape(Capsule())
      }

      Spacer()
    }
    .frame(maxWidth: .infinity)
  }

  // MARK: - Main Scroll View

  private var mainScrollView: some View {
    List {
      if !searchText.isEmpty {
        searchResultsContent
      } else {
        mainContentRows
      }
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
    .scrollIndicators(.hidden)
  }

  // MARK: - Main Content Rows (for List)

  @ViewBuilder
  private var mainContentRows: some View {
    // Insight card
    JournalInsightCard(
      totalEntries: taskStore.journalEntries.count,
      entriesThisMonth: entriesThisMonth
    )
    .listRowInsets(LayoutTokens.listRowInsets(vertical: LayoutTokens.Spacing.sm, for: sizeClass))
    .listRowBackground(Color.clear)
    .listRowSeparator(.hidden)

    // Streak card
    JournalStreakCard(streak: streak)
      .listRowInsets(LayoutTokens.listRowInsets(vertical: LayoutTokens.Spacing.sm, for: sizeClass))
      .listRowBackground(Color.clear)
      .listRowSeparator(.hidden)

    // Navigation rows
    NavigationRow(
      icon: "books.vertical.fill",
      color: Theme.tint,
      title: "All Entries",
      count: taskStore.journalEntries.count
    ) {
      navigationPath.append(JournalNav.allEntries)
    }
    .listRowInsets(LayoutTokens.listRowInsets(vertical: LayoutTokens.Spacing.xs, for: sizeClass))
    .listRowBackground(Color.clear)
    .listRowSeparator(.hidden)

    NavigationRow(
      icon: "trash",
      color: .gray,
      title: "Recently Deleted",
      count: taskStore.deletedJournalEntries.count
    ) {
      navigationPath.append(JournalNav.deleted)
    }
    .listRowInsets(LayoutTokens.listRowInsets(vertical: LayoutTokens.Spacing.xs, for: sizeClass))
    .listRowBackground(Color.clear)
    .listRowSeparator(.hidden)

    // Recent entries section header
    recentEntriesHeader
      .listRowInsets(EdgeInsets(top: LayoutTokens.Spacing.lg, leading: LayoutTokens.Padding.screenHorizontal(for: sizeClass), bottom: LayoutTokens.Spacing.sm, trailing: LayoutTokens.Padding.screenHorizontal(for: sizeClass)))
      .listRowBackground(Color.clear)
      .listRowSeparator(.hidden)

    // Recent entries content
    if recentsExpanded {
      if recentEntries.isEmpty {
        emptyState
          .listRowInsets(LayoutTokens.listRowInsets(vertical: LayoutTokens.Spacing.sm, for: sizeClass))
          .listRowBackground(Color.clear)
          .listRowSeparator(.hidden)
      } else {
        ForEach(recentEntries) { entry in
          JournalEntryRow(entry: entry) {
            navigationPath.append(entry)
          }
          .listRowInsets(LayoutTokens.listRowInsets(vertical: LayoutTokens.Spacing.xs, for: sizeClass))
          .listRowBackground(Color.clear)
          .listRowSeparator(.hidden)
        }
      }
    }
  }

  // MARK: - Search Results Content (for List)

  @ViewBuilder
  private var searchResultsContent: some View {
    let results = filteredEntries
    if results.isEmpty {
      VStack(spacing: LayoutTokens.Spacing.md) {
        Image(systemName: "magnifyingglass")
          .font(.system(size: LayoutTokens.Typography.emptyStateIcon))
          .foregroundStyle(.secondary)
        Text("No results")
          .font(.system(size: LayoutTokens.Typography.callout))
          .foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, LayoutTokens.Spacing.xxl * 3)
      .listRowInsets(EdgeInsets())
      .listRowBackground(Color.clear)
      .listRowSeparator(.hidden)
    } else {
      ForEach(results) { entry in
        JournalEntryRow(entry: entry) {
          navigationPath.append(entry)
        }
        .listRowInsets(LayoutTokens.listRowInsets(vertical: LayoutTokens.Spacing.xs, for: sizeClass))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
      }
    }
  }

  // MARK: - Main Content

  private var mainContent: some View {
    VStack(spacing: 16) {
      // Insight card
      JournalInsightCard(
        totalEntries: taskStore.journalEntries.count,
        entriesThisMonth: entriesThisMonth
      )

      // Streak card
      JournalStreakCard(streak: streak)

      // Navigation list
      navigationList

      // Recent entries
      recentEntriesSection
    }
  }

  // MARK: - Navigation List

  private var navigationList: some View {
    VStack(spacing: LayoutTokens.Spacing.sm) {
      NavigationRow(
        icon: "books.vertical.fill",
        color: Theme.tint,
        title: "All Entries",
        count: taskStore.journalEntries.count
      ) {
        navigationPath.append(JournalNav.allEntries)
      }

      NavigationRow(
        icon: "trash",
        color: .gray,
        title: "Recently Deleted",
        count: taskStore.deletedJournalEntries.count
      ) {
        navigationPath.append(JournalNav.deleted)
      }
    }
  }

  // MARK: - Recent Entries Section

  private var recentEntriesSection: some View {
    VStack(alignment: .leading, spacing: LayoutTokens.Spacing.md) {
      Button {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
          recentsExpanded.toggle()
        }
      } label: {
        HStack {
          Text("Recent")
            .font(.system(size: LayoutTokens.Typography.title2, weight: .bold))
            .foregroundStyle(.primary)

          Image(systemName: recentsExpanded ? "chevron.down" : "chevron.right")
            .font(.system(size: LayoutTokens.Typography.subheadline, weight: .semibold))
            .foregroundStyle(.secondary)
            .contentTransition(.symbolEffect(.replace))

          Spacer()
        }
        .padding(.horizontal, LayoutTokens.Padding.sectionTitleInset)
      }
      .buttonStyle(.plain)

      if recentsExpanded {
        if recentEntries.isEmpty {
          emptyState
        } else {
          VStack(spacing: LayoutTokens.Spacing.sm) {
            ForEach(recentEntries) { entry in
              JournalEntryRow(entry: entry) {
                navigationPath.append(entry)
              }
            }
          }
          .transition(.opacity.combined(with: .move(edge: .top)))
        }
      }
    }
  }

  private var emptyState: some View {
    VStack(spacing: LayoutTokens.Spacing.md) {
      Image(systemName: "book.closed")
        .font(.system(size: LayoutTokens.Typography.emptyStateIcon))
        .foregroundStyle(.secondary.opacity(0.5))

      Text("No entries yet")
        .font(.system(size: LayoutTokens.Typography.callout))
        .foregroundStyle(.secondary)

      Text("Tap + to start writing")
        .font(.system(size: LayoutTokens.Typography.footnote))
        .foregroundStyle(.tertiary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, LayoutTokens.Spacing.xxl * 2)
  }

  private var recentEntriesHeader: some View {
    Button {
      withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
        recentsExpanded.toggle()
      }
    } label: {
      HStack {
        Text("Recent")
          .font(.system(size: LayoutTokens.Typography.title2, weight: .bold))
          .foregroundStyle(.primary)

        Image(systemName: recentsExpanded ? "chevron.down" : "chevron.right")
          .font(.system(size: LayoutTokens.Typography.subheadline, weight: .semibold))
          .foregroundStyle(.secondary)
          .contentTransition(.symbolEffect(.replace))

        Spacer()
      }
      .padding(.horizontal, LayoutTokens.Padding.sectionTitleInset)
    }
    .buttonStyle(.plain)
  }

  // MARK: - Search Results

  private var searchResults: some View {
    VStack(spacing: LayoutTokens.Spacing.sm) {
      let results = filteredEntries
      if results.isEmpty {
        VStack(spacing: LayoutTokens.Spacing.md) {
          Image(systemName: "magnifyingglass")
            .font(.system(size: LayoutTokens.Typography.emptyStateIcon))
            .foregroundStyle(.secondary)
          Text("No results")
            .font(.system(size: LayoutTokens.Typography.callout))
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, LayoutTokens.Spacing.xxl * 3)
      } else {
        ForEach(results) { entry in
          JournalEntryRow(entry: entry) {
            navigationPath.append(entry)
          }
        }
      }
    }
  }

  // MARK: - Computed Properties

  private var recentEntries: [JournalEntry] {
    let cutoff = Calendar.current.date(byAdding: .hour, value: -48, to: Date()) ?? Date()
    return taskStore.journalEntries
      .filter { $0.date >= cutoff }
      .sorted { $0.date > $1.date }
  }

  private var filteredEntries: [JournalEntry] {
    taskStore.journalEntries.filter {
      $0.title.localizedCaseInsensitiveContains(searchText)
        || $0.body.localizedCaseInsensitiveContains(searchText)
    }
  }

  private var entriesThisMonth: Int {
    taskStore.journalEntries.filter {
      Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month)
    }.count
  }

  private var streak: Int {
    let dates = taskStore.journalEntries.map { $0.date }.sorted(by: >)
    guard let first = dates.first else { return 0 }
    guard Calendar.current.isDateInToday(first) || Calendar.current.isDateInYesterday(first) else {
      return 0
    }

    var count = 1
    var prev = first
    for date in dates.dropFirst() {
      if Calendar.current.isDate(date, inSameDayAs: prev) { continue }
      guard let dayBefore = Calendar.current.date(byAdding: .day, value: -1, to: prev),
        Calendar.current.isDate(date, inSameDayAs: dayBefore)
      else { break }
      count += 1
      prev = date
    }
    return count
  }

  // MARK: - Actions

  private func createNewEntry() {
    let entry = JournalEntry(title: "", body: "", date: Date())
    taskStore.addJournalEntry(entry)
    navigationPath.append(entry)
  }

  private func createNewEntryFullScreen() {
    let entry = JournalEntry(title: "", body: "", date: Date())
    taskStore.addJournalEntry(entry)
    newEntryId = entry.id
    showNewEntryFullScreen = true
  }

  private func unlockWithBiometrics() async {
    let context = LAContext()
    var error: NSError?

    guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
      // Fallback: just unlock if no biometrics
      isLocked = false
      return
    }

    do {
      let success = try await context.evaluatePolicy(
        .deviceOwnerAuthenticationWithBiometrics,
        localizedReason: "Unlock your journal"
      )
      if success {
        isLocked = false
      }
    } catch {
      // Keep locked on failure
    }
  }

  // MARK: - Navigation Enum

  enum JournalNav: Hashable {
    case allEntries
    case deleted
  }

  // MARK: - Navigation Row

  struct NavigationRow: View {
    let icon: String
    let color: Color
    let title: String
    let count: Int
    let action: () -> Void
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
      Button(action: action) {
        HStack(spacing: LayoutTokens.Spacing.md) {
          Image(systemName: icon)
            .font(.system(size: LayoutTokens.IconSize.md, weight: .semibold))
            .foregroundStyle(color)

          Text(title)
            .font(.system(size: LayoutTokens.Typography.body, weight: .medium))
            .foregroundStyle(.primary)

          Spacer()

          if count > 0 {
            Text("\(count)")
              .font(.system(size: LayoutTokens.Typography.body))
              .foregroundStyle(.secondary)
          }

          Image(systemName: "chevron.right")
            .font(.system(size: LayoutTokens.Typography.caption, weight: .semibold))
            .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, LayoutTokens.Padding.screenHorizontal(for: sizeClass))
        .padding(.vertical, LayoutTokens.Padding.rowVertical)
        .glassEffect()
      }
      .buttonStyle(.plain)
    }
  }
}
