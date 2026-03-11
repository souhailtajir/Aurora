//
//  ModelContainerHelper.swift
//  Aurora
//
//  Created by antigravity on 3/11/26.
//

import Foundation
import SwiftData

public enum ModelContainerHelper {
    @MainActor
    public static func shared() -> ModelContainer? {
        let schema = Schema([
            AppTask.self,
            TaskCategory.self,
            JournalEntry.self
        ])
        
        // For a real app, you would use an App Group URL here.
        // For now, we'll use the default configuration to resolve compilation.
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("Could not create ModelContainer: \(error)")
            return nil
        }
    }
}
