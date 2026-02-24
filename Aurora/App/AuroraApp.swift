//
//  AuroraApp.swift
//  Aurora
//
//  Created by souhail on 12/1/25.
//

import SwiftUI
import SwiftData

@main
struct AuroraApp: App {
  let container: ModelContainer
  @State private var taskStore: TaskStore
  @State private var userProfileStore = UserProfileStore()

  init() {
    do {
      let schema = Schema([
        Task.self,
        TaskCategory.self,
        JournalEntry.self
      ])
      let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
      container = try ModelContainer(for: schema, configurations: [modelConfiguration])
      
      let store = TaskStore(modelContext: container.mainContext)
      _taskStore = State(initialValue: store)
    } catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(taskStore)
        .environment(userProfileStore)
        .preferredColorScheme(.dark)
    }
    .modelContainer(container)
  }
}
