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
      VStack(alignment: .leading, spacing: 4) {
        Text("All Entries")
          .font(.system(size: 28, weight: .bold))
        Text("\(taskStore.journalEntries.count) entries")
          .font(.system(size: 14))
          .foregroundStyle(.secondary)
      }
      .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 8, trailing: 16))
      .listRowBackground(Color.clear)
      .listRowSeparator(.hidden)

      // Empty state or entries
      if entries.isEmpty {
        VStack(spacing: 12) {
          Image(systemName: "book.closed")
            .font(.system(size: 36))
            .foregroundStyle(.secondary.opacity(0.5))
          Text("No entries yet")
            .font(.system(size: 15))
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
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
              .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
              .listRowBackground(Color.clear)
              .listRowSeparator(.hidden)
            }
          } header: {
            Text(month)
              .font(.system(size: 14, weight: .semibold))
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

#Preview {
  PreviewContainer {
    AllEntriesView()
  }
}

