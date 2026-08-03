//
//  DeletedEntriesView.swift
//  Aurora
//

import SwiftUI

struct DeletedEntriesView: View {
  @Environment(TaskStore.self) var taskStore
  @Environment(\.dismiss) var dismiss
  @State private var searchText = ""
  @State private var isSearching = false
  @State private var isSelecting = false
  @State private var selectedEntries: Set<UUID> = []
  @Environment(\.horizontalSizeClass) private var sizeClass

  private var filteredEntries: [JournalEntry] {
    if searchText.isEmpty {
      return taskStore.deletedJournalEntries
    }
    return taskStore.deletedJournalEntries.filter {
      $0.title.localizedCaseInsensitiveContains(searchText)
        || $0.body.localizedCaseInsensitiveContains(searchText)
    }
  }

  private var allSelected: Bool {
    !filteredEntries.isEmpty && selectedEntries.count == filteredEntries.count
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: LayoutTokens.Spacing.lg) {
        // Header
        VStack(alignment: .leading, spacing: LayoutTokens.Spacing.xs) {
          Text("Recently Deleted")
            .font(.system(size: LayoutTokens.Typography.largeTitle, weight: .bold))
          Text("\(taskStore.deletedJournalEntries.count) entries")
            .font(.system(size: LayoutTokens.Typography.subheadline))
            .foregroundStyle(.secondary)
        }
        .padding(.top, LayoutTokens.Spacing.lg)

        // Empty state or entries
        if taskStore.deletedJournalEntries.isEmpty {
          VStack(spacing: LayoutTokens.Spacing.md) {
            Image(systemName: "trash")
              .font(.system(size: LayoutTokens.Typography.emptyStateIcon))
              .foregroundStyle(.secondary.opacity(0.5))
            Text("No deleted entries")
              .font(.system(size: LayoutTokens.Typography.callout))
              .foregroundStyle(.secondary)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, LayoutTokens.Spacing.xxl * 3)
        } else {
          ForEach(filteredEntries) { entry in
            deletedRowContent(entry)
          }
        }
      }
      .padding(.horizontal, LayoutTokens.Padding.screenHorizontal(for: sizeClass))
      .padding(.bottom, LayoutTokens.Padding.scrollBottom)  // Space for bottom bar
    }
    .scrollIndicators(.hidden)
    .background(Color.clear.auroraBackground())
    .toolbar(.hidden, for: .tabBar)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        if !taskStore.deletedJournalEntries.isEmpty {
          Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
              if isSelecting {
                // Toggle select all / deselect all
                if allSelected {
                  selectedEntries.removeAll()
                } else {
                  selectedEntries = Set(filteredEntries.map { $0.id })
                }
              } else {
                isSelecting = true
              }
            }
          } label: {
            Text(isSelecting ? (allSelected ? "Deselect All" : "Select All") : "Select")
              .font(.system(size: LayoutTokens.Typography.body, weight: .medium))
              .foregroundStyle(Theme.tint)
          }
        }
      }
      ToolbarSpacer(placement: .topBarTrailing)

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
          placeholder: "Search deleted entries..."
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
      } else if !taskStore.deletedJournalEntries.isEmpty {
        bottomActionBar
          .transition(.move(edge: .bottom).combined(with: .opacity))
      }
    }
    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isSearching)
    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isSelecting)
    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedEntries.count)
  }

  // MARK: - Bottom Action Bar

  private var bottomActionBar: some View {
    HStack(spacing: LayoutTokens.Spacing.md) {
      if isSelecting && !selectedEntries.isEmpty {
        // Selected items actions
        Button {
          withAnimation {
            for entryId in selectedEntries {
              if let entry = taskStore.deletedJournalEntries.first(where: { $0.id == entryId }) {
                taskStore.restoreJournalEntry(entry)
              }
            }
            selectedEntries.removeAll()
            if taskStore.deletedJournalEntries.isEmpty {
              isSelecting = false
            }
          }
        } label: {
          HStack(spacing: LayoutTokens.Spacing.sm) {
            Image(systemName: "arrow.uturn.backward")
            Text("Recover (\(selectedEntries.count))")
          }
          .font(.system(size: LayoutTokens.Typography.body, weight: .semibold))
          .foregroundStyle(.white)
          .frame(maxWidth: .infinity)
          .padding(.vertical, LayoutTokens.Padding.rowVertical)
          .background(Theme.tint, in: .rect(cornerRadius: LayoutTokens.Radius.lg))
        }

        Button {
          withAnimation {
            for entryId in selectedEntries {
              if let entry = taskStore.deletedJournalEntries.first(where: { $0.id == entryId }) {
                taskStore.permanentlyDeleteJournalEntry(entry)
              }
            }
            selectedEntries.removeAll()
            if taskStore.deletedJournalEntries.isEmpty {
              isSelecting = false
            }
          }
        } label: {
          HStack(spacing: LayoutTokens.Spacing.sm) {
            Image(systemName: "trash")
            Text("Delete (\(selectedEntries.count))")
          }
          .font(.system(size: LayoutTokens.Typography.body, weight: .semibold))
          .foregroundStyle(.white)
          .frame(maxWidth: .infinity)
          .padding(.vertical, LayoutTokens.Padding.rowVertical)
          .background(.red, in: .rect(cornerRadius: LayoutTokens.Radius.lg))
        }
      } else if isSelecting {
        // Selecting mode but nothing selected - show cancel
        Button {
          withAnimation {
            isSelecting = false
            selectedEntries.removeAll()
          }
        } label: {
          Text("Cancel")
            .font(.system(size: LayoutTokens.Typography.body, weight: .semibold))
            .foregroundStyle(Theme.tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, LayoutTokens.Padding.rowVertical)
            .background(.ultraThinMaterial, in: .rect(cornerRadius: LayoutTokens.Radius.lg))
        }
      } else {
        // Not selecting - show Recover All / Delete All
        Button {
          withAnimation {
            for entry in taskStore.deletedJournalEntries {
              taskStore.restoreJournalEntry(entry)
            }
          }
        } label: {
          HStack(spacing: LayoutTokens.Spacing.sm) {
            Image(systemName: "arrow.uturn.backward")
            Text("Recover All")
          }
          .font(.system(size: LayoutTokens.Typography.body, weight: .semibold))
          .foregroundStyle(.white)
          .frame(maxWidth: .infinity)
          .padding(.vertical, LayoutTokens.Padding.rowVertical)
          .background(Theme.tint, in: .rect(cornerRadius: LayoutTokens.Radius.lg))
        }

        Button {
          withAnimation {
            for entry in taskStore.deletedJournalEntries {
              taskStore.permanentlyDeleteJournalEntry(entry)
            }
          }
        } label: {
          HStack(spacing: LayoutTokens.Spacing.sm) {
            Image(systemName: "trash")
            Text("Delete All")
          }
          .font(.system(size: LayoutTokens.Typography.body, weight: .semibold))
          .foregroundStyle(.white)
          .frame(maxWidth: .infinity)
          .padding(.vertical, LayoutTokens.Padding.rowVertical)
          .background(.red, in: .rect(cornerRadius: LayoutTokens.Radius.lg))
        }
      }
    }
    .padding(LayoutTokens.Spacing.md)
    .glassEffect(.clear, in: .capsule)
    .padding(.horizontal, LayoutTokens.Padding.screenHorizontal(for: sizeClass))
    .padding(.bottom, LayoutTokens.Spacing.sm)
  }

  // MARK: - Row Content

  private func deletedRowContent(_ entry: JournalEntry) -> some View {
    Button {
      // Toggle selection when tapped
      withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
        if !isSelecting {
          isSelecting = true
        }
        if selectedEntries.contains(entry.id) {
          selectedEntries.remove(entry.id)
        } else {
          selectedEntries.insert(entry.id)
        }
      }
    } label: {
      HStack(spacing: LayoutTokens.Spacing.md) {
        VStack(alignment: .leading, spacing: LayoutTokens.Spacing.xs) {
          Text(entry.title.isEmpty ? "Untitled" : entry.title)
            .font(.system(size: LayoutTokens.Typography.body, weight: .medium))
            .foregroundStyle(.primary)
            .lineLimit(1)

          if let deletedAt = entry.deletedAt {
            Text("Deleted \(deletedAt.formatted(.relative(presentation: .named)))")
              .font(.system(size: LayoutTokens.Typography.footnote))
              .foregroundStyle(.secondary)
          }
        }

        Spacer()

        // Show selection indicator only in selection mode
        if isSelecting {
          if selectedEntries.contains(entry.id) {
            Image(systemName: "checkmark.circle.fill")
              .font(.system(size: LayoutTokens.IconSize.lg))
              .foregroundStyle(Theme.tint)
          } else {
            Image(systemName: "circle")
              .font(.system(size: LayoutTokens.IconSize.lg))
              .foregroundStyle(.secondary.opacity(0.5))
          }
        }
      }
      .padding(.horizontal, LayoutTokens.Padding.screenHorizontal(for: sizeClass))
      .padding(.vertical, LayoutTokens.Spacing.md)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .glassEffect()
  }
}
