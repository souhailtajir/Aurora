//
//  AllEntriesView.swift
//  Aurora
//

import SwiftUI

struct AllEntriesView: View {
  @Environment(TaskStore.self) var taskStore
  @Environment(\.dismiss) var dismiss
  @State private var searchText = ""
  @State private var isSearching = false
  @State private var selectedEntry: JournalEntry?
  @Environment(\.horizontalSizeClass) private var sizeClass

  private var entries: [JournalEntry] {
    let sorted = taskStore.journalEntries.sorted { $0.date > $1.date }
    if searchText.isEmpty { return sorted }
    return sorted.filter {
      $0.title.localizedCaseInsensitiveContains(searchText)
        || $0.body.localizedCaseInsensitiveContains(searchText)
    }
  }

  private var grouped: [(String, [JournalEntry])] {
    let dict = Dictionary(grouping: entries) { entry in
      entry.date.formatted(.dateTime.month(.wide).year())
    }
    return dict.sorted { a, b in
      guard
        let d1 = entries.first(where: { $0.date.formatted(.dateTime.month(.wide).year()) == a.key }
        )?.date,
        let d2 = entries.first(where: { $0.date.formatted(.dateTime.month(.wide).year()) == b.key }
        )?.date
      else { return a.key > b.key }
      return d1 > d2
    }
  }

  var body: some View {
    List {
      // Header
      VStack(alignment: .leading, spacing: LayoutTokens.Spacing.xs) {
        Text("All Entries")
          .font(.system(size: LayoutTokens.Typography.largeTitle, weight: .bold))
        Text("\(taskStore.journalEntries.count) entries")
          .font(.system(size: LayoutTokens.Typography.subheadline))
          .foregroundStyle(.secondary)
      }
      .listRowInsets(EdgeInsets(top: LayoutTokens.Spacing.lg, leading: LayoutTokens.Padding.screenHorizontal(for: sizeClass), bottom: LayoutTokens.Spacing.sm, trailing: LayoutTokens.Padding.screenHorizontal(for: sizeClass)))
      .listRowBackground(Color.clear)
      .listRowSeparator(.hidden)

      // Empty state or entries
      if entries.isEmpty {
        VStack(spacing: LayoutTokens.Spacing.md) {
          Image(systemName: "book.closed")
            .font(.system(size: LayoutTokens.Typography.emptyStateIcon))
            .foregroundStyle(.secondary.opacity(0.5))
          Text("No entries yet")
            .font(.system(size: LayoutTokens.Typography.callout))
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, LayoutTokens.Spacing.xxl * 3)
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
      } else {
        // Grouped entries
        ForEach(grouped, id: \.0) { month, monthEntries in
          Section {
            ForEach(monthEntries) { entry in
              JournalEntryRow(entry: entry) {
                selectedEntry = entry
              }
              .listRowInsets(LayoutTokens.listRowInsets(vertical: LayoutTokens.Spacing.xs, for: sizeClass))
              .listRowBackground(Color.clear)
              .listRowSeparator(.hidden)
            }
          } header: {
            Text(month)
              .font(.system(size: LayoutTokens.Typography.subheadline, weight: .semibold))
              .foregroundStyle(Theme.tint)
              .textCase(nil)
          }
        }
      }
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
    .scrollIndicators(.hidden)
    .background(Color.clear.auroraBackground())
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
    .safeAreaInset(edge: .bottom) {
      if isSearching {
        BottomSearchBar(
          text: $searchText,
          isSearching: $isSearching,
          placeholder: "Search entries..."
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
      }
    }
    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isSearching)
    .navigationDestination(for: JournalEntry.self) { entry in
      EntryEditorView(entryId: entry.id)
    }
    .navigationDestination(item: $selectedEntry) { entry in
      EntryEditorView(entryId: entry.id)
    }
  }
}
