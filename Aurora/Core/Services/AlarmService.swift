//
//  AlarmService.swift
//  Aurora
//
//  AlarmKit integration for urgent task notifications (iOS 26+)
//  Created by souhail on 12/30/25.
//

#if os(iOS)

import ActivityKit
import AlarmKit
import SwiftUI

/// Empty metadata for simple alarms
struct TaskAlarmMetadata: AlarmMetadata, Codable, Hashable {}

/// Aurora purple color for alarm UI
private let auroraPurple = Color(red: 0.7, green: 0.4, blue: 0.95)

/// Service for managing urgent task alarms using AlarmKit
@MainActor
@Observable
class AlarmService {
  static let shared = AlarmService()

  /// Whether the user has authorized alarm access
  var isAuthorized = false

  private init() {
    AsyncTask {
      await checkAuthorization()
    }
  }

  // MARK: - Authorization

  /// Check current authorization status
  func checkAuthorization() async {
    let status = AlarmManager.shared.authorizationState
    isAuthorized = (status == .authorized)
  }

  /// Request authorization for AlarmKit
  func requestAuthorization() async -> Bool {
    do {
      let status = try await AlarmManager.shared.requestAuthorization()
      isAuthorized = (status == .authorized)
      return isAuthorized
    } catch {
      print("[AlarmService] Authorization failed: \(error)")
      return false
    }
  }

  // MARK: - Scheduling

  /// Schedule an urgent alarm for a task
  func scheduleUrgentAlarm(for task: Task) async {
    guard let taskDate = task.date else {
      print("[AlarmService] Cannot schedule alarm - no date set")
      return
    }

    // Extract hour and minute from the task date
    let calendar = Calendar.current
    let hour = calendar.component(.hour, from: taskDate)
    let minute = calendar.component(.minute, from: taskDate)

    // Create the schedule
    let time = Alarm.Schedule.Relative.Time(hour: hour, minute: minute)
    let schedule = Alarm.Schedule.relative(Alarm.Schedule.Relative(time: time, repeats: .never))

    // Create the alert presentation with Aurora purple snooze button
    let snoozeButton = AlarmButton(
      text: LocalizedStringResource(stringLiteral: "Snooze"),
      textColor: auroraPurple,
      systemImageName: "moon.zzz.fill"
    )

    let alert: AlarmPresentation.Alert
    if #available(iOS 26.1, *) {
      alert = AlarmPresentation.Alert(
        title: LocalizedStringResource(stringLiteral: task.title),
        secondaryButton: snoozeButton,
        secondaryButtonBehavior: .countdown
      )
    } else {
      alert = AlarmPresentation.Alert(
        title: LocalizedStringResource(stringLiteral: task.title)
      )
    }

    let presentation = AlarmPresentation(alert: alert)

    // Create attributes with Aurora purple tint
    let attributes = AlarmAttributes<TaskAlarmMetadata>(
      presentation: presentation,
      metadata: nil,
      tintColor: auroraPurple
    )

    // Create configuration
    let configuration = AlarmManager.AlarmConfiguration<TaskAlarmMetadata>.alarm(
      schedule: schedule,
      attributes: attributes
    )

    do {
      let _ = try await AlarmManager.shared.schedule(
        id: task.id,
        configuration: configuration
      )
      print("[AlarmService] Scheduled alarm for '\(task.title)' at \(hour):\(minute)")
    } catch {
      print("[AlarmService] Failed to schedule alarm: \(error)")
    }
  }

  /// Cancel an alarm for a task
  func cancelAlarm(for task: Task) async {
    do {
      try AlarmManager.shared.cancel(id: task.id)
      print("[AlarmService] Cancelled alarm for '\(task.title)'")
    } catch {
      print("[AlarmService] Failed to cancel alarm: \(error)")
    }
  }

  /// Check if an alarm is scheduled for a task
  func hasAlarm(for taskId: UUID) -> Bool {
    do {
      let alarms = try AlarmManager.shared.alarms
      return alarms.contains { $0.id == taskId }
    } catch {
      return false
    }
  }
}

#elseif os(macOS)

import SwiftUI

/// macOS stub — AlarmKit is not available on Mac.
/// All methods are no-ops, keeping the call-site API identical.
@MainActor
@Observable
class AlarmService {
  static let shared = AlarmService()

  var isAuthorized = false

  private init() {}

  func checkAuthorization() async {}
  func requestAuthorization() async -> Bool { false }
  func scheduleUrgentAlarm(for task: Task) async {}
  func cancelAlarm(for task: Task) async {}
  func hasAlarm(for taskId: UUID) -> Bool { false }
}

#endif
