//
//  JournalEntryRow.swift
//  Aurora
//

import SwiftUI

struct JournalEntryRow: View {
  @Environment(TaskStore.self) var taskStore
  let entry: JournalEntry
  let onTap: () -> Void
  @Environment(\.horizontalSizeClass) private var sizeClass

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
      VStack(alignment: .leading, spacing: LayoutTokens.Spacing.sm) {
        HStack(spacing: LayoutTokens.Spacing.sm) {
          Text(entry.title.isEmpty ? "Untitled Entry" : entry.title)
            .font(.system(size: LayoutTokens.Typography.body, weight: .semibold))
            .foregroundStyle(.primary)
            .lineLimit(1)

          Spacer()

          Text(dateText)
            .font(.system(size: LayoutTokens.Typography.caption, weight: .medium))
            .foregroundStyle(Theme.primary)

          Image(systemName: "chevron.right")
            .font(.system(size: LayoutTokens.Typography.caption, weight: .bold))
            .foregroundStyle(.tertiary)
        }

        if !entry.body.isEmpty {
          Text(entry.body)
            .font(.system(size: LayoutTokens.Typography.subheadline))
            .foregroundStyle(.secondary)
            .lineLimit(2)
            .lineSpacing(2)
        }

        HStack(spacing: LayoutTokens.Spacing.xs) {
          Image(systemName: "clock")
            .font(.system(size: LayoutTokens.Typography.micro))
          Text(timeText)
            .font(.system(size: LayoutTokens.Typography.caption, weight: .medium))

          if let loc = entry.locationName {
            Text("•")
            Image(systemName: "location.fill")
              .font(.system(size: LayoutTokens.Typography.micro))
            Text(loc)
              .font(.system(size: LayoutTokens.Typography.caption))
              .lineLimit(1)
          }
        }
        .foregroundStyle(.tertiary)
        .padding(.top, 2)
      }
      .padding(.horizontal, LayoutTokens.Padding.screenHorizontal(for: sizeClass))
      .padding(.vertical, LayoutTokens.Padding.rowVertical)
      .background {
        Capsule(style: .continuous)
          .glassEffect(.clear)
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
