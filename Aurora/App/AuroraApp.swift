//
//  AuroraApp.swift
//  Aurora
//
//  Created by souhail on 12/1/25.
//

import SwiftUI
import SwiftData

#if canImport(UIKit)
import UIKit
#endif

@main
struct AuroraApp: App {
  #if os(iOS)
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  #endif

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
    #if os(macOS)
    .windowStyle(.hiddenTitleBar)
    .windowToolbarStyle(.unified(showsTitle: false))
    .defaultSize(width: 1000, height: 700)
    #endif
    .modelContainer(container)

    #if os(macOS)
    Settings {
      SettingsView()
        .environment(taskStore)
        .environment(userProfileStore)
        .frame(minWidth: 500, minHeight: 400)
    }
    #endif
  }
}
