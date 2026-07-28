//
//  EditableTaskRow.swift
//  Aurora
//

import SwiftUI

struct EditableTaskRow: View {
  @Environment(TaskStore.self) var taskStore
  let task: Task

  @Binding var editingTaskId: UUID?
  @FocusState.Binding var focusedTaskId: UUID?
  var onInfoTap: (() -> Void)? = nil

  @State private var editedTitle: String = ""

  private var isEditing: Bool {
    editingTaskId == task.id
  }

  private var categoryColor: Color {
    if let cat = task.category {
      return Color(hex: cat.colorHex)
    }
    return Theme.primary
  }

  var body: some View {
    HStack(spacing: 14) {
      // Completion Toggle
      Button {
        HapticService.shared.impact(.light)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
          taskStore.toggleTaskCompletion(task)
        }
      } label: {
        ZStack {
          Circle()
            .strokeBorder(categoryColor, lineWidth: 2)
            .background(Circle().fill(task.isCompleted ? categoryColor : .clear))
            .frame(width: 24, height: 24)

          if task.isCompleted {
            Image(systemName: "checkmark")
              .font(.system(size: 11, weight: .black))
              .foregroundStyle(.white)
              .transition(.scale.combined(with: .opacity))
          }
        }
      }
      .buttonStyle(.plain)

      // Task Title & Date Subtitle
      VStack(alignment: .leading, spacing: 3) {
        if isEditing {
          TextField("Task title...", text: $editedTitle)
            .font(.system(size: 16, weight: .medium))
            .textFieldStyle(.plain)
            .focused($focusedTaskId, equals: task.id)
            .onSubmit { saveAndDismiss() }
            .onAppear { editedTitle = task.title }
            .onChange(of: focusedTaskId) { _, newId in
              if newId != task.id && isEditing { saveAndDismiss() }
            }
        } else {
          Text(task.title.isEmpty ? "New Task" : task.title)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(task.isCompleted ? .secondary : .primary)
            .strikethrough(task.isCompleted, color: .secondary.opacity(0.7))
            .lineLimit(1)
        }

        if let date = task.date, !isEditing {
          HStack(spacing: 8) {
            HStack(spacing: 4) {
              Image(systemName: "calendar")
                .font(.system(size: 10, weight: .medium))
              Text(formatDate(date))
                .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(isOverdue(date) ? .red : .secondary)

            if hasTimeComponent(date) {
              HStack(spacing: 4) {
                Image(systemName: "clock")
                  .font(.system(size: 10, weight: .medium))
                Text(formatTime(date))
                  .font(.system(size: 12, weight: .medium))
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
          HapticService.shared.impact(.light)
          editedTitle = task.title
          editingTaskId = task.id
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            focusedTaskId = task.id
          }
        }
      }

      // Priority & Flag Indicators
      HStack(spacing: 8) {
        if task.priority == .high {
          Image(systemName: "exclamationmark.circle.fill")
            .font(.system(size: 14))
            .foregroundStyle(.red)
        }

        if task.isFlagged {
          Image(systemName: "flag.fill")
            .font(.system(size: 14))
            .foregroundStyle(.orange)
        }

        if isEditing {
          Button {
            onInfoTap?()
          } label: {
            Image(systemName: "info.circle.fill")
              .font(.system(size: 18))
              .foregroundStyle(Theme.primary)
          }
          .buttonStyle(.plain)
        }
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 13)
    .background {
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .glassEffect(.clear)
    }
    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
      Button(role: .destructive) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
          taskStore.deleteTask(task)
        }
      } label: {
        Label("Delete", systemImage: "trash")
      }

      Button {
        withAnimation {
          var updated = task
          updated.isFlagged.toggle()
          taskStore.updateTask(updated)
        }
      } label: {
        Label(
          task.isFlagged ? "Unflag" : "Flag",
          systemImage: task.isFlagged ? "flag.slash.fill" : "flag.fill"
        )
      }
      .tint(.orange)
    }
  }

  private func saveAndDismiss() {
    let trimmed = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    if !trimmed.isEmpty && trimmed != task.title {
      var updated = task
      updated.title = trimmed
      taskStore.updateTask(updated)
    }
    if editingTaskId == task.id {
      editingTaskId = nil
    }
  }

  private func formatDate(_ date: Date) -> String {
    let cal = Calendar.current
    if cal.isDateInToday(date) { return "Today" }
    if cal.isDateInTomorrow(date) { return "Tomorrow" }
    if cal.isDateInYesterday(date) { return "Yesterday" }
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d"
    return formatter.string(from: date)
  }

  private func formatTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mm a"
    return formatter.string(from: date)
  }

  private func hasTimeComponent(_ date: Date) -> Bool {
    let cal = Calendar.current
    return cal.component(.hour, from: date) != 0 || cal.component(.minute, from: date) != 0
  }

  private func isOverdue(_ date: Date) -> Bool {
    return date < Date() && !task.isCompleted
  }
}
