//
//  SmartListType.swift
//  Aurora
//
//  Created by antigravity on 3/11/26.
//

import SwiftUI

/// Represents the types of smart lists available in the task view
enum SmartListType: String, CaseIterable, Identifiable, Codable, Sendable {
  case today = "Today"
  case scheduled = "Scheduled"
  case all = "All"
  case flagged = "Flagged"
  case completed = "Completed"

  var id: String { rawValue }

  var icon: String {
    switch self {
    case .today: return "calendar"
    case .scheduled: return "calendar.badge.clock"
    case .all: return "tray.fill"
    case .flagged: return "flag.fill"
    case .completed: return "checkmark.circle.fill"
    }
  }

  var tintColor: Color {
    switch self {
    case .today: return .blue
    case .scheduled: return .red
    case .all: return .gray
    case .flagged: return .orange
    case .completed: return .gray
    }
  }

  var title: String { rawValue }
  var color: Color { tintColor }
}
