//
//  JournalModels.swift
//  Aurora
//
//  Created by souhail on 12/4/25.
//

//
//  JournalModels.swift
//  Aurora
//
//  Created by souhail on 12/4/25.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class JournalEntry {
  @Attribute(.unique) var id: UUID
  var title: String
  var body: String
  var date: Date
  var theme: JournalTheme
  @Attribute(.externalStorage) var images: [Data] = []
  var deletedAt: Date?
  var locationName: String?
  var latitude: Double?
  var longitude: Double?

  init(
    id: UUID = UUID(),
    title: String,
    body: String,
    date: Date,
    theme: JournalTheme = .system,
    images: [Data] = [],
    deletedAt: Date? = nil,
    locationName: String? = nil,
    latitude: Double? = nil,
    longitude: Double? = nil
  ) {
    self.id = id
    self.title = title
    self.body = body
    self.date = date
    self.theme = theme
    self.images = images
    self.deletedAt = deletedAt
    self.locationName = locationName
    self.latitude = latitude
    self.longitude = longitude
  }
}

enum JournalTheme: String, Codable, CaseIterable, Sendable {
  case system = "Default"
  case oldPaper = "Old Paper"
  case midnight = "Midnight"
  case aurora = "Aurora"

  var backgroundColor: Color {
    switch self {
    case .system: return Theme.backgroundTop
    case .oldPaper: return Color(hex: "F4ECD8")
    case .midnight: return .black
    case .aurora: return .black
    }
  }

  var textColor: Color {
    switch self {
    case .system: return Theme.primary
    case .oldPaper: return Color(hex: "3C3C3C")
    case .midnight: return .white
    case .aurora: return .white
    }
  }

  var accentColor: Color {
    switch self {
    case .system: return Theme.primary
    case .oldPaper: return Color(hex: "8B4513")
    case .midnight: return Color(hex: "6B46C1")
    case .aurora: return Color(hex: "00F0FF")
    }
  }
}
