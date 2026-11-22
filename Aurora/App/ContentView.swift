//
//  ContentView.swift
//  Aurora
//
//  Created by souhail on 12/1/25.
//

import SwiftUI

struct ContentView: View {
  @Environment(TaskStore.self) var taskStore
  @State private var selectedTab: Int = 0
  @State private var showingAddTask = false
  @State private var showingAddJournal = false
  @State private var newJournalEntryId: UUID?

  // macOS sidebar selection
  @State private var selectedSidebarItem: SidebarItem? = .home

  enum SidebarItem: String, CaseIterable, Identifiable {
    case home = "Home"
    case tasks = "Tasks"
    case journal = "Journal"
    case calendar = "Calendar"

    var id: Self { self }

    var icon: String {
      switch self {
      case .home: return "house.fill"
      case .tasks: return "list.bullet"
      case .journal: return "book.fill"
      case .calendar: return "calendar"
      }
    }
  }

  var body: some View {
    #if os(macOS)
    macOSLayout
    #else
    iOSLayout
    #endif
  }

  // MARK: - macOS Layout

  #if os(macOS)
  private var macOSLayout: some View {
    NavigationSplitView {
      List(SidebarItem.allCases, selection: $selectedSidebarItem) { item in
        Label(item.rawValue, systemImage: item.icon)
          .font(.system(size: 14, weight: .medium))
      }
      .navigationTitle("Aurora")
      .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 240)
    } detail: {
      Group {
        switch selectedSidebarItem {
        case .home:
          NavigationStack {
            HomeView()
          }
        case .tasks:
          NavigationStack {
            TasksView()
          }
        case .journal:
          NavigationStack {
            JournalView()
          }
        case .calendar:
          NavigationStack {
            CalendarView()
          }
        case nil:
          NavigationStack {
            HomeView()
          }
        }
      }
    }
    .background {
      WindowAccessor()
    }
    .sheet(isPresented: $showingAddTask) {
      TaskSheet()
        .frame(minWidth: 480, idealWidth: 520, minHeight: 600)
    }
    .sheet(isPresented: $showingAddJournal) {
      if let entryId = newJournalEntryId {
        NavigationStack {
          EntryEditorView(entryId: entryId)
        }
        .frame(minWidth: 500, minHeight: 600)
      }
    }
  }
  #endif

  // MARK: - iOS Layout

  private var iOSLayout: some View {
    ZStack(alignment: .top) {
      TabView(selection: $selectedTab) {
        Tab(value: 0) {
          HomeView()
        } label: {
          Label("Home", systemImage: "house.fill")
            .symbolEffect(.bounce, value: selectedTab == 0)
        }

        Tab(value: 1) {
          TasksView()
        } label: {
          Label("Tasks", systemImage: "list.bullet")
            .symbolEffect(.bounce, value: selectedTab == 1)
        }

        Tab(value: 2) {
          JournalView()
        } label: {
          Label("Journal", systemImage: "book.fill")
            .symbolEffect(.bounce, value: selectedTab == 2)
        }

        Tab(value: 3) {
          CalendarView()
        } label: {
          Label("Calendar", systemImage: "calendar")
            .symbolEffect(.bounce, value: selectedTab == 3)
        }
      }
      .tabViewStyle(.sidebarAdaptable)
      .tint(Theme.primary)

      #if os(iOS)
      // Global Status Bar Vignette (iOS 26 Look)
      LinearGradient(
        colors: [.black.opacity(0.6), .clear],
        startPoint: .top,
        endPoint: .bottom
      )
      .frame(height: 140)
      .ignoresSafeArea()
      .allowsHitTesting(false)
      #endif
    }
    #if os(iOS)
    .onChange(of: QuickActionManager.shared.action) { _, action in
      switch action {
      case .addTask:
        showingAddTask = true
      case .addJournal:
        let entry = JournalEntry(title: "", body: "", date: Date())
        taskStore.addJournalEntry(entry)
        newJournalEntryId = entry.id
        showingAddJournal = true
      case .openCalendar:
        withAnimation(.smooth(duration: 0.2)) {
          selectedTab = 3
        }
      case .none:
        break
      }
      QuickActionManager.shared.action = .none
    }
    #endif
    .sheet(isPresented: $showingAddTask) {
      TaskSheet()
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
    #if os(iOS)
    .fullScreenCover(isPresented: $showingAddJournal) {
      if let entryId = newJournalEntryId {
        NavigationStack {
          EntryEditorView(entryId: entryId)
        }
      }
    }
    #else
    .sheet(isPresented: $showingAddJournal) {
      if let entryId = newJournalEntryId {
        NavigationStack {
          EntryEditorView(entryId: entryId)
        }
        .frame(minWidth: 500, minHeight: 600)
      }
    }
    #endif
  }
}

// MARK: - Category Picker View

struct CategoryPickerView: View {
  @Environment(TaskStore.self) var taskStore
  @Environment(\.dismiss) var dismiss
  @Binding var selectedCategory: TaskCategory

  var body: some View {
    List {
      ForEach(taskStore.categories) { category in
        Button {
          selectedCategory = category
          dismiss()
        } label: {
          HStack {
            ZStack {
              RoundedRectangle(cornerRadius: 6)
                .fill(Color(hex: category.colorHex))
                .frame(width: 28, height: 28)

              Image(systemName: category.iconName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
            }

            Text(category.name)
              .foregroundStyle(.primary)

            Spacer()

            if category.id == selectedCategory.id {
              Image(systemName: "checkmark")
                .foregroundStyle(Theme.primary)
            }
          }
        }
      }
    }
    .navigationTitle("List")
    .toolbarTitleDisplayMode(.inline)
  }
}
