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
  @Environment(\.horizontalSizeClass) private var sizeClass

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
    HStack(spacing: LayoutTokens.Spacing.md + 2) {
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
            .frame(width: LayoutTokens.CardHeight.taskCheckbox, height: LayoutTokens.CardHeight.taskCheckbox)

          if task.isCompleted {
            Image(systemName: "checkmark")
              .font(.system(size: LayoutTokens.IconSize.xs, weight: .black))
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
            .font(.system(size: LayoutTokens.Typography.body, weight: .medium))
            .textFieldStyle(.plain)
            .focused($focusedTaskId, equals: task.id)
            .onSubmit { saveAndDismiss() }
            .onAppear { editedTitle = task.title }
            .onChange(of: focusedTaskId) { _, newId in
              if newId != task.id && isEditing { saveAndDismiss() }
            }
        } else {
          Text(task.title.isEmpty ? "New Task" : task.title)
            .font(.system(size: LayoutTokens.Typography.body, weight: .medium))
            .foregroundStyle(task.isCompleted ? .secondary : .primary)
            .strikethrough(task.isCompleted, color: .secondary.opacity(0.7))
            .lineLimit(1)
        }

        if let date = task.date, !isEditing {
          HStack(spacing: LayoutTokens.Spacing.sm) {
            HStack(spacing: LayoutTokens.Spacing.xs) {
              Image(systemName: "calendar")
                .font(.system(size: LayoutTokens.Typography.micro, weight: .medium))
              Text(formatDate(date))
                .font(.system(size: LayoutTokens.Typography.caption, weight: .medium))
            }
            .foregroundStyle(isOverdue(date) ? .red : .secondary)

            if hasTimeComponent(date) {
              HStack(spacing: LayoutTokens.Spacing.xs) {
                Image(systemName: "clock")
                  .font(.system(size: LayoutTokens.Typography.micro, weight: .medium))
                Text(formatTime(date))
                  .font(.system(size: LayoutTokens.Typography.caption, weight: .medium))
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
      HStack(spacing: LayoutTokens.Spacing.sm) {
        if task.priority == .high {
          Image(systemName: "exclamationmark.circle.fill")
            .font(.system(size: LayoutTokens.IconSize.sm))
            .foregroundStyle(.red)
        }

        if task.isFlagged {
          Image(systemName: "flag.fill")
            .font(.system(size: LayoutTokens.IconSize.sm))
            .foregroundStyle(.orange)
        }

        if isEditing {
          Button {
            onInfoTap?()
          } label: {
            Image(systemName: "info.circle.fill")
              .font(.system(size: LayoutTokens.IconSize.md))
              .foregroundStyle(Theme.primary)
          }
          .buttonStyle(.plain)
        }
      }
    }
    .padding(.horizontal, LayoutTokens.Padding.cardInner(for: sizeClass))
    .padding(.vertical, LayoutTokens.Padding.rowVertical)
    .background {
      Capsule(style: .continuous)
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
          let updated = task
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
      let updated = task
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
