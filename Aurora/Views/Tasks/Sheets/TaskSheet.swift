//
//  TaskSheet.swift
//  Aurora
//
//  Unified sheet for adding and editing tasks
//  Created by souhail on 12/30/25.
//

import SwiftUI
import UserNotifications

struct TaskSheet: View {
  @Environment(TaskStore.self) var taskStore
  @Environment(\.dismiss) var dismiss

  // If nil, we're adding a new task. If set, we're editing.
  let existingTask: Task?
  let defaultCategory: TaskCategory?

  // Basic info
  @State private var title = ""
  @State private var notes = ""
  @State private var url = ""

  // Date & Time
  @State private var hasDate = false
  @State private var selectedDate = Date()
  @State private var hasTime = false
  @State private var selectedTime = Date()
  @State private var isUrgent = false

  // Collapsible states
  @State private var showDatePicker = false
  @State private var showTimePicker = false

  // Repeat & Early Reminder
  @State private var repeatOption: RepeatOption = .never
  @State private var earlyReminder: EarlyReminder = .none
  @State private var isTimeSensitive = true  // Default to time-sensitive

  // Organization
  @State private var selectedCategory: TaskCategory = .reminders
  @State private var isFlagged = false
  @State private var selectedPriority: TaskPriority = .none

  // Alarm Service
  @State private var alarmService = AlarmService.shared
  @State private var showingAlarmPermission = false

  @FocusState private var focusedField: Field?

  enum Field: Hashable {
    case title, notes, url
  }

  enum RepeatOption: String, CaseIterable {
    case never = "Never"
    case daily = "Daily"
    case weekly = "Weekly"
    case biweekly = "Every 2 Weeks"
    case monthly = "Monthly"
    case yearly = "Yearly"
  }

  enum EarlyReminder: String, CaseIterable {
    case none = "None"
    case atTime = "At time of event"
    case fiveMin = "5 minutes before"
    case fifteenMin = "15 minutes before"
    case thirtyMin = "30 minutes before"
    case oneHour = "1 hour before"
    case oneDay = "1 day before"

    var timeInterval: TimeInterval? {
      switch self {
      case .none: return nil
      case .atTime: return 0
      case .fiveMin: return -5 * 60
      case .fifteenMin: return -15 * 60
      case .thirtyMin: return -30 * 60
      case .oneHour: return -60 * 60
      case .oneDay: return -24 * 60 * 60
      }
    }
  }

  var isEditing: Bool {
    existingTask != nil
  }

  var sheetTitle: String {
    isEditing ? "Details" : "New Task"
  }

  init(task: Task? = nil, defaultCategory: TaskCategory? = nil) {
    self.existingTask = task
    self.defaultCategory = defaultCategory
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 0) {
          // Title, Notes, URL Section
          titleNotesSection

          // Date & Time Section
          dateTimeSection

          // Repeat & Early Reminder
          repeatReminderSection

          // Organization Section
          organizationSection

          // Delete Button (only when editing)
          if isEditing {
            deleteButton
          }

          Spacer(minLength: 40)
        }
      }
      .background(Color(.systemGroupedBackground))
      .navigationTitle(sheetTitle)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button {
            dismiss()
          } label: {
            Image(systemName: "xmark")
              .font(.system(size: 15, weight: .bold))
              .foregroundStyle(Theme.primary)
              .frame(width: 30, height: 30)
          }
        }

        ToolbarItem(placement: .topBarTrailing) {
          Button {
            saveTask()
          } label: {
            Image(systemName: "checkmark")
              .font(.system(size: 15, weight: .bold))
              .foregroundStyle(.white)
              .frame(width: 30, height: 30)
          }
          .buttonStyle(.glassProminent)
          .tint(Theme.primary)
        }
      }
      .onAppear {
        loadTask()
        focusedField = isEditing ? nil : .title
      }
      .alert("Enable Urgent Alarms", isPresented: $showingAlarmPermission) {
        Button("Enable") {
          AsyncTask {
            let granted = await alarmService.requestAuthorization()
            if granted {
              isUrgent = true
            }
          }
        }
        Button("Cancel", role: .cancel) {
          isUrgent = false
        }
      } message: {
        Text(
          "Aurora needs permission to schedule urgent alarms that will ring even when your device is in Focus mode."
        )
      }
    }
  }

  // MARK: - Title, Notes, URL Section

  private var titleNotesSection: some View {
    VStack(spacing: 0) {
      TextField("Title", text: $title)
        .font(.title2.weight(.semibold))
        .focused($focusedField, equals: .title)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)

      Divider().padding(.leading, 16)

      TextField("Notes", text: $notes, axis: .vertical)
        .focused($focusedField, equals: .notes)
        .foregroundStyle(.secondary)
        .lineLimit(2...6)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)

      Divider().padding(.leading, 16)

      TextField("URL", text: $url)
        .focused($focusedField, equals: .url)
        .keyboardType(.URL)
        .textContentType(.URL)
        .autocapitalization(.none)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
    .background(Color(.secondarySystemGroupedBackground))
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .padding(.horizontal, 16)
    .padding(.top, 16)
  }

  // MARK: - Date & Time Section

  private var dateTimeSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Date & Time")
        .font(.subheadline)
        .fontWeight(.semibold)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 20)
        .padding(.top, 24)

      VStack(spacing: 0) {
        // Date Toggle
        dateRow

        Divider().padding(.leading, 56)

        // Time Toggle
        timeRow

        Divider().padding(.leading, 56)

        // Urgent Toggle
        urgentRow
      }
      .background(Color(.secondarySystemGroupedBackground))
      .clipShape(RoundedRectangle(cornerRadius: 12))
      .padding(.horizontal, 16)

      if isUrgent {
        Text("Mark this reminder as urgent to set an alarm.")
          .font(.caption)
          .foregroundStyle(.secondary)
          .padding(.horizontal, 20)
      }
    }
  }

  // MARK: - Repeat & Early Reminder Section

  private var repeatReminderSection: some View {
    VStack(spacing: 0) {
      // Repeat
      HStack {
        Image(systemName: "arrow.trianglehead.2.clockwise")
          .font(.system(size: 18))
          .foregroundStyle(.secondary)
          .frame(width: 28)

        Text("Repeat")

        Spacer()

        Picker("", selection: $repeatOption) {
          ForEach(RepeatOption.allCases, id: \.self) { option in
            Text(option.rawValue).tag(option)
          }
        }
        .tint(.secondary)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)

      Divider().padding(.leading, 56)

      // Early Reminder
      HStack {
        Image(systemName: "bell")
          .font(.system(size: 18))
          .foregroundStyle(.secondary)
          .frame(width: 28)

        Text("Early Reminder")

        Spacer()

        Picker("", selection: $earlyReminder) {
          ForEach(EarlyReminder.allCases, id: \.self) { option in
            Text(option.rawValue).tag(option)
          }
        }
        .tint(.secondary)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)

      // Time Sensitive toggle (only show when early reminder is set)
      if earlyReminder != .none {
        Divider().padding(.leading, 56)

        HStack {
          Image(systemName: "exclamationmark.circle")
            .font(.system(size: 18))
            .foregroundStyle(isTimeSensitive ? .orange : .secondary)
            .frame(width: 28)

          VStack(alignment: .leading, spacing: 2) {
            Text("Time Sensitive")
              .foregroundStyle(.primary)
            Text("Breaks through Focus modes")
              .font(.caption)
              .foregroundStyle(.secondary)
          }

          Spacer()

          Toggle("", isOn: $isTimeSensitive)
            .tint(.orange)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
      }
    }
    .background(Color(.secondarySystemGroupedBackground))
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .padding(.horizontal, 16)
    .padding(.top, 16)
  }

  // MARK: - Organization Section

  private var organizationSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Organization")
        .font(.subheadline)
        .fontWeight(.semibold)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 20)
        .padding(.top, 24)

      VStack(spacing: 0) {
        // List Picker
        NavigationLink {
          CategoryPickerView(selectedCategory: $selectedCategory)
        } label: {
          HStack {
            ZStack {
              RoundedRectangle(cornerRadius: 6)
                .fill(Color(hex: selectedCategory.colorHex))
                .frame(width: 28, height: 28)

              Image(systemName: selectedCategory.iconName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
            }

            Text("List")
              .foregroundStyle(.white)

            Spacer()

            Text(selectedCategory.name)
              .foregroundStyle(.secondary)

            Image(systemName: "chevron.right")
              .font(.system(size: 14, weight: .semibold))
              .foregroundStyle(.secondary)
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 12)
        }
      }
      .background(Color(.secondarySystemGroupedBackground))
      .clipShape(RoundedRectangle(cornerRadius: 12))
      .padding(.horizontal, 16)

      // Flag and Priority
      VStack(spacing: 0) {
        // Flag toggle
        HStack {
          Image(systemName: isFlagged ? "flag.fill" : "flag")
            .font(.system(size: 18))
            .foregroundStyle(isFlagged ? .orange : .secondary)
            .frame(width: 28)

          Text("Flag")
            .foregroundStyle(.primary)

          Spacer()

          Toggle("", isOn: $isFlagged)
            .tint(.orange)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)

        Divider().padding(.leading, 56)

        // Priority picker
        HStack {
          Text("!!!")
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(selectedPriority.color)
            .frame(width: 28)

          Text("Priority")
            .foregroundStyle(.primary)

          Spacer()

          Picker("", selection: $selectedPriority) {
            ForEach(TaskPriority.allCases, id: \.self) { priority in
              Text(priority.rawValue).tag(priority)
            }
          }
          .tint(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
      }
      .background(Color(.secondarySystemGroupedBackground))
      .clipShape(RoundedRectangle(cornerRadius: 12))
      .padding(.horizontal, 16)
      .padding(.top, 16)
    }
  }

  // MARK: - Date Row (Collapsible)

  @ViewBuilder
  private var dateRow: some View {
    VStack(spacing: 0) {
      Button {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
          if hasDate {
            showDatePicker.toggle()
          } else {
            hasDate = true
            showDatePicker = true
          }
        }
      } label: {
        HStack {
          Image(systemName: "calendar")
            .font(.system(size: 18))
            .foregroundStyle(.secondary)
            .frame(width: 28)

          VStack(alignment: .leading, spacing: 2) {
            Text("Date")
              .foregroundStyle(.primary)
            if hasDate {
              Text(formatDateLabel(selectedDate))
                .font(.caption)
                .foregroundStyle(Theme.primary)
            }
          }

          Spacer()

          Toggle(
            "",
            isOn: Binding(
              get: { hasDate },
              set: { newValue in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                  hasDate = newValue
                  if newValue {
                    showDatePicker = true
                  } else {
                    showDatePicker = false
                  }
                }
              }
            )
          )
          .tint(Theme.primary)
        }
      }
      .buttonStyle(.plain)
      .padding(.horizontal, 16)
      .padding(.vertical, 10)

      if showDatePicker && hasDate {
        DatePicker("", selection: $selectedDate, displayedComponents: .date)
          .datePickerStyle(.graphical)
          .padding(.horizontal, 16)
          .transition(.opacity.combined(with: .move(edge: .top)))
      }
    }
  }

  // MARK: - Time Row (Collapsible)

  @ViewBuilder
  private var timeRow: some View {
    VStack(spacing: 0) {
      Button {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
          if hasTime {
            showTimePicker.toggle()
          } else {
            hasTime = true
            showTimePicker = true
          }
        }
      } label: {
        HStack {
          Image(systemName: "clock")
            .font(.system(size: 18))
            .foregroundStyle(.secondary)
            .frame(width: 28)

          VStack(alignment: .leading, spacing: 2) {
            Text("Time")
              .foregroundStyle(.primary)
            if hasTime {
              Text(selectedTime.formatted(date: .omitted, time: .shortened))
                .font(.caption)
                .foregroundStyle(Theme.secondary)
            }
          }

          Spacer()

          Toggle(
            "",
            isOn: Binding(
              get: { hasTime },
              set: { newValue in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                  hasTime = newValue
                  if newValue {
                    showTimePicker = true
                  } else {
                    showTimePicker = false
                  }
                }
              }
            )
          )
          .tint(Theme.primary)
        }
      }
      .buttonStyle(.plain)
      .padding(.horizontal, 16)
      .padding(.vertical, 10)

      if showTimePicker && hasTime {
        DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
          .datePickerStyle(.wheel)
          .frame(height: 150)
          .padding(.horizontal, 16)
          .transition(.opacity.combined(with: .move(edge: .top)))
      }
    }
  }

  // MARK: - Urgent Row

  private var urgentRow: some View {
    HStack {
      Image(systemName: "alarm.waves.left.and.right")
        .font(.system(size: 18))
        .foregroundStyle(.secondary)
        .frame(width: 28)

      Text("Urgent")

      Spacer()

      Toggle(
        "",
        isOn: Binding(
          get: { isUrgent },
          set: { newValue in
            if newValue {
              if alarmService.isAuthorized {
                isUrgent = true
              } else {
                showingAlarmPermission = true
              }
            } else {
              isUrgent = false
            }
          }
        )
      )
      .tint(Theme.primary)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 10)
  }

  // MARK: - Delete Button

  private var deleteButton: some View {
    Button(role: .destructive) {
      if let task = existingTask {
        AsyncTask {
          await alarmService.cancelAlarm(for: task)
        }
        taskStore.deleteTask(task)
      }
      dismiss()
    } label: {
      HStack {
        Image(systemName: "trash")
        Text("Delete Task")
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 14)
    }
    .background(Color(.secondarySystemGroupedBackground))
    .glassEffect(.regular.tint(.red))
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .padding(.horizontal, 16)
    .padding(.top, 24)
  }

  // MARK: - Load Task

  private func loadTask() {
    if let task = existingTask {
      title = task.title
      notes = task.notes
      url = task.url
      selectedCategory = task.category ?? .reminders
      selectedPriority = task.priority
      isFlagged = task.isFlagged
      isUrgent = task.priority == .high && task.hasReminder

      if let date = task.date {
        hasDate = true
        selectedDate = date

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        if hour != 0 || minute != 0 {
          hasTime = true
          selectedTime = date
        }
      }
    } else {
      selectedCategory = defaultCategory ?? .reminders
    }
  }

  // MARK: - Save Task

  private func saveTask() {
    var taskDate: Date? = nil

    if hasDate {
      if hasTime {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)

        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute

        taskDate = calendar.date(from: combined)
      } else {
        taskDate = selectedDate
      }
    }

    let priority: TaskPriority = isUrgent ? .high : selectedPriority

    if var task = existingTask {
      task.title = title.trimmingCharacters(in: .whitespaces)
      task.notes = notes
      task.url = url
      task.date = taskDate
      task.priority = priority
      task.category = selectedCategory
      task.isFlagged = isFlagged
      task.hasReminder = isUrgent

      taskStore.updateTask(task)

      // Handle notifications
      scheduleNotifications(for: task, at: taskDate)

      // Handle alarm
      AsyncTask {
        if isUrgent && taskDate != nil {
          await alarmService.scheduleUrgentAlarm(for: task)
        } else {
          await alarmService.cancelAlarm(for: task)
        }
      }
    } else {
      let newTask = Task(
        title: title.trimmingCharacters(in: .whitespaces),
        notes: notes,
        url: url,
        date: taskDate,
        priority: priority,
        category: selectedCategory,
        isFlagged: isFlagged,
        hasReminder: isUrgent
      )

      taskStore.addTask(newTask)

      // Handle notifications
      scheduleNotifications(for: newTask, at: taskDate)

      // Schedule alarm if urgent
      if isUrgent && taskDate != nil {
        AsyncTask {
          await alarmService.scheduleUrgentAlarm(for: newTask)
        }
      }
    }

    dismiss()
  }

  // MARK: - Schedule Notifications

  private func scheduleNotifications(for task: Task, at date: Date?) {
    // Remove existing notifications
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
      task.id.uuidString,
      "\(task.id.uuidString)-early",
    ])

    guard let taskDate = date else { return }

    // Schedule main notification at task time
    if hasTime {
      scheduleNotification(
        id: task.id.uuidString,
        title: task.title,
        body: task.notes.isEmpty ? "Task reminder" : task.notes,
        at: taskDate
      )
    }

    // Schedule early reminder if set
    if let offset = earlyReminder.timeInterval, earlyReminder != .none, let taskDate = date {
      let earlyDate = taskDate.addingTimeInterval(offset)
      if earlyDate > Date() {
        scheduleNotification(
          id: "\(task.id.uuidString)-early",
          title: "Upcoming: \(task.title)",
          body: "\(earlyReminder.rawValue)",
          at: earlyDate,
          timeSensitive: isTimeSensitive
        )
      }
    }
  }

  private func scheduleNotification(
    id: String, title: String, body: String, at date: Date, timeSensitive: Bool = false
  ) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default

    // Set interruption level based on time-sensitive setting
    if timeSensitive {
      content.interruptionLevel = .timeSensitive
    }

    let components = Calendar.current.dateComponents(
      [.year, .month, .day, .hour, .minute], from: date)
    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

    let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

    UNUserNotificationCenter.current().add(request) { error in
      if let error = error {
        print("Failed to schedule notification: \(error)")
      }
    }
  }

  // MARK: - Helpers

  private func formatDateLabel(_ date: Date) -> String {
    let calendar = Calendar.current
    if calendar.isDateInToday(date) {
      return "Today"
    } else if calendar.isDateInTomorrow(date) {
      return "Tomorrow"
    } else {
      return date.formatted(date: .abbreviated, time: .omitted)
    }
  }
}
