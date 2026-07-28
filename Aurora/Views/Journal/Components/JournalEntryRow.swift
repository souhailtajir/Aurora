//
//  JournalEntryRow.swift
//  Aurora
//

import SwiftUI

struct JournalEntryRow: View {
  @Environment(TaskStore.self) var taskStore
  let entry: JournalEntry
  let onTap: () -> Void

  private var timeText: String {
    entry.date.formatted(.dateTime.hour().minute())
  }

  private var dateText: String {
    let cal = Calendar.current
    if cal.isDateInToday(entry.date) { return "Today" }
    if cal.isDateInYesterday(entry.date) { return "Yesterday" }
    return entry.date.formatted(.dateTime.month(.abbreviated).day())
  }

  var body: some View {
    Button(action: onTap) {
      VStack(alignment: .leading, spacing: 6) {
        HStack(spacing: 8) {
          Text(entry.title.isEmpty ? "Untitled Entry" : entry.title)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.primary)
            .lineLimit(1)

          Spacer()

          Text(dateText)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Theme.primary)

          Image(systemName: "chevron.right")
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.tertiary)
        }

        if !entry.body.isEmpty {
          Text(entry.body)
            .font(.system(size: 14))
            .foregroundStyle(.secondary)
            .lineLimit(2)
            .lineSpacing(2)
        }

        HStack(spacing: 6) {
          Image(systemName: "clock")
            .font(.system(size: 11))
          Text(timeText)
            .font(.system(size: 12, weight: .medium))

          if let loc = entry.locationName {
            Text("•")
            Image(systemName: "location.fill")
              .font(.system(size: 10))
            Text(loc)
              .font(.system(size: 12))
              .lineLimit(1)
          }
        }
        .foregroundStyle(.tertiary)
        .padding(.top, 2)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 14)
      .background {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .glassEffect(.regular)
      }
    }
    .buttonStyle(.plain)
    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
      Button(role: .destructive) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
          taskStore.deleteJournalEntry(entry)
        }
      } label: {
        Label("Delete", systemImage: "trash")
      }
    }
  }
}
