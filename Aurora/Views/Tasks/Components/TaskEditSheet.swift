//
//  TaskEditSheet.swift
//  Aurora
//
//  Sheet modal for task editing
//

import SwiftUI

struct TaskEditSheet: View {
    let task: Task
    @Environment(TaskStore.self) var taskStore
    var onDismiss: () -> Void
    
    @State private var draftTask: Task
    @FocusState private var focusedField: Field?
    
    enum Field {
        case title, notes, url
    }
    
    init(task: Task, onDismiss: @escaping () -> Void) {
        self.task = task
        self.onDismiss = onDismiss
        _draftTask = State(initialValue: task)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with checkbox
                    HStack(spacing: 16) {
                        completionCheckbox
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    // Content
                    VStack(spacing: 20) {
                        // Title & Notes
                        textFieldsSection
                        
                        // Metadata
                        metadataSection
                        
                        // Date & Time
                        dateTimeSection
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 20)
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        onDismiss()
                    }
                }
            }
            .onChange(of: draftTask) { _, newValue in
                taskStore.updateTask(newValue)
            }
        }
    }
    
    // MARK: - Components
    
    private var completionCheckbox: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3)) {
                draftTask.isCompleted.toggle()
                taskStore.toggleTaskCompletion(draftTask)
            }
        }) {
            HStack(spacing: 12) {
                Circle()
                    .fill((draftTask.category.map { Theme.categoryColor(for: $0) } ?? .gray).opacity(0.25))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .strokeBorder(draftTask.category.map { Theme.categoryColor(for: $0) } ?? .gray, lineWidth: 2)
                    )
                    .overlay(
                        draftTask.isCompleted ?
                        Image(systemName: "checkmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(draftTask.category.map { Theme.categoryColor(for: $0) } ?? .gray)
                        : nil
                    )
                
                Text(draftTask.isCompleted ? "Completed" : "Mark Complete")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.primary)
            }
        }
        .buttonStyle(.plain)
    }
    
    private var textFieldsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Task title", text: $draftTask.title)
                .font(.system(size: 20, weight: .semibold))
                .focused($focusedField, equals: .title)
            
            TextField("Notes", text: $draftTask.notes, axis: .vertical)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .lineLimit(1...5)
                .focused($focusedField, equals: .notes)
            
            TextField("URL (optional)", text: $draftTask.url)
                .font(.system(size: 14))
                .foregroundStyle(.blue)
                .keyboardType(.URL)
                .autocapitalization(.none)
                .focused($focusedField, equals: .url)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var metadataSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Details")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Spacer()
            }
            
            HStack(spacing: 10) {
                // Category
                Menu {
                    ForEach(taskStore.categories) { category in
                        Button(category.name) {
                            draftTask.category = category
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(draftTask.category.map { Theme.categoryColor(for: $0) } ?? .gray)
                            .frame(width: 8, height: 8)
                        Text(draftTask.category?.name ?? "None")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(draftTask.category.map { Theme.categoryColor(for: $0) } ?? .gray)
                    )
                }
                
                // Flag
                Button(action: { draftTask.isFlagged.toggle() }) {
                    Image(systemName: draftTask.isFlagged ? "flag.fill" : "flag")
                        .font(.system(size: 15))
                        .foregroundStyle(draftTask.isFlagged ? .orange : .secondary)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(draftTask.isFlagged ? .orange.opacity(0.15) : Color.white.opacity(0.1))
                        )
                }
                .buttonStyle(.plain)
                
                // Priority
                Menu {
                    ForEach(TaskPriority.allCases) { priority in
                        Button(priority.rawValue) {
                            draftTask.priority = priority
                        }
                    }
                } label: {
                    Text(draftTask.priority.rawValue)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(draftTask.priority == .none ? .secondary : Color.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(draftTask.priority == .none ? Color.white.opacity(0.1) : draftTask.priority.color)
                        )
                }
                
                Spacer()
            }
        }
    }
    
    private var dateTimeSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Schedule")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Spacer()
            }
            
            HStack(spacing: 12) {
                // Date
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                    
                    DatePicker("", selection: Binding(
                        get: { draftTask.date ?? Date() },
                        set: { draftTask.date = $0 }
                    ), displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.compact)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                
                // Time
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                    
                    DatePicker("", selection: Binding(
                        get: { draftTask.date ?? Date() },
                        set: { draftTask.date = $0 }
                    ), displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .datePickerStyle(.compact)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                
                Spacer()
            }
        }
    }
}

#Preview {
    PreviewContainer {
        TaskEditSheet(
            task: Task(title: "Review Design Specs", notes: "Check Figma files"),
            onDismiss: {}
        )
    }
}

