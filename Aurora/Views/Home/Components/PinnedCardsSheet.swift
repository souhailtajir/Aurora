//
//  PinnedCardsSheet.swift
//  Aurora
//
//  Created by souhail on 12/31/25.
//

import SwiftUI

/// Represents a pinned card item that can be either a smart list or a category
enum PinnedCardItem: Identifiable, Equatable, Hashable {
  case smartList(SmartListType)
  case category(TaskCategory)

  var id: String {
    switch self {
    case .smartList(let type): return "smart_\(type.rawValue)"
    case .category(let cat): return "category_\(cat.id.uuidString)"
    }
  }

  var title: String {
    switch self {
    case .smartList(let type): return type.title
    case .category(let cat): return cat.name
    }
  }

  var icon: String {
    switch self {
    case .smartList(let type): return type.icon
    case .category(let cat): return cat.iconName
    }
  }

  var color: Color {
    switch self {
    case .smartList(let type): return type.color
    case .category(let cat): return Color(hex: cat.colorHex)
    }
  }
}

struct PinnedCardsSheet: View {
  @Environment(TaskStore.self) var taskStore
  @Environment(\.dismiss) var dismiss
  @State private var pinnedItems: [PinnedCardItem] = []
  @State private var isEditing = false

  private let maxPinnedCards = 2

  private var canAddMore: Bool {
    pinnedItems.count < maxPinnedCards
  }

  var body: some View {
    NavigationStack {
      List {
        // Currently pinned section (reorderable)
        Section {
          if pinnedItems.isEmpty {
            Text("No cards pinned")
              .foregroundStyle(.secondary)
          } else {
            ForEach(pinnedItems) { item in
              HStack {
                Label(item.title, systemImage: item.icon)
                  .foregroundStyle(item.color)
                Spacer()
                if !isEditing {
                  Button {
                    withAnimation {
                      pinnedItems.removeAll { $0.id == item.id }
                    }
                  } label: {
                    Image(systemName: "minus.circle.fill")
                      .foregroundStyle(.red)
                  }
                }
              }
            }
            .onMove { from, to in
              pinnedItems.move(fromOffsets: from, toOffset: to)
            }
          }
        } header: {
          HStack {
            Text("Pinned (\(pinnedItems.count)/\(maxPinnedCards))")
            Spacer()
            if !pinnedItems.isEmpty {
              Text("First = Left, Second = Right")
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
          }
        }

        // Available smart lists
        Section {
          ForEach(SmartListType.allCases) { listType in
            let item = PinnedCardItem.smartList(listType)
            let isPinned = pinnedItems.contains(item)

            Toggle(
              isOn: Binding(
                get: { isPinned },
                set: { isOn in
                  if isOn && canAddMore {
                    withAnimation { pinnedItems.append(item) }
                  } else if !isOn {
                    withAnimation { pinnedItems.removeAll { $0.id == item.id } }
                  }
                }
              )
            ) {
              Label(listType.title, systemImage: listType.icon)
                .foregroundStyle(listType.color)
            }
            .tint(Theme.primary)
            .disabled(!canAddMore && !isPinned)
          }
        } header: {
          Text("Smart Lists")
        }

        // Available categories
        Section {
          ForEach(taskStore.categories) { category in
            let item = PinnedCardItem.category(category)
            let isPinned = pinnedItems.contains(item)

            Toggle(
              isOn: Binding(
                get: { isPinned },
                set: { isOn in
                  if isOn && canAddMore {
                    withAnimation { pinnedItems.append(item) }
                  } else if !isOn {
                    withAnimation { pinnedItems.removeAll { $0.id == item.id } }
                  }
                }
              )
            ) {
              Label(category.name, systemImage: category.iconName)
                .foregroundStyle(Color(hex: category.colorHex))
            }
            .tint(Theme.primary)
            .disabled(!canAddMore && !isPinned)
          }
        } header: {
          Text("Categories")
        }
      }
      .environment(\.editMode, .constant(isEditing ? .active : .inactive))
      .navigationTitle("Pinned Cards")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(isEditing ? "Done" : "Edit") {
            withAnimation {
              isEditing.toggle()
            }
          }
        }
        ToolbarItem(placement: .topBarTrailing) {
          Button("Save") {
            saveAndDismiss()
          }
          .fontWeight(.semibold)
        }
      }
      .onAppear {
        loadPinnedItems()
      }
    }
  }

  private func toggleItem(_ item: PinnedCardItem) {
    withAnimation {
      if let index = pinnedItems.firstIndex(of: item) {
        pinnedItems.remove(at: index)
      } else if canAddMore {
        pinnedItems.append(item)
      }
    }
  }

  private func loadPinnedItems() {
    // Load in order: smart lists first, then categories
    var items: [PinnedCardItem] = []

    for listType in taskStore.pinnedHomeSmartLists {
      items.append(.smartList(listType))
    }

    for category in taskStore.categories where taskStore.pinnedHomeCategoryIds.contains(category.id)
    {
      items.append(.category(category))
    }

    // Limit to max
    pinnedItems = Array(items.prefix(maxPinnedCards))
  }

  private func saveAndDismiss() {
    var smartLists: [SmartListType] = []
    var categoryIds: [UUID] = []

    // Save in order (first 2 only) - order matters for left/right positioning
    for item in pinnedItems.prefix(maxPinnedCards) {
      switch item {
      case .smartList(let type):
        smartLists.append(type)
      case .category(let cat):
        categoryIds.append(cat.id)
      }
    }

    taskStore.pinnedHomeSmartLists = smartLists
    taskStore.pinnedHomeCategoryIds = categoryIds
    dismiss()
  }
}

#Preview {
  PreviewContainer {
    PinnedCardsSheet()
  }
}

