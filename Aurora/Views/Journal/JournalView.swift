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
      .safeAreaPadding(.top, 8)
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
    VStack(spacing: 24) {
      Spacer()

      Image(systemName: "lock.fill")
        .font(.system(size: 48))
        .foregroundStyle(.secondary)

      Text("Journal Locked")
        .font(.system(size: 20, weight: .semibold))
        .foregroundStyle(.primary)

      Text("Use Face ID to unlock")
        .font(.system(size: 15))
        .foregroundStyle(.secondary)

      Button {
        AsyncTask { await unlockWithBiometrics() }
      } label: {
        HStack(spacing: 8) {
          Image(systemName: "faceid")
            .font(.system(size: 18))
          Text("Unlock")
            .font(.system(size: 16, weight: .semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
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
    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
    .listRowBackground(Color.clear)
    .listRowSeparator(.hidden)

    // Streak card
    JournalStreakCard(streak: streak)
      .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
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
    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
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
    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
    .listRowBackground(Color.clear)
    .listRowSeparator(.hidden)

    // Recent entries section header
    recentEntriesHeader
      .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 8, trailing: 16))
      .listRowBackground(Color.clear)
      .listRowSeparator(.hidden)

    // Recent entries content
    if recentsExpanded {
      if recentEntries.isEmpty {
        emptyState
          .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
          .listRowBackground(Color.clear)
          .listRowSeparator(.hidden)
      } else {
        ForEach(recentEntries) { entry in
          JournalEntryRow(entry: entry) {
            navigationPath.append(entry)
          }
          .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
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
      VStack(spacing: 12) {
        Image(systemName: "magnifyingglass")
          .font(.system(size: 36))
          .foregroundStyle(.secondary)
        Text("No results")
          .font(.system(size: 15))
          .foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 60)
      .listRowInsets(EdgeInsets())
      .listRowBackground(Color.clear)
      .listRowSeparator(.hidden)
    } else {
      ForEach(results) { entry in
        JournalEntryRow(entry: entry) {
          navigationPath.append(entry)
        }
        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
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
    VStack(spacing: 8) {
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
    VStack(alignment: .leading, spacing: 12) {
      Button {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
          recentsExpanded.toggle()
        }
      } label: {
        HStack {
          Text("Recent")
            .font(.system(size: 22, weight: .bold))
            .foregroundStyle(.primary)

          Image(systemName: recentsExpanded ? "chevron.down" : "chevron.right")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.secondary)
            .contentTransition(.symbolEffect(.replace))

          Spacer()
        }
        .padding(.horizontal, 4)
      }
      .buttonStyle(.plain)

      if recentsExpanded {
        if recentEntries.isEmpty {
          emptyState
        } else {
          VStack(spacing: 8) {
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
    VStack(spacing: 12) {
      Image(systemName: "book.closed")
        .font(.system(size: 36))
        .foregroundStyle(.secondary.opacity(0.5))

      Text("No entries yet")
        .font(.system(size: 15))
        .foregroundStyle(.secondary)

      Text("Tap + to start writing")
        .font(.system(size: 13))
        .foregroundStyle(.tertiary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 32)
  }

  private var recentEntriesHeader: some View {
    Button {
      withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
        recentsExpanded.toggle()
      }
    } label: {
      HStack {
        Text("Recent")
          .font(.system(size: 22, weight: .bold))
          .foregroundStyle(.primary)

        Image(systemName: recentsExpanded ? "chevron.down" : "chevron.right")
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(.secondary)
          .contentTransition(.symbolEffect(.replace))

        Spacer()
      }
      .padding(.horizontal, 4)
    }
    .buttonStyle(.plain)
  }

  // MARK: - Search Results

  private var searchResults: some View {
    VStack(spacing: 8) {
      let results = filteredEntries
      if results.isEmpty {
        VStack(spacing: 12) {
          Image(systemName: "magnifyingglass")
            .font(.system(size: 36))
            .foregroundStyle(.secondary)
          Text("No results")
            .font(.system(size: 15))
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
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

    var body: some View {
      Button(action: action) {
        HStack(spacing: 12) {
          Image(systemName: icon)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(color)

          Text(title)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(.primary)

          Spacer()

          if count > 0 {
            Text("\(count)")
              .font(.system(size: 16))
              .foregroundStyle(.secondary)
          }

          Image(systemName: "chevron.right")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .glassEffect()
      }
      .buttonStyle(.plain)
    }
  }
}
