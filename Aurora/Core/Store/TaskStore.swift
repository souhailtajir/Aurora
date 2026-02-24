//
//  TaskStore.swift
//  Aurora
//
//  Created by souhail on 12/1/25.
//

import Observation
import SwiftUI
import SwiftData

@Observable
final class TaskStore {
  var tasks: [Task] = []
  var categories: [TaskCategory] = []
  var journalEntries: [JournalEntry] = []
  var deletedJournalEntries: [JournalEntry] = []
  
  var addTaskTrigger: AddTaskTrigger = .none
  var addJournalTrigger: Bool = false

  // MARK: - Settings
  var visibleSmartLists: Set<SmartListType> = [.today, .all, .flagged] { didSet { saveSettings() } }
  var visibleCategories: Set<UUID> = [] { didSet { saveSettings() } }
  var smartListOrder: [SmartListType] = [] { didSet { saveSettings() } }
  var pinnedHomeSmartLists: [SmartListType] = [.flagged] { didSet { saveSettings() } }
  var pinnedHomeCategoryIds: [UUID] = [] { didSet { saveSettings() } }
  var weekStartsOnMonday: Bool = true { didSet { saveSettings() } }
  var myListsExpanded: Bool = true

  enum AddTaskTrigger {
    case none, home, tasks
  }

  private var modelContext: ModelContext

  init(modelContext: ModelContext) {
    self.modelContext = modelContext
    loadSettings()
    loadData()
  }
  
  // MARK: - Data Loading
  func loadData() {
    fetchCategories()
    fetchTasks()
    fetchJournal()
  }
  
  private func fetchCategories() {
    do {
      let descriptor = FetchDescriptor<TaskCategory>(sortBy: [SortDescriptor(\.name)])
      categories = try modelContext.fetch(descriptor)
      
      if categories.isEmpty {
        seedCategories()
      }
    } catch {
      print("Failed to fetch categories: \(error)")
    }
  }
  
  private func fetchTasks() {
    do {
      let descriptor = FetchDescriptor<Task>(sortBy: [SortDescriptor(\.date)])
      tasks = try modelContext.fetch(descriptor)
    } catch {
      print("Failed to fetch tasks: \(error)")
    }
  }
  
  private func fetchJournal() {
    do {
      let descriptor = FetchDescriptor<JournalEntry>(predicate: #Predicate { $0.deletedAt == nil }, sortBy: [SortDescriptor(\.date, order: .reverse)])
      journalEntries = try modelContext.fetch(descriptor)
      
      let deletedDescriptor = FetchDescriptor<JournalEntry>(predicate: #Predicate { $0.deletedAt != nil }, sortBy: [SortDescriptor(\.deletedAt, order: .reverse)])
      deletedJournalEntries = try modelContext.fetch(deletedDescriptor)
    } catch {
      print("Failed to fetch journal: \(error)")
    }
  }
  
  private func seedCategories() {
    let defaults = TaskCategory.defaults()
    for cat in defaults {
      modelContext.insert(cat)
    }
    saveContext()
    fetchCategories() // Reload to get the managed objects
  }

  // MARK: - Task Management
  func addTask(_ task: Task) {
    // If task has a category that isn't persistent, try to find matching existing category or default
    if task.category == nil || task.category?.modelContext == nil {
        if let defaultCat = categories.first(where: { $0.name == "Personal" }) ?? categories.first {
            task.category = defaultCat
        }
    }
      
    modelContext.insert(task)
    saveContext()
    fetchTasks()
  }

  func updateTask(_ task: Task) {
    // SwiftData objects are reference types, so modifying properties updates the object.
    // We just need to save.
    saveContext()
    // Trigger UI refresh if needed (arrays might need re-fetching if sort order changed)
    fetchTasks()
  }

  func deleteTask(_ task: Task) {
    modelContext.delete(task)
    saveContext()
    fetchTasks()
  }

  func toggleTaskCompletion(_ task: Task) {
    task.isCompleted.toggle()
    saveContext()
    fetchTasks()
  }

  func clearCompletedTasks() {
    for task in tasks where task.isCompleted {
        modelContext.delete(task)
    }
    saveContext()
    fetchTasks()
  }

  // MARK: - Category Management
  func addCategory(_ category: TaskCategory) {
    modelContext.insert(category)
    saveContext()
    fetchCategories()
  }

  func deleteCategory(_ category: TaskCategory) {
    modelContext.delete(category)
    saveContext()
    fetchCategories()
    fetchTasks() // Tasks might be deleted or affected
  }

  func updateCategory(_ category: TaskCategory) {
    saveContext()
    fetchCategories()
  }

  // MARK: - Journal Management
  func addJournalEntry(_ entry: JournalEntry) {
    modelContext.insert(entry)
    saveContext()
    fetchJournal()
  }

  func deleteJournalEntry(_ entry: JournalEntry) {
    entry.deletedAt = Date()
    saveContext()
    fetchJournal()
  }

  func permanentlyDeleteJournalEntry(_ entry: JournalEntry) {
    modelContext.delete(entry)
    saveContext()
    fetchJournal()
  }

  func restoreJournalEntry(_ entry: JournalEntry) {
    entry.deletedAt = nil
    saveContext()
    fetchJournal()
  }

  func cleanupOldDeletedEntries() {
      // Fetch directly from deleted list logic or just iterate
      // Logic handled in fetch or manually here.
      let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
      for entry in deletedJournalEntries {
          if let deletedAt = entry.deletedAt, deletedAt < thirtyDaysAgo {
              modelContext.delete(entry)
          }
      }
      saveContext()
      fetchJournal()
  }

  func updateJournalEntry(_ entry: JournalEntry) {
    saveContext()
    fetchJournal()
  }

  // MARK: - Persistence Helper
  private func saveContext() {
    try? modelContext.save()
  }

  // MARK: - Settings Persistence (UserDefaults)
  private func loadSettings() {
      if let data = UserDefaults.standard.data(forKey: "AppSettings"),
         let settings = try? JSONDecoder().decode(AppSettings.self, from: data) {
          self.visibleSmartLists = Set(settings.visibleSmartLists)
          self.visibleCategories = Set(settings.visibleCategories)
          self.smartListOrder = settings.smartListOrder
          self.pinnedHomeSmartLists = settings.pinnedHomeSmartLists
          self.pinnedHomeCategoryIds = settings.pinnedHomeCategoryIds
          self.weekStartsOnMonday = settings.weekStartsOnMonday
      }
  }

  private func saveSettings() {
      let settings = AppSettings(
        visibleSmartLists: Array(visibleSmartLists),
        visibleCategories: Array(visibleCategories),
        smartListOrder: smartListOrder,
        pinnedHomeSmartLists: Array(pinnedHomeSmartLists),
        pinnedHomeCategoryIds: Array(pinnedHomeCategoryIds),
        weekStartsOnMonday: weekStartsOnMonday
      )
      if let data = try? JSONEncoder().encode(settings) {
          UserDefaults.standard.set(data, forKey: "AppSettings")
      }
  }
}
