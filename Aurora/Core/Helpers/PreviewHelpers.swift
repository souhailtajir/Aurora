//
//  PreviewHelpers.swift
//  Aurora
//
//  Shared preview utilities for Xcode Canvas previews
//

import SwiftData
import SwiftUI

/// A container for SwiftUI previews that sets up an in-memory ModelContainer
/// with TaskStore and UserProfileStore environments.
struct PreviewContainer<Content: View>: View {
  let content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    content
      .environment(Self.makeTaskStore())
      .environment(UserProfileStore())
      .preferredColorScheme(.dark)
  }

  @MainActor
  static func makeTaskStore() -> TaskStore {
    let schema = Schema([Task.self, TaskCategory.self, JournalEntry.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    return TaskStore(modelContext: container.mainContext)
  }
}
