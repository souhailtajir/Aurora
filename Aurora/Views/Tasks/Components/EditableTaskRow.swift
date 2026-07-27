//
//  EditableTaskRow.swift
//  Aurora
//
//  Created by souhail on 12/30/25.
//

import SwiftUI

struct EditableTaskRow: View {
  @Environment(TaskStore.self) var taskStore
  let task: Task

  // Bindings to parent state for exclusive editing
  @Binding var editingTaskId: UUID?
  @FocusState.Binding var focusedTaskId: UUID?

  // Callback to show task details
  var onInfoTap: (() -> Void)? = nil

  @State private var editedTitle: String = ""

  private var isEditing: Bool {
    editingTaskId == task.id
  }

  var body: some View {
    HStack(spacing: 12) {
      // Completion toggle
      Button {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
          taskStore.toggleTaskCompletion(task)
        }
      } label: {
        Circle()
          .fill(task.isCompleted ? Color(hex: task.category?.colorHex ?? "808080") : Color.clear)
          .frame(width: 24, height: 24)
          .overlay(
            Circle()
              .strokeBorder(Color(hex: task.category?.colorHex ?? "808080"), lineWidth: 2)
          )
          .overlay {
            if task.isCompleted {
              Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
            }
          }
      }
      .buttonStyle(.plain)

      // Main content
      VStack(alignment: .leading, spacing: 4) {
        // Title (editable)
        if isEditing {
          TextField("Task name", text: $editedTitle)
            .textFieldStyle(.plain)
            .font(.system(size: 16))
            .focused($focusedTaskId, equals: task.id)
            .onSubmit {
              saveAndDismiss()
            }
            .onAppear {
              editedTitle = task.title
            }
            .onChange(of: focusedTaskId) { _, newId in
              if newId != task.id && isEditing {
                saveAndDismiss()
              }
            }
        } else {
          Text(task.title.isEmpty ? "New Task" : task.title)
            .font(.system(size: 16))
            .foregroundStyle(task.title.isEmpty ? .secondary : .primary)
            .strikethrough(task.isCompleted)
            .lineLimit(1)
        }

        // Date and time info
        if let date = task.date, !isEditing {
          HStack(spacing: 6) {
            // Date
            HStack(spacing: 4) {
              Image(systemName: "calendar")
                .font(.system(size: 11))
              Text(formatDate(date))
                .font(.system(size: 12))
            }
            .foregroundStyle(isOverdue(date) ? .red : .secondary)

            // Time (if set)
            if hasTimeComponent(date) {
              HStack(spacing: 4) {
                Image(systemName: "clock")
                  .font(.system(size: 11))
                Text(formatTime(date))
                  .font(.system(size: 12))
              }
              .foregroundStyle(isOverdue(date) ? .red : .secondary)
            }
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .contentShape(Rectangle())
      .onTapGesture {
        if !isEditing {
          editedTitle = task.title
          editingTaskId = task.id
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            focusedTaskId = task.id
          }
        }
      }

      // Right side indicators
      if isEditing {
        // When editing: show flag (if flagged) next to info button
        if task.isFlagged {
          Image(systemName: "flag.fill")
            .font(.system(size: 16))
            .foregroundStyle(.orange)
        }

        // Info button - show when editing
        Button {
          onInfoTap?()
        } label: {
          Image(systemName: "info.circle")
            .font(.system(size: 18))
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
      } else if task.isFlagged {
        // Flag indicator only - show when not editing
        Image(systemName: "flag.fill")
          .font(.system(size: 16))
          .foregroundStyle(.orange)
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .glassEffect(.regular)
    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
      Button(role: .destructive) {
        withAnimation {
          taskStore.deleteTask(task)
        }
      } label: {
        Label("Delete", systemImage: "trash")
      }

      Button {
        withAnimation {
          var updatedTask = task
          updatedTask.isFlagged.toggle()
          taskStore.updateTask(updatedTask)
        }
      } label: {
        Label(
          task.isFlagged ? "Unflag" : "Flag",
          systemImage: task.isFlagged ? "flag.slash.fill" : "flag.fill")
      }
      .tint(.orange)

      Button {
        onInfoTap?()
      } label: {
        Label("Details", systemImage: "info.circle")
      }
      .tint(.gray)
    }
  }

  // MARK: - Helpers

  private func saveAndDismiss() {
    if !editedTitle.isEmpty && editedTitle != task.title {
      var updatedTask = task
      updatedTask.title = editedTitle
      taskStore.updateTask(updatedTask)
    }
    if editingTaskId == task.id {
      editingTaskId = nil
    }
  }

  private func formatDate(_ date: Date) -> String {
    let calendar = Calendar.current
    if calendar.isDateInToday(date) {
      return "Today"
    } else if calendar.isDateInTomorrow(date) {
      return "Tomorrow"
    } else if calendar.isDateInYesterday(date) {
      return "Yesterday"
    } else {
      let formatter = DateFormatter()
      formatter.dateFormat = "MMM d"
      return formatter.string(from: date)
    }
  }

  private func formatTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mm a"
    return formatter.string(from: date)
  }

  private func hasTimeComponent(_ date: Date) -> Bool {
    let calendar = Calendar.current
    let hour = calendar.component(.hour, from: date)
    let minute = calendar.component(.minute, from: date)
    return hour != 0 || minute != 0
  }

  private func isOverdue(_ date: Date) -> Bool {
    return date < Date() && !task.isCompleted
  }
}

#Preview {
  PreviewContainer {
    EditableTaskRowContainer()
  }
}

private struct EditableTaskRowContainer: View {
  @State private var editingTaskId: UUID? = nil
  @FocusState private var focusedTaskId: UUID?

  var body: some View {
    EditableTaskRow(
      task: Task(title: "Complete project documentation", date: Date(), isFlagged: true),
      editingTaskId: $editingTaskId,
      focusedTaskId: $focusedTaskId
    )
    .padding()
  }
}

