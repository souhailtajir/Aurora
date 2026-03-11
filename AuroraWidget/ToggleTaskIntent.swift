//
//  ToggleTaskIntent.swift
//  Aurora
//
//  Rewritten to use shared ModelContainerHelper.
//

import AppIntents
import SwiftData

struct ToggleTaskIntent: AppIntent {
  static var title: LocalizedStringResource = "Toggle Task Completion"
  static var description = IntentDescription("Toggles the completion status of a specific task.")

  @Parameter(title: "Task ID")
  var taskId: String

  init() {}

  init(taskId: String) {
    self.taskId = taskId
  }

  @MainActor
  func perform() async throws -> some IntentResult {
    guard let container = ModelContainerHelper.shared() else {
      return .result()
    }

    let context = container.mainContext

    if let uuid = UUID(uuidString: taskId) {
      let descriptor = FetchDescriptor<Task>(predicate: #Predicate { $0.id == uuid })
      if let task = try? context.fetch(descriptor).first {
        task.isCompleted.toggle()
        try? context.save()
      }
    }

    return .result()
  }
}
