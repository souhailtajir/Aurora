//
//  ToggleTaskIntent.swift
//  Aurora
//
//  Created on 1/21/26.
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

    func perform() async throws -> some IntentResult {
        // Setup ModelContainer for the Intent
        // Note: In a real app group scenario, you'd pass the App Group URL here.
        let schema = Schema([
            Task.self,
            TaskCategory.self,
            JournalEntry.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        let context = container.mainContext
        
        // Fetch the task
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
